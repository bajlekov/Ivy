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

use crate::ast::{
    BinaryExpr, BinaryOp, Cond, Expr, Index, Literal, Prop, Stmt, UnaryExpr, UnaryOp,
};
use crate::function_id::function_id;

use crate::inference::{Inference, VarType};

pub struct Generator<'a> {
    ast: Vec<Stmt>,
    inference: RefCell<Inference<'a>>,
    constants: RefCell<HashMap<String, &'a Expr>>,
    functions: RefCell<HashMap<String, &'a Stmt>>,
    kernels: RefCell<HashMap<String, &'a Stmt>>,
    generated_constants: RefCell<Option<String>>,
    generated_functions: RefCell<HashMap<String, (String, String, VarType, HashSet<String>)>>, // collect specialized functions: (declaration, definition, return value, dependencies)
    generated_kernels: RefCell<HashMap<String, String>>, // collect specialized kernels: (kernel)
    dependencies: RefCell<Vec<HashSet<String>>>, // collects dependencies of currently parsed function in a stack
}

// helper function for generating up to 4D array indices
fn idx4(dim: u8, a: u64, b: u64, c: u64, d: u64) -> Result<String, String> {
    Ok(match dim {
        1 => format!("[{}]", a),
        2 => format!("[{}][{}]", a, b),
        3 => format!("[{}][{}][{}]", a, b, c),
        4 => format!("[{}][{}][{}][{}]", a, b, c, d),
        n => {
            return Err(format!(
                "Array dimensions must be between 1 and 4, found: {}",
                n
            ))
        }
    })
}

