/*
  Copyright (C) 2011-2021 G. Bajlekov

    Ivy is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ivy is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::convert::TryInto;

use crate::ast::{BinaryOp, ColorSpace, Expr, Index, Literal, Prop, UnaryOp};
use crate::function_id::function_id;
use crate::scope::Tree;

#[derive(Debug, Eq, PartialEq, Copy, Clone)]
pub enum AddressSpace {
    Local,
    Private,
} 

#[derive(Debug, Eq, PartialEq, Copy, Clone)]
pub enum VarType {
    Bool,
    Int,
    Float,
    Vec,
    BoolArray(u8, AddressSpace, usize, usize, usize, usize),
    IntArray(u8, AddressSpace, usize, usize, usize, usize),
    FloatArray(u8, AddressSpace, usize, usize, usize, usize),
    VecArray(u8, AddressSpace, usize, usize, usize, usize),
    Buffer {
        x1y1: bool,
        z: usize,
        cs: ColorSpace,
    },
    Void,
    Unknown,
}

const B: VarType = VarType::Bool;
const I: VarType = VarType::Int;
const F: VarType = VarType::Float;
const V: VarType = VarType::Vec;

pub const LOCAL: AddressSpace = AddressSpace::Local;
pub const PRIVATE: AddressSpace = AddressSpace::Private;

impl std::fmt::Display for VarType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VarType::Bool => write!(f, "Bool"),
            VarType::Int => write!(f, "Int"),
            VarType::Float => write!(f, "Float"),
            VarType::Vec => write!(f, "Vec"),
            VarType::BoolArray(dim, address, ..) => {
                write!(
                    f,
                    "{}D {}BoolArray",
                    dim,
                    if *address==LOCAL { "local " } else { "" }
                )
            }
            VarType::IntArray(dim, local, ..) => {
                write!(f, "{}D {}IntArray", dim, if *local==LOCAL { "local " } else { "" })
            }
            VarType::FloatArray(dim, local, ..) => {
                write!(
                    f,
                    "{}D {}FloatArray",
                    dim,
                    if *local==LOCAL { "local " } else { "" }
                )
            }
            VarType::VecArray(dim, local, ..) => {
                write!(f, "{}D {}VecArray", dim, if *local==LOCAL { "local " } else { "" })
            }
            VarType::Buffer { z, cs, x1y1: true } => write!(f, "{}ch {} x1y1 Buffer", z, cs),
            VarType::Buffer { z, cs, x1y1: false } => write!(f, "{}ch {} Buffer", z, cs),
            VarType::Void => write!(f, "Void"),
            VarType::Unknown => write!(f, "Unknown"),
        }
    }
}

pub struct GenFunction {
    pub declaration: String,
    pub definition: String,
    pub return_type: VarType,
    pub dependencies: HashSet<String>,
}

pub struct Inference<'a> {
    pub scope: Tree,
    pub functions: Option<&'a RefCell<HashMap<String, GenFunction>>>,
}

impl<'a> Inference<'a> {
    pub fn new() -> Inference<'a> {
        Inference {
            scope: Tree::new(),
            functions: None,
        }
    }

    pub fn var_type(&self, expr: &Expr) -> Result<VarType, String> {
        // handle Prop::Ptr separately as it needs information about the array/buffer before indexing
        if let Expr::Index(expr, idx) = expr {
            if let (Expr::Index(expr, _), Index::Prop(Prop::Ptr)) = (&**expr, &**idx) {
                if let Expr::Identifier(id) = &**expr {
                    if let Some(var_type) = self.scope.get(id) {
                        let var_type = match var_type {
                            VarType::IntArray(_, LOCAL, ..) => {
                                VarType::IntArray(1, LOCAL, 0, 0, 0, 0)
                            }
                            VarType::IntArray(_, PRIVATE, ..) => {
                                VarType::IntArray(1, PRIVATE, 0, 0, 0, 0)
                            }
                            VarType::FloatArray(_, LOCAL, ..) => {
                                VarType::FloatArray(1, LOCAL, 0, 0, 0, 0)
                            }
                            VarType::FloatArray(_, PRIVATE, ..) => {
                                VarType::FloatArray(1, PRIVATE, 0, 0, 0, 0)
                            }
                            VarType::Buffer { .. } => VarType::FloatArray(1, PRIVATE, 0, 0, 0, 0),
                            err_type => {
                                return Err(format!(
                                "Variable '{}' of type '{}' does not support the '.ptr' property",
                                id, err_type
                            ))
                            }
                        };

                        return Ok(var_type);
                    }
                    return Err(format!("Variable '{}' is not defined", id));
                }
            }
        }

        let var_type = match expr {
            Expr::Literal(Literal::Bool(_)) => B,
            Expr::Literal(Literal::Int(_)) => I,
            Expr::Literal(Literal::Float(_)) => F,
            Expr::Identifier(name) => self.scope.get(name).map_or(VarType::Unknown, |t| t),
            Expr::Unary(expr) => match (&(*expr).op, self.var_type(&expr.right)?) {
                (UnaryOp::Not, B) => B,
                (UnaryOp::Neg, I) => I,
                (UnaryOp::Neg, F) => F,
                (UnaryOp::Neg, V) => V,
                (op, err_type) => {
                    return Err(format!(
                        "Variable of type '{}' does not support unary operation '{:?}'",
                        err_type, op
                    ))
                }
            },
            Expr::Binary(expr) => {
                match (
                    &(*expr).op,
                    self.var_type(&expr.left)?,
                    self.var_type(&expr.right)?,
                ) {
                    (BinaryOp::And | BinaryOp::Or, B, B)
                    | (BinaryOp::Equal | BinaryOp::NotEqual, _, _) => B,

                    (
                        BinaryOp::Greater
                        | BinaryOp::GreaterEqual
                        | BinaryOp::Less
                        | BinaryOp::LessEqual,
                        left,
                        right,
                    ) if (left == I || left == F) && (right == I || right == F) => B,

                    (BinaryOp::Pow | BinaryOp::Div, left, right) => {
                        Inference::promote(Inference::promote(left, right)?, F)?
                    }

                    (BinaryOp::DivInt, _, _) => I,

                    (
                        BinaryOp::Add | BinaryOp::Sub | BinaryOp::Mul | BinaryOp::Mod,
                        left,
                        right,
                    ) => Inference::promote_num(left, right)?,

                    (op, left, right) => {
                        return Err(format!(
                    "Unable to infer type of operation '{:?}' with arguments of type '{}' and '{}'",
                    op, left, right
                ))
                    }
                }
            }
            Expr::Index(expr, idx) => match (self.var_type(expr)?, &**idx) {
                (V, Index::Vec(_)) => F,
                (VarType::Buffer { .. }, Index::Vec(_)) => I,
                (V, Index::ColorSpace(c)) => match c {
                    // 3ch buffer
                    ColorSpace::Srgb
                    | ColorSpace::Lrgb
                    | ColorSpace::Xyz
                    | ColorSpace::Lab
                    | ColorSpace::Lch => V,
                    ColorSpace::Y | ColorSpace::L => F,
                },
                (F, Index::ColorSpace(c)) => match c {
                    // 1ch buffer
                    ColorSpace::Srgb
                    | ColorSpace::Lrgb
                    | ColorSpace::Xyz
                    | ColorSpace::Lab
                    | ColorSpace::Lch => V,
                    ColorSpace::Y | ColorSpace::L => F,
                },

                (F, Index::Prop(Prop::IntPtr)) => VarType::IntArray(1, PRIVATE, 0, 0, 0, 0), // only available for buffers

                (VarType::BoolArray(1, ..), Index::Array1D(..))
                | (VarType::BoolArray(2, ..), Index::Array2D(..))
                | (VarType::BoolArray(3, ..), Index::Array3D(..))
                | (VarType::BoolArray(4, ..), Index::Array4D(..)) => B,

                (F, Index::Prop(Prop::Int))
                | (F, Index::Prop(Prop::Idx))
                | (VarType::IntArray(1, ..), Index::Array1D(..))
                | (VarType::IntArray(2, ..), Index::Array2D(..))
                | (VarType::IntArray(3, ..), Index::Array3D(..))
                | (VarType::IntArray(4, ..), Index::Array4D(..)) => I,

                (VarType::Buffer { .. }, Index::Array1D(..))
                | (VarType::Buffer { z: 1, .. }, Index::Array2D(..))
                | (VarType::Buffer { .. }, Index::Array3D(..))
                | (VarType::FloatArray(1, ..), Index::Array1D(..))
                | (VarType::FloatArray(2, ..), Index::Array2D(..))
                | (VarType::FloatArray(3, ..), Index::Array3D(..))
                | (VarType::FloatArray(4, ..), Index::Array4D(..)) => F,

                (VarType::Buffer { z: 3, .. }, Index::Array2D(..))
                | (VarType::VecArray(1, ..), Index::Array1D(..))
                | (VarType::VecArray(2, ..), Index::Array2D(..))
                | (VarType::VecArray(3, ..), Index::Array3D(..))
                | (VarType::VecArray(4, ..), Index::Array4D(..)) => V,

                _ => self.var_type(expr)?,
            },
            Expr::Grouping(expr) => self.var_type(&**expr)?,
            Expr::Call(id, expr) => {
                if let Ok(var_type) = self.builtin(id, &**expr) {
                    var_type
                } else if let Ok(var_type) = self.function(id, &**expr) {
                    var_type
                } else {
                    VarType::Unknown // function call with unknown return type
                }
            }
            Expr::Array(elems) => {
                if elems.is_empty() {
                    return Err("Unable to construct empty array".into());
                }

                // TODO: assert that all other elements have the same type
                match self.var_type(&elems[0])? {
                    B => VarType::BoolArray(1, PRIVATE, elems.len(), 0, 0, 0),
                    I => VarType::IntArray(1, PRIVATE, elems.len(), 0, 0, 0),
                    F => VarType::FloatArray(1, PRIVATE, elems.len(), 0, 0, 0),
                    V => VarType::VecArray(1, PRIVATE, elems.len(), 0, 0, 0),
                    VarType::BoolArray(1, _, i1, ..) => {
                        VarType::BoolArray(2, PRIVATE, elems.len(), i1, 0, 0)
                    }
                    VarType::BoolArray(2, _, i1, i2, ..) => {
                        VarType::BoolArray(3, PRIVATE, elems.len(), i1, i2, 0)
                    }
                    VarType::BoolArray(3, _, i1, i2, i3, ..) => {
                        VarType::BoolArray(4, PRIVATE, elems.len(), i1, i2, i3)
                    }
                    VarType::IntArray(1, _, i1, ..) => {
                        VarType::IntArray(2, PRIVATE, elems.len(), i1, 0, 0)
                    }
                    VarType::IntArray(2, _, i1, i2, ..) => {
                        VarType::IntArray(3, PRIVATE, elems.len(), i1, i2, 0)
                    }
                    VarType::IntArray(3, _, i1, i2, i3, ..) => {
                        VarType::IntArray(4, PRIVATE, elems.len(), i1, i2, i3)
                    }
                    VarType::FloatArray(1, _, i1, ..) => {
                        VarType::FloatArray(2, PRIVATE, elems.len(), i1, 0, 0)
                    }
                    VarType::FloatArray(2, _, i1, i2, ..) => {
                        VarType::FloatArray(3, PRIVATE, elems.len(), i1, i2, 0)
                    }
                    VarType::FloatArray(3, _, i1, i2, i3, ..) => {
                        VarType::FloatArray(4, PRIVATE, elems.len(), i1, i2, i3)
                    }
                    VarType::VecArray(1, _, i1, ..) => {
                        VarType::VecArray(2, PRIVATE, elems.len(), i1, 0, 0)
                    }
                    VarType::VecArray(2, _, i1, i2, ..) => {
                        VarType::VecArray(3, PRIVATE, elems.len(), i1, i2, 0)
                    }
                    VarType::VecArray(3, _, i1, i2, i3, ..) => {
                        VarType::VecArray(4, PRIVATE, elems.len(), i1, i2, i3)
                    }
                    err_type => {
                        return Err(format!("Unable to construct array of type '{}'", err_type))
                    }
                }
            }
        };

        Ok(var_type)
    }

    // promote: int -> float -> vec
    pub fn promote_num(left: VarType, right: VarType) -> Result<VarType, String> {
        Ok(match (left, right) {
            (I, I) => I,
            (F | I, F) | (F, I) => F,
            (V | F | I, V) | (V, F | I) => V,
            (left, right) => {
                return Err(format!(
                    "Unable to promote type '{}' and '{}' to a common numeric type",
                    left, right
                ))
            }
        })
    }

    pub fn promote(left: VarType, right: VarType) -> Result<VarType, String> {
        Ok(match (left, right) {
            (B, B) => B,
            (I, I) => I,
            (F | I, F) | (F, I) => F,
            (V | F | I, V) | (V, F | I) => V,
            (left, right) => {
                return Err(format!(
                    "Unable to promote type '{}' and '{}' to a common type",
                    left, right
                ))
            }
        })
    }

    // can be coerced to float or int
    fn is_num(&self, x: &Expr) -> Result<bool, String> {
        let x = self.var_type(x)?;
        Ok(x == I || x == F)
    }

    fn is_int_lit(x: &Expr) -> bool {
        matches!(x, Expr::Literal(Literal::Int(_)))
    }

    fn get_int_lit(x: &Expr) -> Result<i32, String> {
        if let Expr::Literal(Literal::Int(val)) = x {
            Ok(*val)
        } else {
            Err(format!("Expected an integer literal, found:\n{:?}", x))
        }
    }

    fn is_num_vec(&self, x: &Expr) -> Result<bool, String> {
        let x = self.var_type(x)?;
        Ok(x == I || x == F || x == V)
    }

    fn function(&self, id: &str, vars: &[Expr]) -> Result<VarType, String> {
        let vars = vars
            .iter()
            .map(|expr| self.var_type(expr))
            .collect::<Result<Vec<_>, _>>()?;

        let id = function_id(id, &vars);

        if let Some(func) = self.functions {
            if let Some(GenFunction { return_type, .. }) = func.borrow().get(&id) {
                Ok(*return_type)
            } else {
                Err(format!("Function '{}' is not defined", id))
            }
        } else {
            Err("Function list is not initialized".into())
        }
    }

    fn math_1(&self, vars: &[Expr]) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to math function, found {}",
                vars.len()
            ));
        }
        if self.is_num_vec(&vars[0])? {
            Inference::promote_num(self.var_type(&vars[0])?, F)
        } else {
            return Err(format!(
                "Expected numeric argument to math function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ));
        }
    }

    fn math_2(&self, vars: &[Expr]) -> Result<VarType, String> {
        if vars.len() != 2 {
            return Err(format!(
                "Expected 1 arguments to math function, found {}",
                vars.len()
            ));
        }
        match (self.is_num_vec(&vars[0])?, self.is_num_vec(&vars[1])?) {
            (true, true) => Inference::promote_num(
                Inference::promote_num(self.var_type(&vars[1])?, self.var_type(&vars[0])?)?,
                F,
            ),
            (false, _) => {
                return Err(format!(
                    "Expected numeric 1st argument to math function, found argument of type '{}'",
                    self.var_type(&vars[0])?
                ))
            }
            (_, false) => {
                return Err(format!(
                    "Expected numeric 2nd argument to math function, found argument of type '{}'",
                    self.var_type(&vars[1])?
                ))
            }
        }
    }

    fn geom_1(&self, vars: &[Expr], var_type: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to geometry function, found {}",
                vars.len()
            ));
        }
        if self.is_num_vec(&vars[0])? {
            Ok(var_type)
        } else {
            return Err(format!(
                "Expected numeric argument to geometry function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ));
        }
    }

    fn geom_2(&self, vars: &[Expr], var_type: VarType) -> Result<VarType, String> {
        if vars.len() != 2 {
            return Err(format!(
                "Expected 2 arguments to geometry function, found {}",
                vars.len()
            ));
        }
        match (self.is_num_vec(&vars[0])?, self.is_num_vec(&vars[1])?) {
            (true, true) => Ok(var_type),
            (false, _) => {
                return Err(format!(
                "Expected numeric 1st argument to geometry function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ))
            }
            (_, false) => {
                return Err(format!(
                "Expected numeric 2nd argument to geometry function, found argument of type '{}'",
                self.var_type(&vars[1])?
            ))
            }
        }
    }

    fn cs_v(&self, vars: &[Expr], var_type: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to color space function, found {}",
                vars.len()
            ));
        }
        if self.is_num_vec(&vars[0])? {
            Ok(var_type)
        } else {
            return Err(format!(
                "Expected numeric argument to geometry function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ));
        }
    }

    fn cs_f(&self, vars: &[Expr], var_type: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to color space function, found {}",
                vars.len()
            ));
        }
        if self.is_num(&vars[0])? {
            Ok(var_type)
        } else {
            return Err(format!(
                "Expected numeric argument to color space function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ));
        }
    }

    fn atomic_1(&self, vars: &[Expr]) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to atomic function, found {}",
                vars.len()
            ));
        }
        match self.var_type(&vars[0])? {
            VarType::FloatArray(1, ..) => Ok(F),
            VarType::IntArray(1, ..) => Ok(I),
            err_type => Err(format!(
                "Unable to perform atomic operation on variable of type '{}'",
                err_type
            )),
        }
    }

    fn atomic_2(&self, vars: &[Expr]) -> Result<VarType, String> {
        if vars.len() != 2 {
            return Err(format!(
                "Expected 2 arguments to atomic function, found {}",
                vars.len()
            ));
        }
        // TODO: check 2nd variable
        match (self.var_type(&vars[0])?, self.var_type(&vars[1])?) {
            (VarType::FloatArray(1, ..), F) => Ok(F),
            (VarType::IntArray(1, ..), I) => Ok(I),
            (type_1 @ VarType::FloatArray(1, ..), type_2) => Err(format!("Atomic operation on variable of type '{}' expected a 'Float' argument, found argument of type '{}'", type_1, type_2)),
            (type_1 @ VarType::IntArray(1, ..), type_2) => Err(format!("Atomic operation on variable of type '{}' expected an 'Int' argument, found argument of type '{}'", type_1, type_2)),
            (err_type, _) => Err(format!("Unable to perform atomic operation on variable of type '{}', expected Float or Int array", err_type)),
        }
    }

    pub fn builtin(&self, id: &str, vars: &[Expr]) -> Result<VarType, String> {
        let var_type = match id {
            "get_work_dim" if vars.is_empty() => I,
            "get_global_size" | "get_global_id" | "get_local_size" | "get_local_id"
            | "get_num_groups" | "get_group_id" | "get_global_offset"
                if vars.len() == 1 && Inference::is_int_lit(&vars[0]) =>
            {
                I
            }

            // type-inferred 0 and 1
            "zero" | "one" if vars.len() == 1 && self.is_num_vec(&vars[0])? => {
                self.var_type(&vars[0])?
            }

            // OpenCL math built-in functions: clamp, degrees, max, min, mix, radians, step, smoothstep, sign
            "clamp" if vars.len() == 3 => {
                let v = self.var_type(&vars[0])?;
                let l = self.var_type(&vars[1])?;
                let h = self.var_type(&vars[2])?;
                Inference::promote_num(v, Inference::promote_num(l, h)?)?
            }
            "mix" if vars.len() == 3 => {
                let l = self.var_type(&vars[0])?;
                let h = self.var_type(&vars[1])?;
                let m = self.var_type(&vars[2])?;
                Inference::promote_num(m, Inference::promote_num(l, h)?)?
            }
            "min" | "max" if vars.len() == 2 => {
                let l = self.var_type(&vars[0])?;
                let r = self.var_type(&vars[1])?;
                Inference::promote_num(l, r)?
            }
            "sign" | "abs" if vars.len() == 1 => self.var_type(&vars[0])?,
            // min, max generate same instructions as fmin, fmax on GCN4
            "range" | "runif" | "rnorm" | "rpois" if vars.len() == 3 => VarType::Float,

            // OpenCL math built-in functions (selection)
            // returns F or V
            // TODO: handle fmin/min, fmax/max, pow/pown/powr, fabs/abs
            "cos" | "sin" | "tan" | "cosh" | "sinh" | "tanh" | "acos" | "asin" | "atan"
            | "acosh" | "asinh" | "atanh" | "exp" | "log" | "pow" | "sqrt" | "fabs" | "floor"
            | "ceil" | "round" => self.math_1(vars)?,

            "atan2" | "fmin" | "fmax" | "mod" => self.math_2(vars)?,

            // OpenCL geometric built-in functions
            "cross" => self.geom_2(vars, V)?,
            "distance" | "dot" => self.geom_2(vars, F)?,
            "length" => self.geom_1(vars, F)?,
            "normalize" => self.geom_1(vars, V)?,

            // memory barrier functions
            "barrier" => VarType::Void,

            // atomics "atomic_add(buf, idx1, idx2, idx3, value)" etc.
            "atomic_add" | "atomic_sub" | "atomic_min" | "atomic_max" => self.atomic_2(vars)?,
            "atomic_inc" | "atomic_dec" => self.atomic_1(vars)?,

            // CS conversion functions
            // TODO: implement source code loading too
            "SRGBtoSRGB" | "SRGBtoLRGB" | "SRGBtoXYZ" | "SRGBtoLAB" | "SRGBtoLCH"
            | "LRGBtoSRGB" | "LRGBtoLRGB" | "LRGBtoXYZ" | "LRGBtoLAB" | "LRGBtoLCH"
            | "XYZtoSRGB" | "XYZtoLRGB" | "XYZtoXYZ" | "XYZtoLAB" | "XYZtoLCH" | "LABtoSRGB"
            | "LABtoLRGB" | "LABtoXYZ" | "LABtoLAB" | "LABtoLCH" | "LCHtoSRGB" | "LCHtoLRGB"
            | "LCHtoXYZ" | "LCHtoLAB" | "LCHtoLCH" => self.cs_v(vars, V)?,

            "YtoSRGB" | "YtoLRGB" | "YtoXYZ" | "YtoLAB" | "YtoLCH" | "LtoSRGB" | "LtoLRGB"
            | "LtoXYZ" | "LtoLAB" | "LtoLCH" => self.cs_f(vars, V)?,

            "SRGBtoY" | "SRGBtoL" | "LRGBtoY" | "LRGBtoL" | "XYZtoY" | "XYZtoL" | "LABtoY"
            | "LABtoL" | "LCHtoY" | "LCHtoL" => self.cs_v(vars, F)?,

            "YtoY" | "YtoL" | "LtoY" | "LtoL" => self.cs_f(vars, F)?,

            "RGBA" if vars.len() == 2 => F,
            "FasI" if vars.len() == 1 => I,
            "IasF" if vars.len() == 1 => F,

            // create vectors or enforce numeric types
            "vec" if vars.len() == 1 && self.is_num(&vars[0])? => V,
            "vec"
                if vars.len() == 3
                    && self.is_num(&vars[0])?
                    && self.is_num(&vars[1])?
                    && self.is_num(&vars[2])? =>
            {
                V
            }
            "float" if vars.len() == 1 && self.is_num(&vars[0])? => F,
            "int" if vars.len() == 1 && self.is_num(&vars[0])? => I,

            "isnan" | "isinf" | "isfinite" | "isnormal"
                if vars.len() == 1 && self.is_num(&vars[0])? =>
            {
                I
            }

            // array constructors
            "array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => VarType::FloatArray(
                1,
                PRIVATE,
                Inference::get_int_lit(&vars[0])?
                    .try_into()
                    .map_err(|_| "Negative array index")?,
                0,
                0,
                0,
            ),
            "array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "bool_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::BoolArray(
                    1,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "bool_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::BoolArray(
                    2,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "bool_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::BoolArray(
                    3,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "bool_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::BoolArray(
                    4,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "int_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => VarType::IntArray(
                1,
                PRIVATE,
                Inference::get_int_lit(&vars[0])?
                    .try_into()
                    .map_err(|_| "Negative array index")?,
                0,
                0,
                0,
            ),
            "int_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::IntArray(
                    2,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "int_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::IntArray(
                    3,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "int_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::IntArray(
                    4,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "float_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::FloatArray(
                    1,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }

            "float_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "float_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "float_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "vec_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => VarType::VecArray(
                1,
                PRIVATE,
                Inference::get_int_lit(&vars[0])?
                    .try_into()
                    .map_err(|_| "Negative array index")?,
                0,
                0,
                0,
            ),
            "vec_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::VecArray(
                    2,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "vec_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::VecArray(
                    3,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "vec_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::VecArray(
                    4,
                    PRIVATE,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            // local array constructors
            "local_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::FloatArray(
                    1,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "local_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "local_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "local_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "local_bool_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::BoolArray(
                    1,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "local_bool_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::BoolArray(
                    2,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "local_bool_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::BoolArray(
                    3,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "local_bool_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::BoolArray(
                    4,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "local_int_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::IntArray(
                    1,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "local_int_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::IntArray(
                    2,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "local_int_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::IntArray(
                    3,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "local_int_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::IntArray(
                    4,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "local_float_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::FloatArray(
                    1,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "local_float_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "local_float_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "local_float_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            "local_vec_array" if vars.len() == 1 && Inference::is_int_lit(&vars[0]) => {
                VarType::VecArray(
                    1,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                    0,
                )
            }
            "local_vec_array"
                if vars.len() == 2
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1]) =>
            {
                VarType::VecArray(
                    2,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                    0,
                )
            }
            "local_vec_array"
                if vars.len() == 3
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2]) =>
            {
                VarType::VecArray(
                    3,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    0,
                )
            }
            "local_vec_array"
                if vars.len() == 4
                    && Inference::is_int_lit(&vars[0])
                    && Inference::is_int_lit(&vars[1])
                    && Inference::is_int_lit(&vars[2])
                    && Inference::is_int_lit(&vars[3]) =>
            {
                VarType::VecArray(
                    4,
                    LOCAL,
                    Inference::get_int_lit(&vars[0])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[1])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[2])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                    Inference::get_int_lit(&vars[3])?
                        .try_into()
                        .map_err(|_| "Negative array index")?,
                )
            }

            // cast from unknown variables to accomodate function or expression return types which cannot be inferred
            "bool" if vars.len() == 1 => B,
            "int" if vars.len() == 1 => I,
            "float" if vars.len() == 1 => F,
            "vec" if vars.len() == 1 => V,
            "vec" if vars.len() == 3 => V,
            name => return Err(format!("Built-in function '{}' not found", name)),
        };

        Ok(var_type)
    }
}
