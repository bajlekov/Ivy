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

use crate::inference::{GenFunction, Inference, VarType, PRIVATE, LOCAL};

pub struct Generator<'a> {
    inference: RefCell<Inference<'a>>,
    constants: RefCell<HashMap<String, Expr>>,
    functions: RefCell<HashMap<String, Stmt>>,
    kernels: RefCell<HashMap<String, Stmt>>,
    generated_constants: RefCell<Option<String>>,
    generated_functions: RefCell<HashMap<String, GenFunction>>, // collect specialized functions: (declaration, definition, return value, dependencies)
    generated_kernels: RefCell<HashMap<String, String>>, // collect specialized kernels: (kernel)
    dependencies: RefCell<Vec<HashSet<String>>>, // collects dependencies of currently parsed function in a stack
}

// helper function for generating up to 4D array indices
fn idx4(dim: u8, i1: usize, i2: usize, i3: usize, i4: usize) -> Result<String, String> {
    Ok(match dim {
        1 => format!("[{}]", i1),
        2 => format!("[{}][{}]", i1, i2),
        3 => format!("[{}][{}][{}]", i1, i2, i3),
        4 => format!("[{}][{}][{}][{}]", i1, i2, i3, i4),
        dim => {
            return Err(format!(
                "Array dimensions must be between 1 and 4, found: {}",
                dim
            ))
        }
    })
}

impl<'a> Generator<'a> {
    //#[allow(clippy::ptr_arg)]
    pub fn new(ast: Vec<Stmt>) -> Generator<'a> {
        let mut constants = HashMap::new();
        let mut functions = HashMap::new();
        let mut kernels = HashMap::new();

        for stmt in ast {
            match stmt {
                Stmt::Const(ref id, expr) => {
                    constants.insert(id.clone(), expr);
                }
                Stmt::Function { ref id, .. } => {
                    functions.insert(id.clone(), stmt);
                }
                Stmt::Kernel { ref id, .. } => {
                    kernels.insert(id.clone(), stmt);
                }
                Stmt::Comment(..) | Stmt::Eof => {}
                _ => panic!("Unexpected statement in file scope!"),
            }
        }

