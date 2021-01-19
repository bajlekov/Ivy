/*
  Copyright (C) 2011-2020 G. Bajlekov

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
use std::collections::HashMap;

use crate::ast::{BinaryOp, ColorSpace, Expr, Index, Literal, Prop, UnaryOp};
use crate::function_id::function_id;
use crate::scope::ScopeTree;

#[derive(Debug, Eq, PartialEq, Copy, Clone)]
pub enum VarType {
    Bool,
    Int,
    Float,
    Vec,
    BoolArray(u8, bool, u64, u64, u64, u64),
    IntArray(u8, bool, u64, u64, u64, u64),
    FloatArray(u8, bool, u64, u64, u64, u64),
    VecArray(u8, bool, u64, u64, u64, u64),
    Buffer { z: u64, cs: ColorSpace },
    Void,
    Unknown,
}

const B: VarType = VarType::Bool;
const I: VarType = VarType::Int;
const F: VarType = VarType::Float;
const V: VarType = VarType::Vec;

impl std::fmt::Display for VarType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VarType::Bool => write!(f, "Bool"),
            VarType::Int => write!(f, "Int"),
            VarType::Float => write!(f, "Float"),
            VarType::Vec => write!(f, "Vec"),
            VarType::BoolArray(d, l, ..) => {
                write!(f, "{}D {}BoolArray", d, if *l { "local " } else { "" })
            }
            VarType::IntArray(d, l, ..) => {
                write!(f, "{}D {}IntArray", d, if *l { "local " } else { "" })
            }
            VarType::FloatArray(d, l, ..) => {
                write!(f, "{}D {}FloatArray", d, if *l { "local " } else { "" })
            }
            VarType::VecArray(d, l, ..) => {
                write!(f, "{}D {}VecArray", d, if *l { "local " } else { "" })
            }
            VarType::Buffer { z, cs } => write!(f, "{}ch {} Buffer]", z, cs),
            VarType::Void => write!(f, "Void"),
            VarType::Unknown => write!(f, "Unknown"),
        }
    }
}

pub struct Inference<'a> {
    pub scope: ScopeTree,
    pub functions: Option<&'a RefCell<HashMap<String, (String, String, VarType)>>>,
}

impl<'a> Inference<'a> {
    pub fn new() -> Inference<'a> {
        Inference {
            scope: ScopeTree::new(),
            functions: None,
        }
    }

    pub fn var_type(&self, expr: &Expr) -> Result<VarType, String> {
        // handle Prop::Ptr separately as it needs information about the array/buffer before indexing
        if let Expr::Index(expr, idx) = expr {
            if let (Expr::Index(expr, _), Index::Prop(Prop::Ptr)) = (&**expr, &**idx) {
                if let Expr::Identifier(id) = &**expr {
                    if let Some(t) = self.scope.get(id) {
                        let t = match t {
                            VarType::IntArray(_, true, ..) => {
                                VarType::IntArray(1, true, 0, 0, 0, 0)
                            }
                            VarType::IntArray(_, false, ..) => {
                                VarType::IntArray(1, false, 0, 0, 0, 0)
                            }
                            VarType::FloatArray(_, true, ..) => {
                                VarType::FloatArray(1, true, 0, 0, 0, 0)
                            }
                            VarType::FloatArray(_, false, ..) => {
                                VarType::FloatArray(1, false, 0, 0, 0, 0)
                            }
                            VarType::Buffer { .. } => VarType::FloatArray(1, false, 0, 0, 0, 0),
                            t => {
                                return Err(format!(
                                "Variable '{}' of type '{}' does not support the '.ptr' property",
                                id, t
                            ))
                            }
                        };

                        return Ok(t);
                    } else {
                        return Err(format!("Variable '{}' is not defined", id));
                    }
                }
            }
        }

        let t = match expr {
            Expr::Literal(Literal::Bool(_)) => B,
            Expr::Literal(Literal::Int(_)) => I,
            Expr::Literal(Literal::Float(_)) => F,
            Expr::Identifier(i) => {
                if let Some(t) = self.scope.get(i) {
                    t
                } else {
                    VarType::Unknown // identifier of unknown type
                }
            }
            Expr::Unary(u) => match (&(*u).op, self.var_type(&u.right)?) {
                (UnaryOp::Not, B) => B,
                (UnaryOp::Neg, I) => I,
                (UnaryOp::Neg, F) => F,
                (UnaryOp::Neg, V) => V,
                (op, t) => {
                    return Err(format!(
                        "Variable of type '{}' does not support unary operation '{:?}'",
                        t, op
                    ))
                }
            },
            Expr::Binary(b) => {
                match (&(*b).op, self.var_type(&b.left)?, self.var_type(&b.right)?) {
                    (BinaryOp::And, B, B) => B,
                    (BinaryOp::Or, B, B) => B,
                    (BinaryOp::Equal, _, _) => B,
                    (BinaryOp::NotEqual, _, _) => B,
                    (BinaryOp::Greater, l, r) if (l == I || l == F) && (r == I || r == F) => B,
                    (BinaryOp::GreaterEqual, l, r) if (l == I || l == F) && (r == I || r == F) => B,
                    (BinaryOp::Less, l, r) if (l == I || l == F) && (r == I || r == F) => B,
                    (BinaryOp::LessEqual, l, r) if (l == I || l == F) && (r == I || r == F) => B,
                    (BinaryOp::Pow, l, r) => self.promote(self.promote(l, r)?, F)?,
                    (BinaryOp::Div, l, r) => self.promote(self.promote(l, r)?, F)?,

                    (BinaryOp::Add, l, r) => self.promote_num(l, r)?,
                    (BinaryOp::Sub, l, r) => self.promote_num(l, r)?,
                    (BinaryOp::Mul, l, r) => self.promote_num(l, r)?,
                    (BinaryOp::Mod, l, r) => self.promote_num(l, r)?,
                    (op, l, r) => {
                        return Err(format!(
                    "Unable to infer type of operation '{:?}' with arguments of type '{}' and '{}'",
                    op, l, r
                ))
                    }
                }
            }
            Expr::Index(expr, idx) => match (self.var_type(expr)?, &**idx) {
                (V, Index::Vec(_)) => F,
                (VarType::Buffer { .. }, Index::Vec(_)) => I,
                (V, Index::ColorSpace(c)) => match c {
                    // 3ch buffer
                    ColorSpace::SRGB => V,
                    ColorSpace::LRGB => V,
                    ColorSpace::XYZ => V,
                    ColorSpace::LAB => V,
                    ColorSpace::LCH => V,
                    ColorSpace::Y => F,
                    ColorSpace::L => F,
                },
                (F, Index::ColorSpace(c)) => match c {
                    // 1ch buffer
                    ColorSpace::SRGB => V,
                    ColorSpace::LRGB => V,
                    ColorSpace::XYZ => V,
                    ColorSpace::LAB => V,
                    ColorSpace::LCH => V,
                    ColorSpace::Y => F,
                    ColorSpace::L => F,
                },

                (F, Index::Prop(Prop::Int)) => I,
                (F, Index::Prop(Prop::Idx)) => I,
                (F, Index::Prop(Prop::IntPtr)) => VarType::IntArray(1, false, 0, 0, 0, 0), // only available for buffers

                (VarType::Buffer { .. }, Index::Array1D(..)) => F,
                (VarType::Buffer { z: 3, .. }, Index::Array2D(..)) => V,
                (VarType::Buffer { z: 1, .. }, Index::Array2D(..)) => F,
                (VarType::Buffer { .. }, Index::Array3D(..)) => F,

                (VarType::BoolArray(1, ..), Index::Array1D(..)) => B,
                (VarType::BoolArray(2, ..), Index::Array2D(..)) => B,
                (VarType::BoolArray(3, ..), Index::Array3D(..)) => B,
                (VarType::BoolArray(4, ..), Index::Array4D(..)) => B,

                (VarType::IntArray(1, ..), Index::Array1D(..)) => I,
                (VarType::IntArray(2, ..), Index::Array2D(..)) => I,
                (VarType::IntArray(3, ..), Index::Array3D(..)) => I,
                (VarType::IntArray(4, ..), Index::Array4D(..)) => I,

                (VarType::FloatArray(1, ..), Index::Array1D(..)) => F,
                (VarType::FloatArray(2, ..), Index::Array2D(..)) => F,
                (VarType::FloatArray(3, ..), Index::Array3D(..)) => F,
                (VarType::FloatArray(4, ..), Index::Array4D(..)) => F,

                (VarType::VecArray(1, ..), Index::Array1D(..)) => V,
                (VarType::VecArray(2, ..), Index::Array2D(..)) => V,
                (VarType::VecArray(3, ..), Index::Array3D(..)) => V,
                (VarType::VecArray(4, ..), Index::Array4D(..)) => V,

                _ => self.var_type(expr)?,
            },
            Expr::Grouping(e) => self.var_type(&**e)?,
            Expr::Call(id, e) => {
                if let Ok(t) = self.builtin(&id, &**e) {
                    t
                } else if let Ok(t) = self.function(&id, &**e) {
                    t
                } else {
                    VarType::Unknown // function call with unknown return type
                }
            }
            Expr::Array(v) => {
                if v.is_empty() {
                    return Err(format!("Unable to construct empty array"));
                } else {
                    // TODO: assert that all other elements have the same type
                    match self.var_type(&v[0])? {
                        B => VarType::BoolArray(1, false, v.len() as u64, 0, 0, 0),
                        I => VarType::IntArray(1, false, v.len() as u64, 0, 0, 0),
                        F => VarType::FloatArray(1, false, v.len() as u64, 0, 0, 0),
                        V => VarType::VecArray(1, false, v.len() as u64, 0, 0, 0),
                        VarType::BoolArray(1, _, a, ..) => {
                            VarType::BoolArray(2, false, v.len() as u64, a, 0, 0)
                        }
                        VarType::BoolArray(2, _, a, b, ..) => {
                            VarType::BoolArray(3, false, v.len() as u64, a, b, 0)
                        }
                        VarType::BoolArray(3, _, a, b, c, ..) => {
                            VarType::BoolArray(4, false, v.len() as u64, a, b, c)
                        }
                        VarType::IntArray(1, _, a, ..) => {
                            VarType::IntArray(2, false, v.len() as u64, a, 0, 0)
                        }
                        VarType::IntArray(2, _, a, b, ..) => {
                            VarType::IntArray(3, false, v.len() as u64, a, b, 0)
                        }
                        VarType::IntArray(3, _, a, b, c, ..) => {
                            VarType::IntArray(4, false, v.len() as u64, a, b, c)
                        }
                        VarType::FloatArray(1, _, a, ..) => {
                            VarType::FloatArray(2, false, v.len() as u64, a, 0, 0)
                        }
                        VarType::FloatArray(2, _, a, b, ..) => {
                            VarType::FloatArray(3, false, v.len() as u64, a, b, 0)
                        }
                        VarType::FloatArray(3, _, a, b, c, ..) => {
                            VarType::FloatArray(4, false, v.len() as u64, a, b, c)
                        }
                        VarType::VecArray(1, _, a, ..) => {
                            VarType::VecArray(2, false, v.len() as u64, a, 0, 0)
                        }
                        VarType::VecArray(2, _, a, b, ..) => {
                            VarType::VecArray(3, false, v.len() as u64, a, b, 0)
                        }
                        VarType::VecArray(3, _, a, b, c, ..) => {
                            VarType::VecArray(4, false, v.len() as u64, a, b, c)
                        }
                        t => return Err(format!("Unable to construct array of type '{}'", t)),
                    }
                }
            }
        };

        Ok(t)
    }

    // promote: int -> float -> vec
    pub fn promote_num(&self, a: VarType, b: VarType) -> Result<VarType, String> {
        Ok(match (a, b) {
            (I, I) => I,
            (F, F) | (I, F) | (F, I) => F,
            (V, V) | (V, F) | (F, V) | (V, I) | (I, V) => V,
            (a, b) => {
                return Err(format!(
                    "Unable to promote type '{}' and '{}' to a common numeric type",
                    a, b
                ))
            }
        })
    }

    pub fn promote(&self, a: VarType, b: VarType) -> Result<VarType, String> {
        Ok(match (a, b) {
            (B, B) => B,
            (I, I) => I,
            (F, F) | (I, F) | (F, I) => F,
            (V, V) | (V, F) | (F, V) | (V, I) | (I, V) => V,
            (a, b) => {
                return Err(format!(
                    "Unable to promote type '{}' and '{}' to a common type",
                    a, b
                ))
            }
        })
    }

    // can be coerced to float or int
    fn is_num(&self, a: &Expr) -> Result<bool, String> {
        let a = self.var_type(a)?;
        Ok(a == I || a == F)
    }

    fn is_int_lit(&self, a: &Expr) -> bool {
        if let Expr::Literal(Literal::Int(_)) = a {
            true
        } else {
            false
        }
    }

    fn get_int_lit(&self, a: &Expr) -> Result<i32, String> {
        if let Expr::Literal(Literal::Int(v)) = a {
            Ok(*v)
        } else {
            Err(format!("Expected an integer literal, found:\n{:?}", a))
        }
    }

    fn is_num_vec(&self, a: &Expr) -> Result<bool, String> {
        let a = self.var_type(a)?;
        Ok(a == I || a == F || a == V)
    }

    fn function(&self, id: &str, vars: &[Expr]) -> Result<VarType, String> {
        let vars = vars
            .iter()
            .map(|e| self.var_type(e))
            .collect::<Result<Vec<_>, _>>()?;

        let id = function_id(id, &vars);

        if let Some(f) = self.functions {
            if let Some((_, _, v)) = f.borrow().get(&id) {
                Ok(*v)
            } else {
                Err(format!("Function '{}' is not defined", id))
            }
        } else {
            Err(format!("Function list is not initialized"))
        }
    }

    fn math_1(&self, vars: &[Expr]) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to math function, found {}",
                vars.len()
            ));
        }
        match self.is_num_vec(&vars[0])? {
            true => self.promote_num(self.var_type(&vars[0])?, F),
            false => {
                return Err(format!(
                    "Expected numeric argument to math function, found argument of type '{}'",
                    self.var_type(&vars[0])?
                ))
            }
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
            (true, true) => self.promote_num(
                self.promote_num(self.var_type(&vars[1])?, self.var_type(&vars[0])?)?,
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

    fn geom_1(&self, vars: &[Expr], t: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to geometry function, found {}",
                vars.len()
            ));
        }
        match self.is_num_vec(&vars[0])? {
            true => Ok(t),
            false => {
                return Err(format!(
                    "Expected numeric argument to geometry function, found argument of type '{}'",
                    self.var_type(&vars[0])?
                ))
            }
        }
    }

    fn geom_2(&self, vars: &[Expr], t: VarType) -> Result<VarType, String> {
        if vars.len() != 2 {
            return Err(format!(
                "Expected 2 arguments to geometry function, found {}",
                vars.len()
            ));
        }
        match (self.is_num_vec(&vars[0])?, self.is_num_vec(&vars[1])?) {
            (true, true) => Ok(t),
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

    fn cs_v(&self, vars: &[Expr], t: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to color space function, found {}",
                vars.len()
            ));
        }
        match self.is_num_vec(&vars[0])? {
            true => Ok(t),
            false => {
                return Err(format!(
                    "Expected numeric argument to geometry function, found argument of type '{}'",
                    self.var_type(&vars[0])?
                ))
            }
        }
    }

    fn cs_f(&self, vars: &[Expr], t: VarType) -> Result<VarType, String> {
        if vars.len() != 1 {
            return Err(format!(
                "Expected 1 argument to color space function, found {}",
                vars.len()
            ));
        }
        match self.is_num(&vars[0])? {
            true => Ok(t),
            false => {
                return Err(format!(
                "Expected numeric argument to color space function, found argument of type '{}'",
                self.var_type(&vars[0])?
            ))
            }
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
            t => Err(format!(
                "Unable to perform atomic operation on variable of type '{}'",
                t
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
            (t1 @ VarType::FloatArray(1, ..), t2) => Err(format!("Atomic operation on variable of type '{}' expected a 'Float' argument, found argument of type '{}'", t1, t2)),
            (t1 @ VarType::IntArray(1, ..), t2) => Err(format!("Atomic operation on variable of type '{}' expected an 'Int' argument, found argument of type '{}'", t1, t2)),
            (t, _) => Err(format!("Unable to perform atomic operation on variable of type '{}', expected Float or Int array", t)),
        }
    }

    pub fn builtin(&self, id: &str, vars: &[Expr]) -> Result<VarType, String> {
        let t = match id {
            "get_work_dim" if vars.is_empty() => I,
            "get_global_size" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_global_id" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_local_size" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_local_id" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_num_groups" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_group_id" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,
            "get_global_offset" if vars.len() == 1 && self.is_int_lit(&vars[0]) => I,

            // type-inferred 0 and 1
            "zero" if vars.len() == 1 && self.is_num_vec(&vars[0])? => self.var_type(&vars[0])?,
            "one" if vars.len() == 1 && self.is_num_vec(&vars[0])? => self.var_type(&vars[0])?,

            // OpenCL math built-in functions: clamp, degrees, max, min, mix, radians, step, smoothstep, sign
            "clamp" if vars.len() == 3 => {
                let v = self.var_type(&vars[0])?;
                let l = self.var_type(&vars[1])?;
                let h = self.var_type(&vars[2])?;
                self.promote_num(v, self.promote_num(l, h)?)?
            }
            "mix" if vars.len() == 3 => {
                let l = self.var_type(&vars[0])?;
                let h = self.var_type(&vars[1])?;
                let m = self.var_type(&vars[2])?;
                self.promote_num(m, self.promote_num(l, h)?)?
            }
            "min" if vars.len() == 2 => {
                let l = self.var_type(&vars[0])?;
                let r = self.var_type(&vars[1])?;
                self.promote_num(l, r)?
            }
            "max" if vars.len() == 2 => {
                let l = self.var_type(&vars[0])?;
                let r = self.var_type(&vars[1])?;
                self.promote_num(l, r)?
            }
            "sign" if vars.len() == 1 => self.var_type(&vars[0])?,
            "abs" if vars.len() == 1 => self.var_type(&vars[0])?,
            // min, max generate same instructions as fmin, fmax on GCN4
            "range" if vars.len() == 3 => VarType::Float,
            "runif" if vars.len() == 3 => VarType::Float,
            "rnorm" if vars.len() == 3 => VarType::Float,
            "rpois" if vars.len() == 3 => VarType::Float,

            // OpenCL math built-in functions (selection)
            // returns F or V
            // TODO: handle fmin/min, fmax/max, pow/pown/powr, fabs/abs
            "cos" => self.math_1(vars)?,
            "sin" => self.math_1(vars)?,
            "tan" => self.math_1(vars)?,
            "cosh" => self.math_1(vars)?,
            "sinh" => self.math_1(vars)?,
            "tanh" => self.math_1(vars)?,
            "acos" => self.math_1(vars)?,
            "asin" => self.math_1(vars)?,
            "atan" => self.math_1(vars)?,
            "acosh" => self.math_1(vars)?,
            "asinh" => self.math_1(vars)?,
            "atanh" => self.math_1(vars)?,
            "atan2" => self.math_2(vars)?,
            "exp" => self.math_1(vars)?,
            "log" => self.math_1(vars)?,
            "pow" => self.math_1(vars)?,
            "sqrt" => self.math_1(vars)?,
            "fabs" => self.math_1(vars)?,
            "floor" => self.math_1(vars)?,
            "ceil" => self.math_1(vars)?,
            "round" => self.math_1(vars)?,
            "fmin" => self.math_2(vars)?,
            "fmax" => self.math_2(vars)?,
            "mod" => self.math_2(vars)?,

            // OpenCL geometric built-in functions
            "cross" => self.geom_2(vars, V)?,
            "distance" => self.geom_2(vars, F)?,
            "dot" => self.geom_2(vars, F)?,
            "length" => self.geom_1(vars, F)?,
            "normalize" => self.geom_1(vars, V)?,

            // memory barrier functions
            "barrier" => VarType::Void,

            // atomics "atomic_add(buf, idx1, idx2, idx3, value)" etc.
            "atomic_add" => self.atomic_2(vars)?,
            "atomic_sub" => self.atomic_2(vars)?,
            "atomic_inc" => self.atomic_1(vars)?,
            "atomic_dec" => self.atomic_1(vars)?,
            "atomic_min" => self.atomic_2(vars)?,
            "atomic_max" => self.atomic_2(vars)?,

            // CS conversion functions
            // TODO: implement source code loading too
            "SRGBtoSRGB" => self.cs_v(vars, V)?,
            "SRGBtoLRGB" => self.cs_v(vars, V)?,
            "SRGBtoXYZ" => self.cs_v(vars, V)?,
            "SRGBtoLAB" => self.cs_v(vars, V)?,
            "SRGBtoLCH" => self.cs_v(vars, V)?,
            "SRGBtoY" => self.cs_v(vars, F)?,
            "SRGBtoL" => self.cs_v(vars, F)?,

            "LRGBtoSRGB" => self.cs_v(vars, V)?,
            "LRGBtoLRGB" => self.cs_v(vars, V)?,
            "LRGBtoXYZ" => self.cs_v(vars, V)?,
            "LRGBtoLAB" => self.cs_v(vars, V)?,
            "LRGBtoLCH" => self.cs_v(vars, V)?,
            "LRGBtoY" => self.cs_v(vars, F)?,
            "LRGBtoL" => self.cs_v(vars, F)?,

            "XYZtoSRGB" => self.cs_v(vars, V)?,
            "XYZtoLRGB" => self.cs_v(vars, V)?,
            "XYZtoXYZ" => self.cs_v(vars, V)?,
            "XYZtoLAB" => self.cs_v(vars, V)?,
            "XYZtoLCH" => self.cs_v(vars, V)?,
            "XYZtoY" => self.cs_v(vars, F)?,
            "XYZtoL" => self.cs_v(vars, F)?,

            "LABtoSRGB" => self.cs_v(vars, V)?,
            "LABtoLRGB" => self.cs_v(vars, V)?,
            "LABtoXYZ" => self.cs_v(vars, V)?,
            "LABtoLAB" => self.cs_v(vars, V)?,
            "LABtoLCH" => self.cs_v(vars, V)?,
            "LABtoY" => self.cs_v(vars, F)?,
            "LABtoL" => self.cs_v(vars, F)?,

            "LCHtoSRGB" => self.cs_v(vars, V)?,
            "LCHtoLRGB" => self.cs_v(vars, V)?,
            "LCHtoXYZ" => self.cs_v(vars, V)?,
            "LCHtoLAB" => self.cs_v(vars, V)?,
            "LCHtoLCH" => self.cs_v(vars, V)?,
            "LCHtoY" => self.cs_v(vars, F)?,
            "LCHtoL" => self.cs_v(vars, F)?,

            "YtoSRGB" => self.cs_f(vars, V)?,
            "YtoLRGB" => self.cs_f(vars, V)?,
            "YtoXYZ" => self.cs_f(vars, V)?,
            "YtoLAB" => self.cs_f(vars, V)?,
            "YtoLCH" => self.cs_f(vars, V)?,
            "YtoY" => self.cs_f(vars, F)?,
            "YtoL" => self.cs_f(vars, F)?,

            "LtoSRGB" => self.cs_f(vars, V)?,
            "LtoLRGB" => self.cs_f(vars, V)?,
            "LtoXYZ" => self.cs_f(vars, V)?,
            "LtoLAB" => self.cs_f(vars, V)?,
            "LtoLCH" => self.cs_f(vars, V)?,
            "LtoY" => self.cs_f(vars, F)?,
            "LtoL" => self.cs_f(vars, F)?,

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

            "isnan" if vars.len() == 1 && self.is_num(&vars[0])? => I,
            "isinf" if vars.len() == 1 && self.is_num(&vars[0])? => I,
            "isfinite" if vars.len() == 1 && self.is_num(&vars[0])? => I,
            "isnormal" if vars.len() == 1 && self.is_num(&vars[0])? => I,

            // array constructors
            "array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::FloatArray(1, false, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "bool_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::BoolArray(1, false, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "bool_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::BoolArray(
                    2,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "bool_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::BoolArray(
                    3,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "bool_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::BoolArray(
                    4,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "int_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::IntArray(1, false, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "int_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::IntArray(
                    2,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "int_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::IntArray(
                    3,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "int_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::IntArray(
                    4,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "float_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::FloatArray(1, false, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }

            "float_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "float_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "float_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "vec_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::VecArray(1, false, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "vec_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::VecArray(
                    2,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "vec_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::VecArray(
                    3,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "vec_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::VecArray(
                    4,
                    false,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            // local array constructors
            "local_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::FloatArray(1, true, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "local_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "local_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "local_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "local_bool_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::BoolArray(1, true, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "local_bool_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::BoolArray(
                    2,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "local_bool_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::BoolArray(
                    3,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "local_bool_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::BoolArray(
                    4,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "local_int_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::IntArray(1, true, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "local_int_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::IntArray(
                    2,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "local_int_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::IntArray(
                    3,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "local_int_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::IntArray(
                    4,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "local_float_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::FloatArray(1, true, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "local_float_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::FloatArray(
                    2,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "local_float_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::FloatArray(
                    3,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "local_float_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::FloatArray(
                    4,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            "local_vec_array" if vars.len() == 1 && self.is_int_lit(&vars[0]) => {
                VarType::VecArray(1, true, self.get_int_lit(&vars[0])? as u64, 0, 0, 0)
            }
            "local_vec_array"
                if vars.len() == 2 && self.is_int_lit(&vars[0]) && self.is_int_lit(&vars[1]) =>
            {
                VarType::VecArray(
                    2,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    0,
                    0,
                )
            }
            "local_vec_array"
                if vars.len() == 3
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2]) =>
            {
                VarType::VecArray(
                    3,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    0,
                )
            }
            "local_vec_array"
                if vars.len() == 4
                    && self.is_int_lit(&vars[0])
                    && self.is_int_lit(&vars[1])
                    && self.is_int_lit(&vars[2])
                    && self.is_int_lit(&vars[3]) =>
            {
                VarType::VecArray(
                    4,
                    true,
                    self.get_int_lit(&vars[0])? as u64,
                    self.get_int_lit(&vars[1])? as u64,
                    self.get_int_lit(&vars[2])? as u64,
                    self.get_int_lit(&vars[3])? as u64,
                )
            }

            // cast from unknown variables to accomodate function or expression return types which cannot be inferred
            "bool" if vars.len() == 1 => B,
            "int" if vars.len() == 1 => I,
            "float" if vars.len() == 1 => F,
            "vec" if vars.len() == 1 => V,
            "vec" if vars.len() == 3 => V,
            n => return Err(format!("Built-in function '{}' not found", n)),
        };

        Ok(t)
    }
}