impl<'a> Generator<'a> {
    #[allow(clippy::ptr_arg)]
    pub fn new(ast: Vec<Stmt>) -> Generator<'a> {
        Generator {
            ast,
            inference: RefCell::new(Inference::new()),
            constants: RefCell::new(HashMap::new()),
            functions: RefCell::new(HashMap::new()),
            kernels: RefCell::new(HashMap::new()),
            generated_constants: RefCell::new(None),
            generated_functions: RefCell::new(HashMap::new()),
            generated_kernels: RefCell::new(HashMap::new()),
            dependencies: RefCell::new(Vec::new()),
        }
    }

    pub fn prepare(&'a self) {
        for stmt in &self.ast {
            match stmt {
                Stmt::Const(id, expr) => {
                    self.constants.borrow_mut().insert(id.clone(), &expr);
                }
                Stmt::Function { id, .. } => {
                    self.functions.borrow_mut().insert(id.clone(), &stmt);
                }
                Stmt::Kernel { id, .. } => {
                    self.kernels.borrow_mut().insert(id.clone(), &stmt);
                }
                Stmt::Comment(..) => {}
                Stmt::Eof => {}
                _ => panic!("Unexpected statement in file scope!"),
            }
        }
    }

    fn function(&'a self, name: &str, input: &[VarType]) -> Result<String, String> {
        let id = function_id(name, input);

        if self.generated_functions.borrow().contains_key(&id) {
            return Ok(id);
        }

        // parse function
        if let Some(Stmt::Function { args, body, .. }) = self.functions.borrow().get(name) {
            // new function scope, keep outer scope reference to restore at the end
            let outer_scope = self.inference.borrow().scope.current.get();
            self.inference.borrow().scope.open();
            self.inference.borrow().scope.set_parent(0); // no parent scope
            self.inference.borrow().scope.placeholder("return");

            // new frame on the dependency stack
            self.dependencies.borrow_mut().push(HashSet::new());

            let mut definition = "(varying int _x, varying int _y, varying int _z, \n".to_string();
            let mut declaration;

            // generate argument signatures
            for (k, v) in args.iter().enumerate() {
                let arg = match input[k] {
                    VarType::Buffer { .. } => {
                        format!("uniform float {}[], uniform int ___str_{}[]", v, v)
                    }
                    VarType::Int => format!("int {}", v),
                    VarType::Float => format!("float {}", v),
                    VarType::Vec => format!("float<3> {}", v),
                    VarType::BoolArray(n, l, a, b, c, d) => {
                        format!(
                            "{}bool {}{}",
                            if l { "local " } else { "" },
                            v,
                            idx4(n, a, b, c, d)?
                        )
                    }
                    VarType::IntArray(n, l, a, b, c, d) => {
                        format!(
                            "{}int {}{}",
                            if l { "local " } else { "" },
                            v,
                            idx4(n, a, b, c, d)?
                        )
                    }
                    VarType::FloatArray(n, l, a, b, c, d) => {
                        format!(
                            "{}float {}{}",
                            if l { "local " } else { "" },
                            v,
                            idx4(n, a, b, c, d)?
                        )
                    }
                    VarType::VecArray(n, l, a, b, c, d) => {
                        format!(
                            "{}float<3> {}{}",
                            if l { "local " } else { "" },
                            v,
                            idx4(n, a, b, c, d)?
                        )
                    }
                    t => {
                        return Err(format!(
                            "Argument '{}' of function '{}' has unsupported type '{}'",
                            v, name, t
                        ))
                    }
                };

                self.inference.borrow().scope.add(v, input[k]); // add argument to scope

                // comma-separate arguments
                if k < args.len() - 1 {
                    definition.push_str(&format!("\t{},\n", arg));
                } else {
                    definition.push_str(&format!("\t{}\n", arg));
                }
            }
            definition.push(')');

            declaration = definition.clone(); // copy function signature into declaration

            // construct function body
            definition.push_str(" {\n");
            for v in body {
                definition.push_str(&self.gen_stmt(v)?);
            }

            // get function return type
            let ret_type = self
                .inference
                .borrow()
                .scope
                .get("return")
                .unwrap_or(VarType::Void); // use void return type if none specified
            let ret_string = match ret_type {
                VarType::Bool => "bool",
                VarType::Int => "int",
                VarType::Float => "float",
                VarType::Vec => "float<3>",
                VarType::Void => "void",
                _ => return Err(format!("Unknown return type of function '{}'", name)),
            };
            self.inference.borrow().scope.close();
            self.inference.borrow().scope.set_current(outer_scope);

            // collect function dependencies from stack
            let deps = self
                .dependencies
                .borrow_mut()
                .pop()
                .ok_or_else(|| "No dependency frame found!".to_string())?;

            // add function return type to definition
            definition = format!("{} {} {}}}", ret_string, id, definition);

            // add function return type to declaration
            declaration = format!("{} {} {};", ret_string, id, declaration);

            // register generated_functions
            self.generated_functions
                .borrow_mut()
                .insert(id.clone(), (declaration, definition, ret_type, deps));

            Ok(id)
        } else {
            Err(format!("Function '{}' not found", id))
        }
    }

    pub fn kernel(&'a self, name: &str, input: &[VarType]) -> Result<String, String> {
        let id = function_id(name, input);

        if let Some(k) = self.generated_kernels.borrow().get(&id) {
            return Ok(k.clone());
        }

        self.inference.borrow_mut().functions = Some(&self.generated_functions); // link generated functions to inference engine
        self.inference.borrow().scope.clear(); // clear leftover scopes
        *self.dependencies.borrow_mut() = vec![]; // clear the dependency stack

        // parse constants
        if self.generated_constants.borrow().is_none() {
            let mut consts = String::new();
            for (k, v) in self.constants.borrow().iter() {
                consts.push_str(&format!("const {}", self.gen_var(k, v)?));
            }
            self.generated_constants.replace(Some(consts));
        }

        if let Some(Stmt::Kernel { id, args, body }) = self.kernels.borrow().get(name) {
            // new kernel scope with void return type
            self.inference.borrow().scope.open();
            self.inference.borrow().scope.add("return", VarType::Void); // explicitly expect void return type for kernels

            // new frame on the dependency stack
            self.dependencies.borrow_mut().push(HashSet::new());

            // construct kernel signature
            let mut arguments = "\n\tuniform int _dim[],\n".to_string();
            for (k, v) in args.iter().enumerate() {
                // construct argument signature
                let arg = format!(
                    "{} {}{}",
                    match input[k] {
                        VarType::Buffer { .. } => "uniform float",
                        VarType::Int => "uniform int",
                        VarType::Float => "uniform float",
                        VarType::IntArray(1, ..) => "uniform int",
                        VarType::FloatArray(1, ..) => "uniform float",
                        t =>
                            return Err(format!(
                                "Type '{}' of argument '{}' not supported in kernel arguments",
                                t, v
                            )),
                    },
                    v,
                    match input[k] {
                        VarType::Buffer { .. } => format!("[], uniform int ___str_{}[]", v),
                        VarType::IntArray(1, ..) => "[]".into(),
                        VarType::FloatArray(1, ..) => "[]".into(),
                        t =>
                            return Err(format!(
                                "Type '{}' of argument '{}' not supported in kernel arguments",
                                t, v
                            )),
                    },
                );

                self.inference.borrow().scope.add(v, input[k]); // add argument to scope

                // comma-separate arguments
                if k < args.len() - 1 {
                    arguments.push_str(&format!("\t{},\n", arg));
                } else {
                    arguments.push_str(&format!("\t{}\n", arg));
                }
            }

            let mut kernel = format!("task void ___task_{} ({}) {{", id, &arguments);
            kernel.push_str(
                "
uniform int _xmin = _dim[0] + taskIndex0*_dim[6];
uniform int _xmax = _dim[0] + min(((uniform int)taskIndex0 + 1)*_dim[6], _dim[3]);
uniform int _ymin = _dim[1] + taskIndex1*_dim[7];
uniform int _ymax = _dim[1] + min(((uniform int)taskIndex1 + 1)*_dim[7], _dim[4]);
uniform int _zmin = _dim[2] + taskIndex2*_dim[8];
uniform int _zmax = _dim[2] + min(((uniform int)taskIndex2 + 1)*_dim[8], _dim[5]);

// swap _x___ and _y___ if _dim[3]==0
if (_dim[3]<16 && _dim[4]>16) {
    uniform int _tmin = _ymin;
    uniform int _tmax = _ymax;
    _ymin = _xmin;
    _ymax = _xmax;
    _xmin = _tmin;
    _xmax = _tmax;
}

foreach (_z = _zmin ... _zmax, _1 = _ymin ... _ymax, _0 = _xmin ... _xmax) {

int _x, _y;
if (_dim[3]<16 && _dim[4]>16) {
    _y = _0;
    _x = _1;   
} else {
    _x = _0;
    _y = _1;   
}\n",
            );

            // construct kernel body
            for v in body {
                kernel.push_str(&self.gen_stmt(v)?);
            }
            kernel.push_str("}\n}\n");

            kernel.push_str(&format!("export void {} ({}) {{", id, &arguments));

            kernel.push_str(
                "
uniform int _nx = ceil((uniform float)_dim[3]/_dim[6]);
uniform int _ny = ceil((uniform float)_dim[4]/_dim[7]);
uniform int _nz = ceil((uniform float)_dim[5]/_dim[8]);
",
            );

            kernel.push_str(&format!("launch[_nx, _ny, _nz] ___task_{}(", id));
            kernel.push_str("\n\t_dim,\n\t");
            for (k, v) in args.iter().enumerate() {
                match input[k] {
                    VarType::Buffer { .. } => kernel.push_str(&format!("{}, ___str_{}", v, v)),
                    _ => kernel.push_str(&format!("{}", v)),
                }
                if k < args.len() - 1 {
                    kernel.push_str(", ");
                } else {
                    kernel.push_str(");\n");
                }
            }
            kernel.push_str("}");

            // check whether return value is of type void
            if self.inference.borrow().scope.get("return") != Some(VarType::Void) {
                return Err(format!(
                    "Expected return value of type 'Void' for kernel '{}'",
                    name
                ));
            }
            self.inference.borrow().scope.close();

            // add includes, constants and function dependencies
            let (deps_declarations, deps_definitions) = self.gen_dependencies()?; // pops dependencies frame
            Ok(format!(
                "#include \"std.ispc\"\n{}\n{}\n{}\n{}",
                self.generated_constants
                    .borrow()
                    .as_ref()
                    .unwrap_or(&format!("")),
                deps_declarations,
                deps_definitions,
                kernel
            ))
        } else {
            Err(format!("Kernel '{}' not found in source", name))
        }
    }

    fn gen_dependencies(&self) -> Result<(String, String), String> {
        let mut satisfied = HashSet::new(); // dependencies which are already satisfied, eventually becomes the final list of dependencies
        let mut deps = self
            .dependencies
            .borrow_mut()
            .pop()
            .ok_or_else(|| "No dependency frame found!".to_string())?
            .into_iter()
            .collect::<Vec<_>>();

        // get nested dependencies
        while let Some(id) = deps.pop() {
            let deps_nested = self
                .generated_functions
                .borrow()
                .get(&id)
                .ok_or::<String>(format!("No function dependency '{}' found", &id))?
                .3
                .clone();
            satisfied.insert(id);

            deps_nested.into_iter().for_each(|id| {
                if satisfied.get(&id).is_none() {
                    deps.push(id);
                }
            })
        }

        let deps = satisfied;

        let mut declarations = String::new();
        let mut definitions = String::new();
        for id in deps.iter() {
            let function = self.generated_functions.borrow();
            let function = function
                .get(id)
                .ok_or::<String>(format!("No function dependency '{}' found", id))?;

            declarations.push_str(&function.0);
            declarations.push_str("\n\n");
            definitions.push_str(&function.1);
            definitions.push_str("\n\n");
        }

        Ok((declarations, definitions))
    }

    fn gen_stmt(&'a self, stmt: &Stmt) -> Result<String, String> {
        let stmt = match stmt {
            Stmt::Var(id, expr) => self.gen_var(id, expr)?,
            Stmt::Const(id, expr) => format!("const {}", self.gen_var(id, expr)?),
            Stmt::Assign(id, expr) => self.gen_assign(id, expr)?,
            Stmt::Call(id, args) => {
                let args_str = args
                    .iter()
                    .map(|e| self.gen_expr(e))
                    .collect::<Result<Vec<_>, _>>()?;
                let vars = args
                    .iter()
                    .map(|e| self.inference.borrow().var_type(e))
                    .collect::<Result<Vec<_>, _>>()?;
                if self.inference.borrow().builtin(id, args).is_ok() {
                    format!("{};\n", self.gen_call(id, &args_str, &vars)?)
                } else {
                    let id = self.function(id, &vars)?;
                    let mut args_str = args_str;
                    args_str.insert(0, "_x, _y, _z".into());
                    format!("{};\n", self.gen_call(&id, &args_str, &vars)?)
                }
            }
            Stmt::For {
                var,
                from,
                to,
                step,
                body,
            } => self.gen_for(var, from, to, step, body)?,
            Stmt::IfElse {
                cond_list,
                else_body,
            } => self.gen_if_else(cond_list, else_body)?,
            Stmt::While { cond, body } => self.gen_while(cond, body)?,
            Stmt::Return(None) => match self.inference.borrow().scope.get("return") {
                Some(VarType::Void) | None => "return;\n".into(),
                Some(t) => {
                    return Err(format!(
                        "Void return statement inconsistent with previously used return type '{}'",
                        t
                    ))
                }
            },
            Stmt::Continue => "continue;\n".into(),
            Stmt::Break => "break;\n".into(),
            Stmt::Return(Some(expr)) => {
                let expr_str = self.gen_expr(expr)?; // generate before assessing type!

                // return value is either new, same as--, or promoted from the previous one
                let new = self.inference.borrow().var_type(expr)?;
                let old = self.inference.borrow().scope.get("return").unwrap_or(new);
                let promoted = self.inference.borrow().promote(new, old)?;

                self.inference.borrow().scope.overwrite("return", promoted);

                format!("return {};\n", expr_str)
            }
            Stmt::Comment(c) => format!("//{}\n", c),
            stmt => return Err(format!("Unable to generate code for:\n{:?}", stmt)),
        };

        Ok(stmt)
    }

    fn gen_for(
        &'a self,
        var: &str,
        from: &Expr,
        to: &Expr,
        step: &Option<Expr>,
        body: &[Stmt],
    ) -> Result<String, String> {
        self.inference.borrow().scope.open();

        let mut s;

        // infer var type
        // TODO: does code need to be generated before inference? e.g. function calls?
        let from_type = self.inference.borrow().var_type(from)?;
        let to_type = self.inference.borrow().var_type(to)?;

        let mut var_type = self.inference.borrow().promote_num(from_type, to_type)?;

        if let Some(step) = &step {
            let step_type = self.inference.borrow().var_type(step)?;
            var_type = self.inference.borrow().promote_num(var_type, step_type)?;
            self.inference.borrow().scope.add(var, var_type);

            s = format!(
                "for ({var_type} {var} = {from}; ({step}>0)?({var}<={to}):({var}>={to}); {var} += {step}) {{\n",
                var_type = match var_type {
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float<3>",
                    _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
                },
                var = var,
                from = self.gen_expr(&from)?,
                to = self.gen_expr(&to)?,
                step = self.gen_expr(&step)?,
            )
        } else {
            let step = match var_type {
                VarType::Int => Expr::Literal(Literal::Int(1)),
                VarType::Float => Expr::Literal(Literal::Float(1.0)),
                VarType::Vec => Expr::Call("vec".into(), vec![Expr::Literal(Literal::Float(1.0))]),
                _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
            };
            self.inference.borrow().scope.add(var, var_type);

            s = format!(
                "for ({var_type} {var} = {from}; {var}<={to}; {var} += {step}) {{\n",
                var_type = match var_type {
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float<3>",
                    _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
                },
                var = var,
                from = self.gen_expr(&from)?,
                to = self.gen_expr(&to)?,
                step = self.gen_expr(&step)?,
            )
        }

        for v in body {
            s.push_str(&self.gen_stmt(v)?);
        }

        s.push_str("}\n");
        self.inference.borrow().scope.close();

        Ok(s)
    }

    fn gen_if_else(&'a self, cond_list: &[Cond], else_body: &[Stmt]) -> Result<String, String> {
        // cond_list should have 1 or more entries

        let Cond { ref cond, ref body } = cond_list[0];

        let mut s = format!("if ({}) {{\n", self.gen_expr(cond)?);
        assert!(self.inference.borrow().var_type(cond)? == VarType::Bool); // type info available only after generation!

        self.inference.borrow().scope.open();
        for v in body {
            s.push_str(&self.gen_stmt(v)?);
        }
        self.inference.borrow().scope.close();

        for cond_item in cond_list.iter().skip(1) {
            let Cond { ref cond, ref body } = cond_item;

            s.push_str(&format!("}} else if ({}) {{\n", self.gen_expr(cond)?));
            assert!(self.inference.borrow().var_type(cond)? == VarType::Bool); // type info available only after generation!

            self.inference.borrow().scope.open();
            for v in body {
                s.push_str(&self.gen_stmt(v)?);
            }
            self.inference.borrow().scope.close();
        }

        if !else_body.is_empty() {
            s.push_str("} else {\n");
            self.inference.borrow().scope.open();
            for v in else_body {
                s.push_str(&self.gen_stmt(v)?);
            }
            self.inference.borrow().scope.close();
        }
        s.push_str("}\n");

        Ok(s)
    }

    fn gen_while(&'a self, cond: &Expr, body: &[Stmt]) -> Result<String, String> {
        assert!(self.inference.borrow().var_type(cond)? == VarType::Bool);

        let mut s = format!("while ({}) {{\n", self.gen_expr(cond)?);

        self.inference.borrow().scope.open();
        for v in body {
            s.push_str(&self.gen_stmt(v)?);
        }
        self.inference.borrow().scope.close();
        s.push_str("}}\n");

        Ok(s)
    }

    fn gen_var(&'a self, id: &str, expr: &Expr) -> Result<String, String> {
        let no_init = String::new();
        let expr_str = match expr {
            Expr::Call(f, _) => match f.as_ref() {
                "array" => no_init,
                "bool_array" => no_init,
                "int_array" => no_init,
                "float_array" => no_init,
                "vec_array" => no_init,
                "local_array" => no_init,
                "local_bool_array" => no_init,
                "local_int_array" => no_init,
                "local_float_array" => no_init,
                "local_vec_array" => no_init,
                "zero" => "0".into(),
                "one" => "1".into(),
                _ => self.gen_expr(&expr)?,
            },
            Expr::Array(_) => format!(" = {}", self.gen_expr(&expr)?),
            _ => self.gen_expr(&expr)?,
        };

        let var_type = self.inference.borrow().var_type(expr)?;
        self.inference.borrow().scope.add(id, var_type);

        let s = match var_type {
            VarType::Bool => format!("bool {} = {};\n", id, expr_str),
            VarType::Int => format!("int {} = {};\n", id, expr_str),
            VarType::Float => format!("float {} = {};\n", id, expr_str),
            VarType::Vec => format!("float<3> {} = {};\n", id, expr_str),

            VarType::BoolArray(n, l, a, b, c, d) => {
                format!(
                    "{}bool {} {}{};\n",
                    if l { "local " } else { "" },
                    id,
                    idx4(n, a, b, c, d)?,
                    expr_str
                )
            }
            VarType::IntArray(n, l, a, b, c, d) => {
                format!(
                    "{}int {} {}{};\n",
                    if l { "local " } else { "" },
                    id,
                    idx4(n, a, b, c, d)?,
                    expr_str
                )
            }
            VarType::FloatArray(n, l, a, b, c, d) => {
                format!(
                    "{}float {} {}{};\n",
                    if l { "local " } else { "" },
                    id,
                    idx4(n, a, b, c, d)?,
                    expr_str
                )
            }
            VarType::VecArray(n, l, a, b, c, d) => {
                format!(
                    "{}float<3> {} {}{};\n",
                    if l { "local " } else { "" },
                    id,
                    idx4(n, a, b, c, d)?,
                    expr_str
                )
            }

            t => {
                return Err(format!(
                "Unable to create variable '{}' of type '{}'.\nType inferred from expression:\n{}",
                id, t, expr_str
            ))
            }
        };

        Ok(s)
    }

    fn gen_expr(&'a self, expr: &Expr) -> Result<String, String> {
        let s = match expr {
            Expr::Literal(Literal::Bool(true)) => "true".into(),
            Expr::Literal(Literal::Bool(false)) => "false".into(),
            Expr::Literal(Literal::Int(n)) => format!("{}", n),
            Expr::Literal(Literal::Float(n)) => format!("{:.7}f", n),
            Expr::Unary(expr) => self.gen_unary(expr)?,
            Expr::Binary(expr) => self.gen_binary(expr)?,
            Expr::Identifier(id) => id.clone(),
            Expr::Index(expr, idx) => self.gen_index(expr, idx)?,
            Expr::Grouping(expr) => format!("({})", self.gen_expr(expr)?),
            Expr::Call(id, args) => {
                if args.len() == 1 {
                    match (id.as_ref(), &args[0]) {
                        ("get_global_id", Expr::Literal(Literal::Int(0))) => return Ok("_x".into()),
                        ("get_global_id", Expr::Literal(Literal::Int(1))) => return Ok("_y".into()),
                        ("get_global_id", Expr::Literal(Literal::Int(2))) => return Ok("_z".into()),
                        _ => {}
                    }
                }

                let args_str = args
                    .iter()
                    .map(|e| self.gen_expr(e))
                    .collect::<Result<Vec<_>, _>>()?;
                let vars = args
                    .iter()
                    .map(|e| self.inference.borrow().var_type(e))
                    .collect::<Result<Vec<_>, _>>()?;
                if self.inference.borrow().builtin(id, args).is_ok() {
                    self.gen_call(id, &args_str, &vars)?
                } else {
                    let id = self.function(id, &vars)?;
                    self.dependencies
                        .borrow_mut()
                        .last_mut()
                        .ok_or_else(|| "No dependency frame found!".to_string())?
                        .insert(id.clone());
                    let mut args_str = args_str;
                    args_str.insert(0, "_x, _y, _z".into());
                    self.gen_call(&id, &args_str, &vars)?
                }
            }
            Expr::Array(elems) => {
                let mut s = String::new();
                for (k, v) in elems.iter().enumerate() {
                    s.push_str(&self.gen_expr(v)?);
                    if k < elems.len() - 1 {
                        s.push_str(", ");
                    }
                }
                format!("{{{}}}", s)
            }
        };

        Ok(s)
    }

    fn gen_unary(&'a self, expr: &UnaryExpr) -> Result<String, String> {
        let s = match expr.op {
            UnaryOp::Not => format!("!{}", self.gen_expr(&expr.right)?),
            UnaryOp::Neg => format!("(-{})", self.gen_expr(&expr.right)?),
        };

        Ok(s)
    }

    fn gen_binary(&'a self, expr: &BinaryExpr) -> Result<String, String> {
        let s = match expr.op {
            BinaryOp::And => format!(
                "{} && {}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Or => format!(
                "{} || {}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),

            BinaryOp::Sub => format!(
                "{} - {}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Add => format!(
                "{} + {}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Div => {
                if self.inference.borrow().var_type(&expr.left)? == VarType::Int {
                    format!(
                        "((float){})/{}",
                        self.gen_expr(&expr.left)?,
                        self.gen_expr(&expr.right)?,
                    )
                } else {
                    format!(
                        "{}/{}",
                        self.gen_expr(&expr.left)?,
                        self.gen_expr(&expr.right)?,
                    )
                }
            }
            BinaryOp::Mul => format!(
                "{}*{}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Mod => format!(
                "{}%{}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Pow => {
                let call = if self.inference.borrow().var_type(&expr.right)? == VarType::Int {
                    "pown"
                } else {
                    "pow"
                };

                if self.inference.borrow().var_type(&expr.left)? == VarType::Int {
                    format!(
                        "{}((float)({}), {})",
                        call,
                        self.gen_expr(&expr.left)?,
                        self.gen_expr(&expr.right)?
                    )
                } else {
                    format!(
                        "{}({}, {})",
                        call,
                        self.gen_expr(&expr.left)?,
                        self.gen_expr(&expr.right)?
                    )
                }
            }

            BinaryOp::Equal => format!(
                "{}=={}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::NotEqual => format!(
                "{}!={}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),

            BinaryOp::Less => format!(
                "{}<{}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::LessEqual => format!(
                "{}<={}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::Greater => format!(
                "{}>{}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
            BinaryOp::GreaterEqual => format!(
                "{}>={}",
                self.gen_expr(&expr.left)?,
                self.gen_expr(&expr.right)?
            ),
        };

        Ok(s)
    }

    fn gen_call(&'a self, id: &str, args: &[String], vars: &[VarType]) -> Result<String, String> {
        let mut id = match id {
            "bool" => "(bool)",
            "int" => "(int)",
            "float" => "(float)",
            "vec" => "vec",
            "mod" => "fmod",
            _ => id,
        };

        if !vars.is_empty() {
            id = match (id, vars[0]) {
                ("abs", VarType::Float) => "fabs",
                ("abs", VarType::Vec) => "fabs",
                ("atomic_add", VarType::FloatArray(1, false, ..)) => "_atomic_float_add",
                ("atomic_sub", VarType::FloatArray(1, false, ..)) => "_atomic_float_sub",
                ("atomic_inc", VarType::FloatArray(1, false, ..)) => "_atomic_float_inc",
                ("atomic_dec", VarType::FloatArray(1, false, ..)) => "_atomic_float_dec",
                ("atomic_min", VarType::FloatArray(1, false, ..)) => "_atomic_float_min",
                ("atomic_max", VarType::FloatArray(1, false, ..)) => "_atomic_float_max",
                ("atomic_add", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_add",
                ("atomic_sub", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_sub",
                ("atomic_inc", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_inc",
                ("atomic_dec", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_dec",
                ("atomic_min", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_min",
                ("atomic_max", VarType::FloatArray(1, true, ..)) => "_atomic_local_float_max",
                _ => id,
            }
        }

        let mut s = String::new();
        for (k, v) in args.iter().enumerate() {
            s.push_str(&v);
            if let VarType::Buffer { .. } = vars[k] {
                s.push_str(", ___str_");
                s.push_str(&v);
            }

            if k < args.len() - 1 {
                s.push_str(", ");
            }
        }

        Ok(format!("{}({})", id, s))
    }

    fn gen_assign(&'a self, expr: &Expr, val: &Expr) -> Result<String, String> {
        let s = if let Expr::Index(expr, idx) = expr {
            if let Index::ColorSpace(cs_from) = &**idx {
                // assign vec with color space conversion
                if let Expr::Index(id, idx) = &**expr {
                    if let Expr::Identifier(name) = &**id {
                        if let Index::Array2D(a, b) = &**idx {
                            let var = self.inference.borrow().var_type(id)?;
                            if let VarType::Buffer { z, cs, x1y1 } = var {
                                let cs = format!("{}to{}", cs_from, cs);
                                let a = self.gen_expr(a)?;
                                let b = self.gen_expr(b)?;
                                let guard = if x1y1 {
                                    format!("if ({}==0 && {}==0) ", a, b,)
                                } else {
                                    format!(
                                        "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                        a, a, name, b, b, name
                                    )
                                };
                                let val = self.gen_expr(val)?;
                                if z == 3 {
                                    let id_x = format!(
                                        "{}[(varying int)({})]",
                                        name,
                                        var.idx_3d(name, &a, &b, "0")
                                    );
                                    let id_y = format!(
                                        "{}[(varying int)({})]",
                                        name,
                                        var.idx_3d(name, &a, &b, "1")
                                    );
                                    let id_z = format!(
                                        "{}[(varying int)({})]",
                                        name,
                                        var.idx_3d(name, &a, &b, "2")
                                    );
                                    format!("{} {{ float<3> __v = {}({}); {} = __v.x; {} = __v.y; {} = __v.z; }}\n",
                                        guard, cs, val, id_x, id_y, id_z)
                                } else if z == 1 {
                                    // match buffer storage size to color space
                                    let id = format!(
                                        "{}[(varying int)({})]",
                                        name,
                                        var.idx_3d(name, &a, &b, "0")
                                    );
                                    format!("{} {} = {}({});\n", guard, id, cs, val)
                                } else {
                                    return Err(format!(
                                        "Expected buffer '{}' to have z==1 or z==3, found z=={}",
                                        name, z
                                    ));
                                }
                            } else {
                                return Err(format!("Expected variable '{}' to be a buffer for color space property access, found '{}'", name, var));
                            }
                        } else {
                            return Err(format!("Expected 2D index for color space property access on buffer '{}', found '{:?}'", name,  idx));
                        }
                    } else {
                        return Err(format!("Expected buffer identifier for color space property access, found '{:?}'", expr));
                    }
                } else {
                    return Err(format!(
                        "Expected element index for color space property asccess, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array1D(a) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(1, ..)
                        | VarType::IntArray(1, ..)
                        | VarType::FloatArray(1, ..)
                        | VarType::VecArray(1, ..) => {
                            format!(
                                "{}[{}] = {};\n",
                                name,
                                self.gen_expr(a)?,
                                self.gen_expr(val)?
                            )
                        }
                        VarType::Buffer { x1y1, .. } => {
                            let a = self.gen_expr(a)?;
                            let val = self.gen_expr(val)?;
                            let guard = if x1y1 {
                                format!("if ({}>=0 && {}<___str_{}[2]) ", a, a, name,)
                            } else {
                                format!("if ({}>=0 && {}<(___str_{}[0] * ___str_{}[1] * ___str_{}[2])) ",
                                a, a, name, name, name)
                            };
                            let id = format!("{}[(varying int)({})]", name, var.idx_1d(name, &a));
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array2D(a, b) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::Buffer { z: 1, x1y1, .. } => {
                            let a = self.gen_expr(a)?;
                            let b = self.gen_expr(b)?;
                            let guard = if x1y1 {
                                format!("if ({}==0 && {}==0) ", a, b,)
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                    a, a, name, b, b, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id = format!(
                                "{}[(varying int)({})]",
                                name,
                                var.idx_3d(name, &a, &b, "0")
                            );
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        VarType::Buffer { z: 3, x1y1, .. } => {
                            let a = self.gen_expr(a)?;
                            let b = self.gen_expr(b)?;
                            let guard = if x1y1 {
                                format!("if ({}==0 && {}==0) ", a, b,)
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                    a, a, name, b, b, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id_x = format!(
                                "{}[(varying int)({})]",
                                name,
                                var.idx_3d(name, &a, &b, "0")
                            );
                            let id_y = format!(
                                "{}[(varying int)({})]",
                                name,
                                var.idx_3d(name, &a, &b, "1")
                            );
                            let id_z = format!(
                                "{}[(varying int)({})]",
                                name,
                                var.idx_3d(name, &a, &b, "2")
                            );
                            format!(
                                "{} {{ float<3> __v = {}; {} = __v.x; {} = __v.y; {} = __v.z; }}\n",
                                guard, val, id_x, id_y, id_z
                            )
                        }
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => format!(
                            "{}[{}][{}] = {};\n",
                            name,
                            self.gen_expr(a)?,
                            self.gen_expr(b)?,
                            self.gen_expr(val)?
                        ),
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array3D(a, b, c) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(a)?,
                            self.gen_expr(b)?,
                            self.gen_expr(c)?,
                            self.gen_expr(val)?
                        ),
                        VarType::Buffer { x1y1, .. } => {
                            let a = self.gen_expr(a)?;
                            let b = self.gen_expr(b)?;
                            let c = self.gen_expr(c)?;
                            let guard = if x1y1 {
                                format!(
                                    "if ({}==0 && {}==0 && {}>=0 && {}<___str_{}[2]) ",
                                    a, b, c, c, name
                                )
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1] && {}>=0 && {}<___str_{}[2]) ",
                                    a, a, name, b, b, name, c, c, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id = format!(
                                "{}[(varying int)({})]",
                                name,
                                var.idx_3d(name, &a, &b, &c)
                            );
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array4D(a, b, c, d) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(a)?,
                            self.gen_expr(b)?,
                            self.gen_expr(c)?,
                            self.gen_expr(d)?,
                            self.gen_expr(val)?
                        ),
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else {
                let id = self.gen_index(expr, idx)?;
                format!("{} = {};\n", id, self.gen_expr(val)?)
            }
        } else {
            format!("{} = {};\n", self.gen_expr(expr)?, self.gen_expr(val)?)
        };

        Ok(s)
    }

    fn gen_index(&'a self, expr: &Expr, idx: &Index) -> Result<String, String> {
        // recursively unwrap nested indices to find name
        let name;
        let mut name_expr = expr;
        loop {
            match name_expr {
                Expr::Index(expr, _) => {
                    name_expr = &**expr;
                }
                Expr::Identifier(n) => {
                    name = n;
                    break;
                }
                expr => {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ))
                }
            }
        }

        let s = match idx {
            Index::Vec(0) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.x", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[0]", name),
                    t => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, t
                        ))
                    }
                }
            }
            Index::Vec(1) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.y", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[1]", name),
                    t => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, t
                        ))
                    }
                }
            }
            Index::Vec(2) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.z", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[2]", name),
                    t => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, t
                        ))
                    }
                }
            }
            Index::Array1D(a) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_1d(id, &self.gen_expr(a)?),
                        VarType::BoolArray(1, ..)
                        | VarType::IntArray(1, ..)
                        | VarType::FloatArray(1, ..)
                        | VarType::VecArray(1, ..) => format!("{}[{}]", id, self.gen_expr(a)?),
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            }
            Index::Array2D(a, b) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { z: 1, .. } => {
                            var.buf_idx_3d(id, &self.gen_expr(a)?, &self.gen_expr(b)?, "0")
                        }
                        VarType::Buffer { z: 3, .. } => format!(
                            "vec{}",
                            var.buf_idx_2d(id, &self.gen_expr(a)?, &self.gen_expr(b)?)
                        ),
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => {
                            format!("{}[{}][{}]", id, self.gen_expr(a)?, self.gen_expr(b)?)
                        }
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            }
            Index::Array3D(a, b, c) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_3d(
                            id,
                            &self.gen_expr(a)?,
                            &self.gen_expr(b)?,
                            &self.gen_expr(c)?,
                        ),
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}]",
                            id,
                            self.gen_expr(a)?,
                            self.gen_expr(b)?,
                            self.gen_expr(c)?,
                        ),
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            }
            Index::Array4D(a, b, c, d) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}]",
                            id,
                            self.gen_expr(a)?,
                            self.gen_expr(b)?,
                            self.gen_expr(c)?,
                            self.gen_expr(d)?,
                        ),
                        t => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, t
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            }
            Index::ColorSpace(cs_to) => {
                if let Expr::Index(expr, idx) = expr {
                    if let Expr::Identifier(id) = &**expr {
                        let var = self.inference.borrow().var_type(expr)?;
                        if let VarType::Buffer { z, cs, .. } = var {
                            let id = if let Index::Array2D(a, b) = &**idx {
                                if z == 1 {
                                    var.buf_idx_3d(id, &self.gen_expr(a)?, &self.gen_expr(b)?, "0")
                                } else if z == 3 {
                                    format!(
                                        "vec{}",
                                        var.buf_idx_2d(id, &self.gen_expr(a)?, &self.gen_expr(b)?)
                                    )
                                } else {
                                    return Err(format!(
                                        "Expected buffer '{}' to have z==1 or z==3, found z=={}",
                                        name, z
                                    ));
                                }
                            } else {
                                return Err(format!("Expected 2D index for color space property access on buffer '{}', found '{:?}'", name,  idx));
                            };
                            format!("{}to{}({})", cs, cs_to, id)
                        } else {
                            return Err(format!("Expected 2D index for color space property access on buffer '{}', found '{:?}'", name,  idx));
                        }
                    } else {
                        return Err(format!("Expected buffer identifier for color space property access, found '{:?}'", expr));
                    }
                } else {
                    return Err(format!(
                        "Expected element index for color space property asccess, found '{:?}'",
                        expr
                    ));
                }
            }

            Index::Prop(prop) => {
                if let Expr::Index(expr, idx) = expr {
                    if let Expr::Identifier(id) = &**expr {
                        let var = self.inference.borrow().var_type(expr)?;
                        let idx = &**idx;
                        match var {
                            VarType::Buffer { .. } => {
                                let idx = match (var, idx) {
                                    (VarType::Buffer { .. }, Index::Array1D(a)) => {
                                        var.idx_1d(id, &self.gen_expr(a)?)
                                    }
                                    (VarType::Buffer { z: 1, .. }, Index::Array2D(a, b)) => {
                                        var.idx_3d(id, &self.gen_expr(a)?, &self.gen_expr(b)?, "0")
                                    }
                                    (VarType::Buffer { .. }, Index::Array3D(a, b, c)) => var
                                        .idx_3d(
                                            id,
                                            &self.gen_expr(a)?,
                                            &self.gen_expr(b)?,
                                            &self.gen_expr(c)?,
                                        ),
                                    (t, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, t)),
                                };
                                match prop {
                                    Prop::Int => format!("(((uniform int*){})[{}])", id, idx), //only for buffers
                                    Prop::Idx => idx,
                                    Prop::Ptr => format!("({} + {})", id, idx),
                                    Prop::IntPtr => format!("(((uniform int*){}) + {})", id, idx), // only for buffers
                                }
                            }
                            VarType::FloatArray(..) => {
                                if let Prop::Ptr = prop {
                                    match (var, idx) {
                                        (VarType::FloatArray(1, ..), Index::Array1D(a)) => {
                                            format!("({} + {})", id, self.gen_expr(a)?)
                                        }
                                        (VarType::FloatArray(2, ..), Index::Array2D(a, b)) => {
                                            format!(
                                                "({}[{}] + {})",
                                                id,
                                                self.gen_expr(a)?,
                                                self.gen_expr(b)?
                                            )
                                        }
                                        (VarType::FloatArray(3, ..), Index::Array3D(a, b, c)) => {
                                            format!(
                                                "({}[{}][{}] + {})",
                                                id,
                                                self.gen_expr(a)?,
                                                self.gen_expr(b)?,
                                                self.gen_expr(c)?
                                            )
                                        }
                                        (
                                            VarType::FloatArray(4, ..),
                                            Index::Array4D(a, b, c, d),
                                        ) => format!(
                                            "({}[{}][{}][{}] + {})",
                                            id,
                                            self.gen_expr(a)?,
                                            self.gen_expr(b)?,
                                            self.gen_expr(c)?,
                                            self.gen_expr(d)?
                                        ),
                                        (t, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, t)),
                                    }
                                } else {
                                    return Err(format!("Array '{}' does not support property access except for '.ptr'", name));
                                }
                            }
                            VarType::IntArray(..) => {
                                if let Prop::Ptr = prop {
                                    match (var, idx) {
                                        (VarType::IntArray(1, ..), Index::Array1D(a)) => {
                                            format!("({} + {})", id, self.gen_expr(a)?)
                                        }
                                        (VarType::IntArray(2, ..), Index::Array2D(a, b)) => {
                                            format!(
                                                "({}[{}] + {})",
                                                id,
                                                self.gen_expr(a)?,
                                                self.gen_expr(b)?
                                            )
                                        }
                                        (VarType::IntArray(3, ..), Index::Array3D(a, b, c)) => {
                                            format!(
                                                "({}[{}][{}] + {})",
                                                id,
                                                self.gen_expr(a)?,
                                                self.gen_expr(b)?,
                                                self.gen_expr(c)?
                                            )
                                        }
                                        (VarType::IntArray(4, ..), Index::Array4D(a, b, c, d)) => {
                                            format!(
                                                "({}[{}][{}][{}] + {})",
                                                id,
                                                self.gen_expr(a)?,
                                                self.gen_expr(b)?,
                                                self.gen_expr(c)?,
                                                self.gen_expr(d)?
                                            )
                                        }
                                        (t, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, t)),
                                    }
                                } else {
                                    return Err(format!("Array '{}' does not support property access except for '.ptr'", name));
                                }
                            }
                            t => {
                                return Err(format!(
                                    "Variable '{}' of type '{}' does not support property access",
                                    name, t
                                ))
                            }
                        }
                    } else {
                        return Err(format!(
                            "Expected buffer or array identifier for property access, found '{:?}'",
                            expr
                        ));
                    }
                } else {
                    return Err(format!(
                        "Expected element index for property asccess, found '{:?}'",
                        expr
                    ));
                }
            }
            i => {
                return Err(format!(
                    "Variable '{}' cannot be indexed with '{:?}'",
                    name, i
                ))
            }
        };

        Ok(s)
    }
}