        Generator {
            inference: RefCell::new(Inference::new()),
            constants: RefCell::new(constants),
            functions: RefCell::new(functions),
            kernels: RefCell::new(kernels),
            generated_constants: RefCell::new(None),
            generated_functions: RefCell::new(HashMap::new()),
            generated_kernels: RefCell::new(HashMap::new()),
            dependencies: RefCell::new(Vec::new()),
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

            let mut definition = "(\n".to_string();
            let mut declaration;

            // generate argument signatures
            for (idx, arg) in args.iter().enumerate() {
                let arg_type = match input[idx] {
                    VarType::Buffer { .. } => {
                        format!("global float *{}, global int *___str_{}", arg, arg)
                    }
                    VarType::Int => format!("int {}", arg),
                    VarType::Float => format!("float {}", arg),
                    VarType::Vec => format!("float3 {}", arg),
                    VarType::BoolArray(dim, address, i1, i2, i3, i4) => {
                        format!(
                            "{}bool {}{}",
                            if address==LOCAL { "local " } else { "" },
                            arg,
                            idx4(dim, i1, i2, i3, i4)?
                        )
                    }
                    VarType::IntArray(dim, address, i1, i2, i3, i4) => {
                        format!(
                            "{}int {}{}",
                            if address==LOCAL { "local " } else { "" },
                            arg,
                            idx4(dim, i1, i2, i3, i4)?
                        )
                    }
                    VarType::FloatArray(dim, address, i1, i2, i3, i4) => {
                        format!(
                            "{}float {}{}",
                            if address==LOCAL { "local " } else { "" },
                            arg,
                            idx4(dim, i1, i2, i3, i4)?
                        )
                    }
                    VarType::VecArray(dim, address, i1, i2, i3, i4) => {
                        format!(
                            "{}float3 {}{}",
                            if address==LOCAL { "local " } else { "" },
                            arg,
                            idx4(dim, i1, i2, i3, i4)?
                        )
                    }
                    err_type => {
                        return Err(format!(
                            "Argument '{}' of function '{}' has unsupported type '{}'",
                            arg, name, err_type
                        ))
                    }
                };

                self.inference.borrow().scope.add(arg, input[idx]); // add argument to scope

                // comma-separate arguments
                if idx < args.len() - 1 {
                    definition.push_str(&format!("\t{},\n", arg_type));
                } else {
                    definition.push_str(&format!("\t{}\n", arg_type));
                }
            }
            definition.push(')');

            declaration = definition.clone(); // copy function signature into declaration

            // construct function body
            definition.push_str(" {\n");
            for stmt in body {
                definition.push_str(&self.gen_stmt(stmt)?);
            }

            // get function return type
            let return_type = self
                .inference
                .borrow()
                .scope
                .get("return")
                .unwrap_or(VarType::Void); // use void return type if none specified
            let return_string = match return_type {
                VarType::Bool => "bool",
                VarType::Int => "int",
                VarType::Float => "float",
                VarType::Vec => "float3",
                VarType::Void => "void",
                _ => return Err(format!("Unknown return type of function '{}'", name)),
            };
            self.inference.borrow().scope.close();
            self.inference.borrow().scope.set_current(outer_scope);

            // collect function dependencies from stack
            let dependencies = self
                .dependencies
                .borrow_mut()
                .pop()
                .ok_or_else(|| "No dependency frame found!".to_string())?;

            // add function return type to definition
            definition = format!("{} {} {}}}", return_string, id, definition);

            // add function return type to declaration
            declaration = format!("{} {} {};", return_string, id, declaration);

            // register generated_functions
            self.generated_functions.borrow_mut().insert(
                id.clone(),
                GenFunction {
                    declaration,
                    definition,
                    return_type,
                    dependencies,
                },
            );

            Ok(id)
        } else {
            Err(format!("Function '{}' not found", id))
        }
    }

    pub fn kernel(&'a self, name: &str, input: &[VarType]) -> Result<String, String> {
        let id = function_id(name, input);

        if let Some(kernel) = self.generated_kernels.borrow().get(&id) {
            return Ok(kernel.clone());
        }

        self.inference.borrow_mut().functions = Some(&self.generated_functions); // link generated functions to inference engine
        self.inference.borrow().scope.clear(); // clear leftover scopes
        *self.dependencies.borrow_mut() = vec![]; // clear the dependency stack

        // parse constants
        if self.generated_constants.borrow().is_none() {
            let mut consts = String::new();
            for (name, expr) in self.constants.borrow().iter() {
                consts.push_str(&format!("constant {}", self.gen_var(name, expr)?));
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
            let mut kernel = format!("kernel void {} (\n", id);
            for (idx, arg) in args.iter().enumerate() {
                // construct argument signature
                let arg_out = format!(
                    "{}{}",
                    match input[idx] {
                        VarType::Buffer { .. } =>
                            format!("global float *{}, global int *___str_", arg),
                        VarType::Int => "int ".into(),
                        VarType::Float => "float ".into(),
                        VarType::IntArray(1, ..) => "int *".into(),
                        VarType::FloatArray(1, ..) => "float *".into(),
                        err_type =>
                            return Err(format!(
                                "Type '{}' of argument '{}' not supported in kernel arguments",
                                err_type, arg
                            )),
                    },
                    arg
                );

                self.inference.borrow().scope.add(arg, input[idx]); // add argument to scope

                // comma-separate arguments
                if idx < args.len() - 1 {
                    kernel.push_str(&format!("\t{},\n", arg_out));
                } else {
                    kernel.push_str(&format!("\t{}\n", arg_out));
                }
            }
            kernel.push_str(") {\n");
            // construct kernel body
            for stmt in body {
                kernel.push_str(&self.gen_stmt(stmt)?);
            }
            kernel.push('}');

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
                "#include \"std.cl\"\n{}\n{}\n{}\n{}",
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
            let dependencies_nested = self
                .generated_functions
                .borrow()
                .get(&id)
                .ok_or::<String>(format!("No function dependency '{}' found", &id))?
                .dependencies
                .clone();
            satisfied.insert(id);

            for id in dependencies_nested {
                if satisfied.get(&id).is_none() {
                    deps.push(id);
                }
            }
        }

        let deps = satisfied;

        let mut declarations = String::new();
        let mut definitions = String::new();
        for id in &deps {
            let function = self.generated_functions.borrow();
            let function = function
                .get(id)
                .ok_or::<String>(format!("No function dependency '{}' found", id))?;

            declarations.push_str(&function.declaration);
            declarations.push_str("\n\n");
            definitions.push_str(&function.definition);
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
                    .map(|expr| self.gen_expr(expr))
                    .collect::<Result<Vec<_>, _>>()?;
                let vars = args
                    .iter()
                    .map(|expr| self.inference.borrow().var_type(expr))
                    .collect::<Result<Vec<_>, _>>()?;
                if self.inference.borrow().builtin(id, args).is_ok() {
                    format!("{};\n", Generator::gen_call(id, &args_str, &vars))
                } else {
                    let id = self.function(id, &vars)?;
                    format!("{};\n", Generator::gen_call(&id, &args_str, &vars))
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
                Some(return_type) => {
                    return Err(format!(
                        "Void return statement inconsistent with previously used return type '{}'",
                        return_type
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
                let promoted = Inference::promote(new, old)?;

                self.inference.borrow().scope.overwrite("return", promoted);

                format!("return {};\n", expr_str)
            }
            Stmt::Comment(comment) => format!("//{}\n", comment),
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

        // infer var type
        // TODO: does code need to be generated before inference? e.g. function calls?
        let from_type = self.inference.borrow().var_type(from)?;
        let to_type = self.inference.borrow().var_type(to)?;

        let mut var_type = Inference::promote_num(from_type, to_type)?;

        let mut out = if let Some(step) = &step {
            let step_type = self.inference.borrow().var_type(step)?;
            var_type = Inference::promote_num(var_type, step_type)?;
            self.inference.borrow().scope.add(var, var_type);

            format!(
                "for ({var_type} {var} = {from}; ({step}>0)?({var}<={to}):({var}>={to}); {var} += {step}) {{\n",
                var_type = match var_type {
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float3",
                    _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
                },
                var = var,
                from = self.gen_expr(from)?,
                to = self.gen_expr(to)?,
                step = self.gen_expr(step)?,
            )
        } else {
            let step = match var_type {
                VarType::Int => Expr::Literal(Literal::Int(1)),
                VarType::Float => Expr::Literal(Literal::Float(1.0)),
                VarType::Vec => Expr::Call("vec".into(), vec![Expr::Literal(Literal::Float(1.0))]),
                _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
            };
            self.inference.borrow().scope.add(var, var_type);

            format!(
                "for ({var_type} {var} = {from}; {var}<={to}; {var} += {step}) {{\n",
                var_type = match var_type {
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float3",
                    _ => return Err(format!("Incompatible loop variable type '{}'", var_type)),
                },
                var = var,
                from = self.gen_expr(from)?,
                to = self.gen_expr(to)?,
                step = self.gen_expr(&step)?,
            )
        };

        for stmt in body {
            out.push_str(&self.gen_stmt(stmt)?);
        }

        out.push_str("}\n");
        self.inference.borrow().scope.close();

        Ok(out)
    }

    fn gen_if_else(&'a self, cond_list: &[Cond], else_body: &[Stmt]) -> Result<String, String> {
        // cond_list should have 1 or more entries

        let Cond { ref cond, ref body } = cond_list[0];

        let mut out = format!("if ({}) {{\n", self.gen_expr(cond)?);
        assert!(self.inference.borrow().var_type(cond)? == VarType::Bool); // type info available only after generation!

        self.inference.borrow().scope.open();
        for stmt in body {
            out.push_str(&self.gen_stmt(stmt)?);
        }
        self.inference.borrow().scope.close();

        for cond_item in cond_list.iter().skip(1) {
            let Cond { ref cond, ref body } = cond_item;

            out.push_str(&format!("}} else if ({}) {{\n", self.gen_expr(cond)?));
            assert!(self.inference.borrow().var_type(cond)? == VarType::Bool); // type info available only after generation!

            self.inference.borrow().scope.open();
            for stmt in body {
                out.push_str(&self.gen_stmt(stmt)?);
            }
            self.inference.borrow().scope.close();
        }

        if !else_body.is_empty() {
            out.push_str("} else {\n");
            self.inference.borrow().scope.open();
            for stmt in else_body {
                out.push_str(&self.gen_stmt(stmt)?);
            }
            self.inference.borrow().scope.close();
        }
        out.push_str("}\n");

        Ok(out)
    }

    fn gen_while(&'a self, cond: &Expr, body: &[Stmt]) -> Result<String, String> {
        assert!(self.inference.borrow().var_type(cond)? == VarType::Bool);

        let mut out = format!("while ({}) {{\n", self.gen_expr(cond)?);

        self.inference.borrow().scope.open();
        for stmt in body {
            out.push_str(&self.gen_stmt(stmt)?);
        }
        self.inference.borrow().scope.close();
        out.push_str("}}\n");

        Ok(out)
    }

    fn gen_var(&'a self, id: &str, expr: &Expr) -> Result<String, String> {
        let no_init = String::new();
        let expr_str = match expr {
            Expr::Call(name, _) => match name.as_ref() {
                "array" | "bool_array" | "int_array" | "float_array" | "vec_array"
                | "local_array" | "local_bool_array" | "local_int_array" | "local_float_array"
                | "local_vec_array" => no_init,
                "zero" => "0".into(),
                "one" => "1".into(),
                _ => self.gen_expr(expr)?,
            },
            Expr::Array(_) => format!(" = {}", self.gen_expr(expr)?),
            _ => self.gen_expr(expr)?,
        };

        let var_type = self.inference.borrow().var_type(expr)?;
        self.inference.borrow().scope.add(id, var_type);

        let out = match var_type {
            VarType::Bool => format!("bool {} = {};\n", id, expr_str),
            VarType::Int => format!("int {} = {};\n", id, expr_str),
            VarType::Float => format!("float {} = {};\n", id, expr_str),
            VarType::Vec => format!("float3 {} = {};\n", id, expr_str),

            VarType::BoolArray(dim, address, i1, i2, i3, i4) => {
                format!(
                    "{}bool {} {}{};\n",
                    if address==LOCAL { "local " } else { "" },
                    id,
                    idx4(dim, i1, i2, i3, i4)?,
                    expr_str
                )
            }
            VarType::IntArray(dim, address, i1, i2, i3, i4) => {
                format!(
                    "{}int {} {}{};\n",
                    if address==LOCAL { "local " } else { "" },
                    id,
                    idx4(dim, i1, i2, i3, i4)?,
                    expr_str
                )
            }
            VarType::FloatArray(dim, address, i1, i2, i3, i4) => {
                format!(
                    "{}float {} {}{};\n",
                    if address==LOCAL { "local " } else { "" },
                    id,
                    idx4(dim, i1, i2, i3, i4)?,
                    expr_str
                )
            }
            VarType::VecArray(dim, address, i1, i2, i3, i4) => {
                format!(
                    "{}float3 {} {}{};\n",
                    if address==LOCAL { "local " } else { "" },
                    id,
                    idx4(dim, i1, i2, i3, i4)?,
                    expr_str
                )
            }

            err_type => {
                return Err(format!(
                "Unable to create variable '{}' of type '{}'.\nType inferred from expression:\n{}",
                id, err_type, expr_str
            ))
            }
        };

        Ok(out)
    }

    fn gen_expr(&'a self, expr: &Expr) -> Result<String, String> {
        let out = match expr {
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
                let args_str = args
                    .iter()
                    .map(|expr| self.gen_expr(expr))
                    .collect::<Result<Vec<_>, _>>()?;
                let vars = args
                    .iter()
                    .map(|expr| self.inference.borrow().var_type(expr))
                    .collect::<Result<Vec<_>, _>>()?;
                if self.inference.borrow().builtin(id, args).is_ok() {
                    Generator::gen_call(id, &args_str, &vars)
                } else {
                    let id = self.function(id, &vars)?;
                    self.dependencies
                        .borrow_mut()
                        .last_mut()
                        .ok_or_else(|| "No dependency frame found!".to_string())?
                        .insert(id.clone());
                    Generator::gen_call(&id, &args_str, &vars)
                }
            }
            Expr::Array(elems) => {
                let mut s = String::new();
                for (idx, expr) in elems.iter().enumerate() {
                    if idx > 0 {
                        s.push(',');
                    }
                    s.push_str(&self.gen_expr(expr)?);
                }
                format!("{{{}}}", s)
            }
        };

        Ok(out)
    }

    fn gen_unary(&'a self, expr: &UnaryExpr) -> Result<String, String> {
        let out = match expr.op {
            UnaryOp::Not => format!("!{}", self.gen_expr(&expr.right)?),
            UnaryOp::Neg => format!("(-{})", self.gen_expr(&expr.right)?),
        };

        Ok(out)
    }

    fn gen_binary(&'a self, expr: &BinaryExpr) -> Result<String, String> {
        let out = match expr.op {
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

        Ok(out)
    }

    fn gen_call(id: &str, args: &[String], vars: &[VarType]) -> String {
        let mut id = match id {
            "bool" => "(bool)",
            "int" => "(int)",
            "float" => "(float)",
            "vec" => "(float3)",
            "mod" => "fmod",
            _ => id,
        };

        if !vars.is_empty() {
            id = match (id, vars[0]) {
                ("abs", VarType::Vec | VarType::Float) => "fabs",
                ("atomic_add", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_add",
                ("atomic_sub", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_sub",
                ("atomic_inc", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_inc",
                ("atomic_dec", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_dec",
                ("atomic_min", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_min",
                ("atomic_max", VarType::FloatArray(1, PRIVATE, ..)) => "_atomic_float_max",
                ("atomic_add", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_add",
                ("atomic_sub", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_sub",
                ("atomic_inc", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_inc",
                ("atomic_dec", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_dec",
                ("atomic_min", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_min",
                ("atomic_max", VarType::FloatArray(1, LOCAL, ..)) => "_atomic_local_float_max",
                _ => id,
            }
        }

        let mut out = String::new();
        for (idx, arg) in args.iter().enumerate() {
            if idx > 0 {
                out.push(',');
            }
            out.push_str(arg);
            if let VarType::Buffer { .. } = vars[idx] {
                out.push_str(", ___str_");
                out.push_str(arg);
            }
        }

        format!("{}({})", id, out)
    }

    fn gen_assign(&'a self, expr: &Expr, val: &Expr) -> Result<String, String> {
        let out = if let Expr::Index(expr, idx) = expr {
            if let Index::ColorSpace(cs_from) = &**idx {
                // assign vec with color space conversion
                if let Expr::Index(id, idx) = &**expr {
                    if let Expr::Identifier(name) = &**id {
                        if let Index::Array2D(i1, i2) = &**idx {
                            let var = self.inference.borrow().var_type(id)?;
                            if let VarType::Buffer { z, cs, x1y1 } = var {
                                let cs = format!("{}to{}", cs_from, cs);
                                let i1 = self.gen_expr(i1)?;
                                let i2 = self.gen_expr(i2)?;
                                let guard = if x1y1 {
                                    format!("if ({}==0 && {}==0) ", i1, i2,)
                                } else {
                                    format!(
                                        "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                        i1, i1, name, i2, i2, name
                                    )
                                };
                                let val = self.gen_expr(val)?;
                                if z == 3 {
                                    let id_x = var.buf_idx_3d(name, &i1, &i2, "0");
                                    let id_y = var.buf_idx_3d(name, &i1, &i2, "1");
                                    let id_z = var.buf_idx_3d(name, &i1, &i2, "2");
                                    format!("{} {{ float3 __v = {}({}); {} = __v.x; {} = __v.y; {} = __v.z; }}\n",
                                        guard, cs, val, id_x, id_y, id_z)
                                } else if z == 1 {
                                    // match buffer storage size to color space
                                    let id = var.buf_idx_3d(name, &i1, &i2, "0");
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
            } else if let Index::Array1D(i1) = &**idx {
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
                                self.gen_expr(i1)?,
                                self.gen_expr(val)?
                            )
                        }
                        VarType::Buffer { x1y1, .. } => {
                            let i1 = self.gen_expr(i1)?;
                            let val = self.gen_expr(val)?;
                            let guard = if x1y1 {
                                format!("if ({}>=0 && {}<___str_{}[2]) ", i1, i1, name,)
                            } else {
                                format!("if ({}>=0 && {}<(___str_{}[0] * ___str_{}[1] * ___str_{}[2])) ",
                                i1, i1, name, name, name)
                            };
                            let id = var.buf_idx_1d(name, &i1);
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array2D(i1, i2) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::Buffer { z: 1, x1y1, .. } => {
                            let i1 = self.gen_expr(i1)?;
                            let i2 = self.gen_expr(i2)?;
                            let guard = if x1y1 {
                                format!("if ({}==0 && {}==0) ", i1, i2,)
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                    i1, i1, name, i2, i2, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id = var.buf_idx_3d(name, &i1, &i2, "0");
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        VarType::Buffer { z: 3, x1y1, .. } => {
                            let i1 = self.gen_expr(i1)?;
                            let i2 = self.gen_expr(i2)?;
                            let guard = if x1y1 {
                                format!("if ({}==0 && {}==0) ", i1, i2,)
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1]) ",
                                    i1, i1, name, i2, i2, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id_x = var.buf_idx_3d(name, &i1, &i2, "0");
                            let id_y = var.buf_idx_3d(name, &i1, &i2, "1");
                            let id_z = var.buf_idx_3d(name, &i1, &i2, "2");
                            format!(
                                "{} {{ float3 __v = {}; {} = __v.x; {} = __v.y; {} = __v.z; }}\n",
                                guard, val, id_x, id_y, id_z
                            )
                        }
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => format!(
                            "{}[{}][{}] = {};\n",
                            name,
                            self.gen_expr(i1)?,
                            self.gen_expr(i2)?,
                            self.gen_expr(val)?
                        ),
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array3D(i1, i2, i3) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(i1)?,
                            self.gen_expr(i2)?,
                            self.gen_expr(i3)?,
                            self.gen_expr(val)?
                        ),
                        VarType::Buffer { x1y1, .. } => {
                            let i1 = self.gen_expr(i1)?;
                            let i2 = self.gen_expr(i2)?;
                            let i3 = self.gen_expr(i3)?;
                            let guard = if x1y1 {
                                format!(
                                    "if ({}==0 && {}==0 && {}>=0 && {}<___str_{}[2]) ",
                                    i1, i2, i3, i3, name
                                )
                            } else {
                                format!(
                                    "if ({}>=0 && {}<___str_{}[0] && {}>=0 && {}<___str_{}[1] && {}>=0 && {}<___str_{}[2]) ",
                                    i1, i1, name, i2, i2, name, i3, i3, name
                                )
                            };
                            let val = self.gen_expr(val)?;

                            let id = var.buf_idx_3d(name, &i1, &i2, &i3);
                            format!("{} {} = {};\n", guard, id, val)
                        }
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
                            ))
                        }
                    }
                } else {
                    return Err(format!(
                        "Expected buffer or array identifier for indexed access, found '{:?}'",
                        expr
                    ));
                }
            } else if let Index::Array4D(i1, i2, i3, i4) = &**idx {
                let var = self.inference.borrow().var_type(expr)?;
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(i1)?,
                            self.gen_expr(i2)?,
                            self.gen_expr(i3)?,
                            self.gen_expr(i4)?,
                            self.gen_expr(val)?
                        ),
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
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

        Ok(out)
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

        let out = match idx {
            Index::Vec(0) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.x", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[0]", name),
                    err_type => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, err_type
                        ))
                    }
                }
            }
            Index::Vec(1) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.y", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[1]", name),
                    err_type => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, err_type
                        ))
                    }
                }
            }
            Index::Vec(2) => {
                let var = self.inference.borrow().var_type(expr)?;
                match var {
                    VarType::Vec => format!("{}.z", self.gen_expr(expr)?),
                    VarType::Buffer { .. } => format!("___str_{}[2]", name),
                    err_type => {
                        return Err(format!(
                            "Variable '{}' of type '{}' does not support property access",
                            name, err_type
                        ))
                    }
                }
            }
            Index::Array1D(i1) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_1d(id, &self.gen_expr(i1)?),
                        VarType::BoolArray(1, ..)
                        | VarType::IntArray(1, ..)
                        | VarType::FloatArray(1, ..)
                        | VarType::VecArray(1, ..) => format!("{}[{}]", id, self.gen_expr(i1)?),
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
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
            Index::Array2D(i1, i2) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { z: 1, .. } => {
                            var.buf_idx_3d(id, &self.gen_expr(i1)?, &self.gen_expr(i2)?, "0")
                        }
                        VarType::Buffer { z: 3, .. } => format!(
                            "(float3){}",
                            var.buf_idx_2d(id, &self.gen_expr(i1)?, &self.gen_expr(i2)?)
                        ),
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => {
                            format!("{}[{}][{}]", id, self.gen_expr(i1)?, self.gen_expr(i2)?)
                        }
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
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
            Index::Array3D(i1, i2, i3) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_3d(
                            id,
                            &self.gen_expr(i1)?,
                            &self.gen_expr(i2)?,
                            &self.gen_expr(i3)?,
                        ),
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}]",
                            id,
                            self.gen_expr(i1)?,
                            self.gen_expr(i2)?,
                            self.gen_expr(i3)?,
                        ),
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
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
            Index::Array4D(i1, i2, i3, i4) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr)?;
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}]",
                            id,
                            self.gen_expr(i1)?,
                            self.gen_expr(i2)?,
                            self.gen_expr(i3)?,
                            self.gen_expr(i4)?,
                        ),
                        err_type => {
                            return Err(format!(
                                "Unable to index variable '{}' of type '{}'",
                                name, err_type
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
                            let id = if let Index::Array2D(i1, i2) = &**idx {
                                if z == 1 {
                                    var.buf_idx_3d(
                                        id,
                                        &self.gen_expr(i1)?,
                                        &self.gen_expr(i2)?,
                                        "0",
                                    )
                                } else if z == 3 {
                                    format!(
                                        "(float3){}",
                                        var.buf_idx_2d(
                                            id,
                                            &self.gen_expr(i1)?,
                                            &self.gen_expr(i2)?
                                        )
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
                                    (VarType::Buffer { .. }, Index::Array1D(i1)) => {
                                        var.idx_1d(id, &self.gen_expr(i1)?)
                                    }
                                    (VarType::Buffer { z: 1, .. }, Index::Array2D(i1, i2)) => {
                                        var.idx_3d(id, &self.gen_expr(i1)?, &self.gen_expr(i2)?, "0")
                                    }
                                    (VarType::Buffer { .. }, Index::Array3D(i1, i2, i3)) => var
                                        .idx_3d(
                                            id,
                                            &self.gen_expr(i1)?,
                                            &self.gen_expr(i2)?,
                                            &self.gen_expr(i3)?,
                                        ),
                                    (err_type, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, err_type)),
                                };
                                match prop {
                                    Prop::Int => format!("(((global int*){})[{}])", id, idx), //only for buffers
                                    Prop::Idx => idx,
                                    Prop::Ptr => format!("({} + {})", id, idx),
                                    Prop::IntPtr => format!("(((global int*){}) + {})", id, idx), // only for buffers
                                }
                            }
                            VarType::FloatArray(..) => {
                                if let Prop::Ptr = prop {
                                    match (var, idx) {
                                        (VarType::FloatArray(1, ..), Index::Array1D(i1)) => {
                                            format!("({} + {})", id, self.gen_expr(i1)?)
                                        }
                                        (VarType::FloatArray(2, ..), Index::Array2D(i1, i2)) => {
                                            format!(
                                                "({}[{}] + {})",
                                                id,
                                                self.gen_expr(i1)?,
                                                self.gen_expr(i2)?
                                            )
                                        }
                                        (VarType::FloatArray(3, ..), Index::Array3D(i1, i2, i3)) => {
                                            format!(
                                                "({}[{}][{}] + {})",
                                                id,
                                                self.gen_expr(i1)?,
                                                self.gen_expr(i2)?,
                                                self.gen_expr(i3)?
                                            )
                                        }
                                        (
                                            VarType::FloatArray(4, ..),
                                            Index::Array4D(i1, i2, i3, i4),
                                        ) => format!(
                                            "({}[{}][{}][{}] + {})",
                                            id,
                                            self.gen_expr(i1)?,
                                            self.gen_expr(i2)?,
                                            self.gen_expr(i3)?,
                                            self.gen_expr(i4)?
                                        ),
                                        (err_type, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, err_type)),
                                    }
                                } else {
                                    return Err(format!("Array '{}' does not support property access except for '.ptr'", name));
                                }
                            }
                            VarType::IntArray(..) => {
                                if let Prop::Ptr = prop {
                                    match (var, idx) {
                                        (VarType::IntArray(1, ..), Index::Array1D(i1)) => {
                                            format!("({} + {})", id, self.gen_expr(i1)?)
                                        }
                                        (VarType::IntArray(2, ..), Index::Array2D(i1, i2)) => {
                                            format!(
                                                "({}[{}] + {})",
                                                id,
                                                self.gen_expr(i1)?,
                                                self.gen_expr(i2)?
                                            )
                                        }
                                        (VarType::IntArray(3, ..), Index::Array3D(i1, i2, i3)) => {
                                            format!(
                                                "({}[{}][{}] + {})",
                                                id,
                                                self.gen_expr(i1)?,
                                                self.gen_expr(i2)?,
                                                self.gen_expr(i3)?
                                            )
                                        }
                                        (VarType::IntArray(4, ..), Index::Array4D(i1, i2, i3, i4)) => {
                                            format!(
                                                "({}[{}][{}][{}] + {})",
                                                id,
                                                self.gen_expr(i1)?,
                                                self.gen_expr(i2)?,
                                                self.gen_expr(i3)?,
                                                self.gen_expr(i4)?
                                            )
                                        }
                                        (err_type, _) => return Err(format!("Variable '{}' of type '{}' does not support property access", name, err_type)),
                                    }
                                } else {
                                    return Err(format!("Array '{}' does not support property access except for '.ptr'", name));
                                }
                            }
                            err_type => {
                                return Err(format!(
                                    "Variable '{}' of type '{}' does not support property access",
                                    name, err_type
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
            idx @ Index::Vec(_) => {
                return Err(format!(
                    "Variable '{}' cannot be indexed with '{:?}'",
                    name, idx
                ))
            }
        };

        Ok(out)
    }
}
