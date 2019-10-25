/*
  Copyright (C) 2011-2019 G. Bajlekov

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

use crate::ast::{
    BinaryExpr, BinaryOp, ColorSpace, Expr, Index, Literal, Stmt, UnaryExpr, UnaryOp,
};

use crate::inference::{Inference, VarType};

pub struct Generator<'a> {
    ast: Vec<Stmt>,
    inference: RefCell<Inference<'a>>,
    constants: RefCell<HashMap<String, &'a Expr>>,
    functions: RefCell<HashMap<String, &'a Stmt>>,
    kernels: RefCell<HashMap<String, &'a Stmt>>,
    generated_constants: RefCell<Option<String>>,
    generated_functions: RefCell<HashMap<String, (String, String, VarType)>>, // collect specialized functions: (declaration, definition, return value)
    generated_kernels: RefCell<HashMap<String, String>>, // collect specialized kernels: (kernel)
    temp: RefCell<String>,
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
            temp: RefCell::new(String::new()),
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
                _ => {}
            }
        }
    }

    fn function(&'a self, name: &str, input: &[VarType]) -> String {
        let id = function_id(name, input);

        if self.generated_functions.borrow().get(&id).is_some() {
            return id;
        }

        let kernel_scope = self.inference.borrow().scope.current.get();
        self.inference.borrow().scope.open();
        self.inference.borrow().scope.set_parent(0);

        self.inference
            .borrow()
            .scope
            .add("return", VarType::Unknown);

        // parse function
        if let Some(Stmt::Function { args, body, .. }) = self.functions.borrow().get(name) {
            let mut def = String::from("(\n");
            let mut decl;

            for (k, v) in args.iter().enumerate() {
                let arg = match input[k] {
                    VarType::Buffer { .. } => format!("global float *{}", v),
                    VarType::Int => format!("int {}", v),
                    VarType::Float => format!("float {}", v),
                    VarType::Vec => format!("float3 {}", v),
                    VarType::BoolArray(1, a, _, _, _) => format!("bool {}[{}]", v, a),
                    VarType::BoolArray(2, a, b, _, _) => format!("bool {}[{}][{}]", v, a, b),
                    VarType::BoolArray(3, a, b, c, _) => format!("bool {}[{}][{}][{}]", v, a, b, c),
                    VarType::BoolArray(4, a, b, c, d) => {
                        format!("bool {}[{}][{}][{}][{}]", v, a, b, c, d)
                    }
                    VarType::IntArray(1, a, _, _, _) => format!("int {}[{}]", v, a),
                    VarType::IntArray(2, a, b, _, _) => format!("int {}[{}][{}]", v, a, b),
                    VarType::IntArray(3, a, b, c, _) => format!("int {}[{}][{}][{}]", v, a, b, c),
                    VarType::IntArray(4, a, b, c, d) => {
                        format!("int {}[{}][{}][{}][{}]", v, a, b, c, d)
                    }
                    VarType::FloatArray(1, a, _, _, _) => format!("float {}[{}]", v, a),
                    VarType::FloatArray(2, a, b, _, _) => format!("float {}[{}][{}]", v, a, b),
                    VarType::FloatArray(3, a, b, c, _) => {
                        format!("float {}[{}][{}][{}]", v, a, b, c)
                    }
                    VarType::FloatArray(4, a, b, c, d) => {
                        format!("float {}[{}][{}][{}][{}]", v, a, b, c, d)
                    }
                    VarType::VecArray(1, a, _, _, _) => format!("float3 {}[{}]", v, a),
                    VarType::VecArray(2, a, b, _, _) => format!("float3 {}[{}][{}]", v, a, b),
                    VarType::VecArray(3, a, b, c, _) => {
                        format!("float3 {}[{}][{}][{}]", v, a, b, c)
                    }
                    VarType::VecArray(4, a, b, c, d) => {
                        format!("float3 {}[{}][{}][{}][{}]", v, a, b, c, d)
                    }
                    _ => String::from("/*** Error: Unknown type ***/"),
                };

                if k < args.len() - 1 {
                    def.push_str(&format!("\t{},\n", arg));
                } else {
                    def.push_str(&format!("\t{}\n", arg));
                }

                self.inference.borrow().scope.add(v, input[k]);
            }

            def.push_str(")");

            decl = def.clone();

            def.push_str(" {\n");

            for v in body {
                def.push_str(&self.gen_stmt(v));
            }

            let ret_type = self.inference.borrow().scope.get("return").unwrap();

            def = format!(
                "{} {} {}}}",
                match ret_type {
                    VarType::Bool => "bool",
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float3",
                    VarType::Unknown => "void",
                    _ => "/*** Error: Unknown type ***/",
                },
                id,
                def
            );

            decl = format!(
                "{} {} {};",
                match ret_type {
                    VarType::Bool => "bool",
                    VarType::Int => "int",
                    VarType::Float => "float",
                    VarType::Vec => "float3",
                    VarType::Unknown => "void",
                    _ => "/*** Error: Unknown type ***/",
                },
                id,
                decl
            );

            let temp = self.temp.borrow().clone();
            let temp = format!("{}\n{}\n{}\n", &decl, temp, &def);
            self.temp.replace(temp);

            // TODO: register function return types in order to have them inferred properly
            // register generated_functions
            self.generated_functions
                .borrow_mut()
                .insert(id.clone(), (decl, def, ret_type));
        }

        self.inference.borrow().scope.close();
        self.inference.borrow().scope.set_current(kernel_scope);

        id
    }

    pub fn kernel(&'a self, name: &str, input: &[VarType]) -> Option<String> {
        self.inference.borrow().scope.clear();
        self.inference.borrow_mut().functions = Some(&self.generated_functions);

        if self.generated_constants.borrow().is_none() {
            let mut s = String::new();
            for (k, v) in self.constants.borrow().iter() {
                s.push_str(&format!("constant {}", self.gen_var(k, v)));
            }
            self.generated_constants.replace(Some(s));
        }

        let id = function_id(name, input);
        if let Some(k) = self.generated_kernels.borrow().get(&id) {
            return Some(k.clone());
        }

        let kernels = self.kernels.borrow();
        let kernel = kernels.get(name).unwrap();
        if let Stmt::Kernel { id, args, body } = kernel {
            let mut s = format!("kernel void {} (\n", id);
            self.inference.borrow().scope.open();
            self.inference
                .borrow()
                .scope
                .add("return", VarType::Unknown);

            self.temp
                .replace(self.generated_constants.borrow().clone().unwrap());

            for (k, v) in args.iter().enumerate() {
                let arg = format!(
                    "{}{}",
                    match input[k] {
                        VarType::Buffer { .. } => "global float *",
                        VarType::Int => "int ",
                        VarType::Float => "float ",
                        VarType::IntArray(1, ..) => "int *",
                        VarType::FloatArray(1, ..) => "float *",
                        _ => "/*** Error: Unknown type ***/",
                    },
                    v
                );

                if k < args.len() - 1 {
                    s.push_str(&format!("\t{},\n", arg));
                } else {
                    s.push_str(&format!("\t{}\n", arg));
                }

                self.inference.borrow().scope.add(v, input[k]);
            }

            s.push_str(") {\n");

            for v in body {
                s.push_str(&self.gen_stmt(v));
            }

            assert!(self.inference.borrow().scope.get("return").unwrap() == VarType::Unknown);

            self.inference.borrow().scope.close();
            s.push_str("}");

            return Some(format!("#include \"cs.cl\"\n{}\n{}", self.temp.borrow().clone(), s));
        }

        None
    }

    pub fn id(name: &str, input: &[VarType]) -> String {
        function_id(name, input)
    }

    fn gen_stmt(&'a self, stmt: &Stmt) -> String {
        match stmt {
            Stmt::Var(id, expr) => self.gen_var(id, expr),
            Stmt::Const(id, expr) => format!("const {}", self.gen_var(id, expr)),
            Stmt::Local(id, expr) => format!("local {}", self.gen_var(id, expr)),
            Stmt::Assign(id, expr) => self.gen_assign(id, expr),
            Stmt::For {
                var,
                from,
                to,
                step,
                body,
            } => self.gen_for(var, from, to, step, body),
            Stmt::IfElse {
                cond,
                if_body,
                else_body,
            } => self.gen_if_else(cond, if_body, else_body),
            Stmt::While { cond, body } => self.gen_while(cond, body),
            Stmt::Return(None) => {
                if self.inference.borrow().scope.get("return").unwrap() == VarType::Unknown {
                    String::from("return;\n")
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            Stmt::Return(Some(expr)) => {
                let expr_str = self.gen_expr(expr); // generate before assessing type!

                // return value is either new, same as--, or promoted from the previous one
                let t1 = self.inference.borrow().var_type(expr);
                let t2 = self.inference.borrow().scope.get("return").unwrap();
                let t3 = self.inference.borrow().promote(t1, t2);

                if t2 == VarType::Unknown {
                    self.inference.borrow().scope.overwrite("return", t1);
                } else if t3 == VarType::Unknown {
                    return String::from("// ERROR!!!\n");
                } else {
                    self.inference.borrow().scope.overwrite("return", t3);
                }

                format!("return {};\n", expr_str)
            }
            Stmt::Comment(c) => format!("//{}\n", c),
            _ => String::from("// ERROR!!!\n"),
        }
    }

    fn gen_for(
        &'a self,
        var: &str,
        from: &Expr,
        to: &Expr,
        step: &Option<Expr>,
        body: &[Stmt],
    ) -> String {
        self.inference.borrow().scope.open();

        let mut s;

        // infer var type
        let from_type = self.inference.borrow().var_type(from);
        let to_type = self.inference.borrow().var_type(to);

        let mut var_type = self.inference.borrow().promote_num(from_type, to_type);

        if let Some(step) = &step {
            let step_type = self.inference.borrow().var_type(step);
            var_type = self.inference.borrow().promote_num(var_type, step_type);
            self.inference.borrow().scope.add(var, var_type);

            s = format!(
                "for ({var_type} {var} = {from}; {var}<={to}; {var} += {step}) {{\n",
                var_type = match var_type {
                    VarType::Int => "int",
                    VarType::Float => "float",
                    _ => "/*** Error: Unknown type ***/",
                },
                var = var,
                from = self.gen_expr(&from),
                to = self.gen_expr(&to),
                step = self.gen_expr(&step),
            )
        } else {
            let step = match var_type {
                VarType::Int => Expr::Literal(Literal::Int(1)),
                VarType::Float => Expr::Literal(Literal::Float(1.0)),
                VarType::Vec => Expr::Call(
                    String::from("vec"),
                    vec![Expr::Literal(Literal::Float(1.0))],
                ),
                _ => return String::from("// ERROR!!!\n"),
            };
            self.inference.borrow().scope.add(var, var_type);

            s = format!("for ({var_type} {var} = {from}; ({step}>0)?({var}<={to}):({var}>={to}); {var} += {step}) {{\n",
            var_type = match var_type{
                VarType::Int => "int",
                VarType::Float => "float",
                VarType::Vec => "float3",
                _ => "/*** Error: Unknown type ***/"
            },
            var = var,
            from = self.gen_expr(&from),
            to = self.gen_expr(&to),
            step = self.gen_expr(&step),
            )
        }

        for v in body {
            s.push_str(&self.gen_stmt(v));
        }

        s.push_str("}\n");
        self.inference.borrow().scope.close();
        s
    }

    fn gen_if_else(&'a self, cond: &Expr, if_body: &[Stmt], else_body: &[Stmt]) -> String {
        let mut s = format!("if ({}) {{\n", self.gen_expr(cond));
        assert!(self.inference.borrow().var_type(cond) == VarType::Bool); // type info available only after generation!

        self.inference.borrow().scope.open();
        for v in if_body {
            s.push_str(&self.gen_stmt(v));
        }
        self.inference.borrow().scope.close();

        if !else_body.is_empty() {
            s.push_str("} else {\n");
            self.inference.borrow().scope.open();
            for v in else_body {
                s.push_str(&self.gen_stmt(v));
            }
            self.inference.borrow().scope.close();
        }
        s.push_str("}\n");

        s
    }

    fn gen_while(&'a self, cond: &Expr, body: &[Stmt]) -> String {
        assert!(self.inference.borrow().var_type(cond) == VarType::Bool);

        let mut s = format!("while ({}) {{\n", self.gen_expr(cond));

        self.inference.borrow().scope.open();
        for v in body {
            s.push_str(&self.gen_stmt(v));
        }
        self.inference.borrow().scope.close();
        s.push_str("}}\n");

        s
    }

    fn gen_var(&'a self, id: &str, expr: &Expr) -> String {
        let expr_str = self.gen_expr(&expr); // generate before assessing type!

        let var_type = self.inference.borrow().var_type(expr);
        self.inference.borrow().scope.add(id, var_type);

        match var_type {
            VarType::Bool => format!("bool {} = {};\n", id, expr_str),
            VarType::Int => format!("int {} = {};\n", id, expr_str),
            VarType::Float => format!("float {} = {};\n", id, expr_str),
            VarType::Vec => format!("float3 {} = {};\n", id, expr_str),

            VarType::BoolArray(1, a, _, _, _) => format!("bool {} [{}];\n", id, a),
            VarType::BoolArray(2, a, b, _, _) => format!("bool {} [{}][{}];\n", id, a, b),
            VarType::BoolArray(3, a, b, c, _) => format!("bool {} [{}][{}][{}];\n", id, a, b, c),
            VarType::BoolArray(4, a, b, c, d) => {
                format!("bool {} [{}][{}][{}][{}];\n", id, a, b, c, d)
            }

            VarType::IntArray(1, a, _, _, _) => format!("int {} [{}];\n", id, a),
            VarType::IntArray(2, a, b, _, _) => format!("int {} [{}][{}];\n", id, a, b),
            VarType::IntArray(3, a, b, c, _) => format!("int {} [{}][{}][{}];\n", id, a, b, c),
            VarType::IntArray(4, a, b, c, d) => {
                format!("int {} [{}][{}][{}][{}];\n", id, a, b, c, d)
            }

            VarType::FloatArray(1, a, _, _, _) => format!("float {} [{}];\n", id, a),
            VarType::FloatArray(2, a, b, _, _) => format!("float {} [{}][{}];\n", id, a, b),
            VarType::FloatArray(3, a, b, c, _) => format!("float {} [{}][{}][{}];\n", id, a, b, c),
            VarType::FloatArray(4, a, b, c, d) => {
                format!("float {} [{}][{}][{}][{}];\n", id, a, b, c, d)
            }

            VarType::VecArray(1, a, _, _, _) => format!("float3 {} [{}];\n", id, a),
            VarType::VecArray(2, a, b, _, _) => format!("float3 {} [{}][{}];\n", id, a, b),
            VarType::VecArray(3, a, b, c, _) => format!("float3 {} [{}][{}][{}];\n", id, a, b, c),
            VarType::VecArray(4, a, b, c, d) => {
                format!("float3 {} [{}][{}][{}][{}];\n", id, a, b, c, d)
            }

            _ => String::from("// ERROR!!!\n"),
        }
    }

    fn gen_expr(&'a self, expr: &Expr) -> String {
        match expr {
            Expr::Literal(Literal::Bool(true)) => String::from("true"),
            Expr::Literal(Literal::Bool(false)) => String::from("false"),
            Expr::Literal(Literal::Int(n)) => format!("{}", n),
            Expr::Literal(Literal::Float(n)) => format!("{:.7}f", n),
            Expr::Unary(expr) => self.gen_unary(expr),
            Expr::Binary(expr) => self.gen_binary(expr),
            Expr::Identifier(id) => id.clone(),
            Expr::Index(expr, idx) => self.gen_index(expr, idx),
            Expr::Grouping(expr) => format!("({})", self.gen_expr(expr)),
            Expr::Call(id, args) => {
                if self.inference.borrow().builtin(id, args).is_some() {
                    let args_str = args
                        .iter()
                        .map(|e| self.gen_expr(e))
                        .collect::<Vec<String>>();
                    self.gen_call(id, &args_str)
                } else {
                    let args_str = args
                        .iter()
                        .map(|e| self.gen_expr(e))
                        .collect::<Vec<String>>();
                    let vars = args
                        .iter()
                        .map(|e| self.inference.borrow().var_type(e))
                        .collect::<Vec<VarType>>();
                    let id = self.function(id, &vars);
                    self.gen_call(&id, &args_str)
                }
            }
            _ => String::from("// ERROR!!!\n"),
        }
    }

    fn gen_unary(&'a self, expr: &UnaryExpr) -> String {
        match expr.op {
            UnaryOp::Not => format!("!{}", self.gen_expr(&expr.right)),
            UnaryOp::Neg => format!("(-{})", self.gen_expr(&expr.right)),
        }
    }

    fn gen_binary(&'a self, expr: &BinaryExpr) -> String {
        match expr.op {
            BinaryOp::And => format!(
                "{} && {}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Or => format!(
                "{} || {}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),

            BinaryOp::Sub => format!(
                "{} - {}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Add => format!(
                "{} + {}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Div => format!(
                "{}/{}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Mul => format!(
                "{}*{}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Mod => format!(
                "{}%{}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Pow => {
                let call = if self.inference.borrow().var_type(&expr.right) == VarType::Int {
                    "pown"
                } else {
                    "pow"
                };

                if self.inference.borrow().var_type(&expr.left) == VarType::Int {
                    format!(
                        "{}((float)({}), {})",
                        call,
                        self.gen_expr(&expr.left),
                        self.gen_expr(&expr.right)
                    )
                } else {
                    format!(
                        "{}({}, {})",
                        call,
                        self.gen_expr(&expr.left),
                        self.gen_expr(&expr.right)
                    )
                }
            }

            BinaryOp::Equal => format!(
                "{}=={}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::NotEqual => format!(
                "{}!={}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),

            BinaryOp::Less => format!(
                "{}<{}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::LessEqual => format!(
                "{}<={}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::Greater => format!(
                "{}>{}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
            BinaryOp::GreaterEqual => format!(
                "{}>={}",
                self.gen_expr(&expr.left),
                self.gen_expr(&expr.right)
            ),
        }
    }

    fn gen_call(&'a self, id: &str, args: &[String]) -> String {
        let id = match id {
            "bool" => "(bool)",
            "int" => "(int)",
            "float" => "(float)",
            "vec" => "(float3)",
            s => s,
        };

        let mut s = String::new();
        for (k, v) in args.iter().enumerate() {
            s.push_str(&v);
            if k < args.len() - 1 {
                s.push_str(", ");
            }
        }

        return format!("{}({})", id, s);
    }

    fn gen_assign(&'a self, expr: &Expr, val: &Expr) -> String {
        if let Expr::Index(expr, idx) = expr {
            if let Index::ColorSpace(cs_from) = &**idx {
                // assign vec with color space conversion
                if let Expr::Index(id, idx) = &**expr {
                    if let Expr::Identifier(name) = &**id {
                        if let Index::Array2D(a, b) = &**idx {
                            let var = self.inference.borrow().var_type(id);
                            if let VarType::Buffer { z, cs, .. } = var {
                                let cs = format!("{}to{}", cs_from, cs);

                                if z == 3 {
                                    let id_x = var.buf_idx_3d(
                                        name,
                                        &self.gen_expr(a),
                                        &self.gen_expr(b),
                                        "0",
                                    );
                                    let id_y = var.buf_idx_3d(
                                        name,
                                        &self.gen_expr(a),
                                        &self.gen_expr(b),
                                        "1",
                                    );
                                    let id_z = var.buf_idx_3d(
                                        name,
                                        &self.gen_expr(a),
                                        &self.gen_expr(b),
                                        "2",
                                    );

                                    format!("{{ float3 __v = {}({}); {} = __v.x; {} = __v.y; {} = __v.z; }}\n", cs, self.gen_expr(val), id_x, id_y, id_z)
                                } else if z == 1 {
                                    // match buffer storage size to color space
                                    let id = var.buf_idx_3d(
                                        name,
                                        &self.gen_expr(a),
                                        &self.gen_expr(b),
                                        "0",
                                    );

                                    format!("{} = {}({});\n", id, cs, self.gen_expr(val))
                                } else {
                                    String::from("// ERROR!!!\n")
                                }
                            } else {
                                String::from("// ERROR!!!\n")
                            }
                        } else {
                            String::from("// ERROR!!!\n")
                        }
                    } else {
                        String::from("// ERROR!!!\n")
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            } else if let Index::Array1D(a) = &**idx {
                let var = self.inference.borrow().var_type(expr);
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(1, ..)
                        | VarType::IntArray(1, ..)
                        | VarType::FloatArray(1, ..)
                        | VarType::VecArray(1, ..) => {
                            format!("{}[{}] = {};\n", name, self.gen_expr(a), self.gen_expr(val))
                        }
                        VarType::Buffer{..} => {
                            let id = var.buf_idx_1d(name, &self.gen_expr(a));
                            format!("{} = {};\n", id, self.gen_expr(val))
                        }
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            } else if let Index::Array2D(a, b) = &**idx {
                let var = self.inference.borrow().var_type(expr);
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::Buffer { z: 1, .. } => {
                            let id =
                                var.buf_idx_3d(name, &self.gen_expr(a), &self.gen_expr(b), "0");
                            format!("{} = {};\n", id, self.gen_expr(val))
                        }
                        VarType::Buffer { z: 3, .. } => {
                            let id_x =
                                var.buf_idx_3d(name, &self.gen_expr(a), &self.gen_expr(b), "0");
                            let id_y =
                                var.buf_idx_3d(name, &self.gen_expr(a), &self.gen_expr(b), "1");
                            let id_z =
                                var.buf_idx_3d(name, &self.gen_expr(a), &self.gen_expr(b), "2");
                            format!(
                                "{{ float3 __v = {}; {} = __v.x; {} = __v.y; {} = __v.z; }}\n",
                                self.gen_expr(val),
                                id_x,
                                id_y,
                                id_z
                            )
                        }
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => format!(
                            "{}[{}][{}] = {};\n",
                            name,
                            self.gen_expr(a),
                            self.gen_expr(b),
                            self.gen_expr(val)
                        ),
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            } else if let Index::Array3D(a, b, c) = &**idx {
                let var = self.inference.borrow().var_type(expr);
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(a),
                            self.gen_expr(b),
                            self.gen_expr(c),
                            self.gen_expr(val)
                        ),
                        VarType::Buffer{..} => {
                            let id = var.buf_idx_3d(name, &self.gen_expr(a), &self.gen_expr(b), &self.gen_expr(c));
                            format!("{} = {};\n", id, self.gen_expr(val))
                        }
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            } else if let Index::Array4D(a, b, c, d) = &**idx {
                let var = self.inference.borrow().var_type(expr);
                if let Expr::Identifier(name) = &**expr {
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}] = {};\n",
                            name,
                            self.gen_expr(a),
                            self.gen_expr(b),
                            self.gen_expr(c),
                            self.gen_expr(d),
                            self.gen_expr(val)
                        ),
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            } else {
                let id = self.gen_index(expr, idx);
                format!("{} = {};\n", id, self.gen_expr(val))
            }
        } else {
            format!("{} = {};\n", self.gen_expr(expr), self.gen_expr(val))
        }
    }

    fn gen_index(&'a self, expr: &Expr, idx: &Index) -> String {
        match idx {
            Index::Vec(0) => {
                let var = self.inference.borrow().var_type(expr);
                dbg!(&var);
                match var {
                    VarType::Vec => format!("{}.x", self.gen_expr(expr)),
                    VarType::Buffer { x, .. } => format!("{}", x),
                    _ => String::from("// ERROR!!!\n"),
                }
            }
            Index::Vec(1) => {
                let var = self.inference.borrow().var_type(expr);
                match var {
                    VarType::Vec => format!("{}.y", self.gen_expr(expr)),
                    VarType::Buffer { y, .. } => format!("{}", y),
                    _ => String::from("// ERROR!!!\n"),
                }
            }
            Index::Vec(2) => {
                let var = self.inference.borrow().var_type(expr);
                match var {
                    VarType::Vec => format!("{}.z", self.gen_expr(expr)),
                    VarType::Buffer { z, .. } => format!("{}", z),
                    _ => String::from("// ERROR!!!\n"),
                }
            }
            Index::Array1D(a) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr);
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_1d(id, &self.gen_expr(a)),
                        VarType::BoolArray(1, ..)
                        | VarType::IntArray(1, ..)
                        | VarType::FloatArray(1, ..)
                        | VarType::VecArray(1, ..) => format!("{}[{}]", id, self.gen_expr(a)),
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            Index::Array2D(a, b) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr);
                    match var {
                        VarType::Buffer { z: 1, .. } => {
                            var.buf_idx_3d(id, &self.gen_expr(a), &self.gen_expr(b), "0")
                        }
                        VarType::Buffer { z: 3, .. } => {
                            var.buf_idx_2d(id, &self.gen_expr(a), &self.gen_expr(b))
                        }
                        VarType::BoolArray(2, ..)
                        | VarType::IntArray(2, ..)
                        | VarType::FloatArray(2, ..)
                        | VarType::VecArray(2, ..) => {
                            format!("{}[{}][{}]", id, self.gen_expr(a), self.gen_expr(b))
                        }
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            Index::Array3D(a, b, c) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr);
                    match var {
                        VarType::Buffer { .. } => var.buf_idx_3d(
                            id,
                            &self.gen_expr(a),
                            &self.gen_expr(b),
                            &self.gen_expr(c),
                        ),
                        VarType::BoolArray(3, ..)
                        | VarType::IntArray(3, ..)
                        | VarType::FloatArray(3, ..)
                        | VarType::VecArray(3, ..) => format!(
                            "{}[{}][{}][{}]",
                            id,
                            self.gen_expr(a),
                            self.gen_expr(b),
                            self.gen_expr(c),
                        ),
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            Index::Array4D(a, b, c, d) => {
                if let Expr::Identifier(id) = expr {
                    let var = self.inference.borrow().var_type(expr);
                    match var {
                        VarType::BoolArray(4, ..)
                        | VarType::IntArray(4, ..)
                        | VarType::FloatArray(4, ..)
                        | VarType::VecArray(4, ..) => format!(
                            "{}[{}][{}][{}][{}]",
                            id,
                            self.gen_expr(a),
                            self.gen_expr(b),
                            self.gen_expr(c),
                            self.gen_expr(d),
                        ),
                        _ => String::from("// ERROR!!!\n"),
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            Index::ColorSpace(cs_to) => {
                if let Expr::Index(expr, idx) = expr {
                    if let Expr::Identifier(id) = &**expr {
                        let var = self.inference.borrow().var_type(expr);
                        if let VarType::Buffer { z, cs, .. } = var {
                            let id = if let Index::Array2D(a, b) = &**idx {
                                if z == 1 {
                                    var.buf_idx_3d(id, &self.gen_expr(a), &self.gen_expr(b), "0")
                                } else if z == 3 {
                                    var.buf_idx_2d(id, &self.gen_expr(a), &self.gen_expr(b))
                                } else {
                                    String::from("// ERROR!!!\n")
                                }
                            } else {
                                String::from("// ERROR!!!\n")
                            };
                            format!("{}to{}({})", cs, cs_to, id)
                        } else {
                            String::from("// ERROR!!!\n")
                        }
                    } else {
                        String::from("// ERROR!!!\n")
                    }
                } else {
                    String::from("// ERROR!!!\n")
                }
            }
            _ => String::from("// ERROR!!!\n"),
        }
    }
}

impl VarType {
    fn buf_idx_1d(&self, id: &str, ix: &str) -> String {
        if let VarType::Buffer { x, y, z, .. } = self {
            format!(
                "{id}[clamp((int)({ix}), 0, {cx})]",
                id = id,
                ix = ix,
                cx = x * y * z - 1,
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }

    fn buf_idx_2d(&self, id: &str, x: &str, y: &str) -> String {
        format!(
            "(float3)( {}, {}, {} )",
            self.buf_idx_3d(id, x, y, "0"),
            self.buf_idx_3d(id, x, y, "1"),
            self.buf_idx_3d(id, x, y, "2"),
        )
    }

    fn buf_idx_3d(&self, id: &str, ix: &str, iy: &str, iz: &str) -> String {
        if let VarType::Buffer {
            x,
            y,
            z,
            sx,
            sy,
            sz,
            ..
        } = self
        {
            format!(
            "{id}[clamp((int)({ix}), 0, {cx})*{sx} + clamp((int)({iy}), 0, {cy})*{sy} + clamp((int)({iz}), 0, {cz})*{sz}]",
            id = id,
            ix = ix,
            iy = iy,
            iz = iz,
            cx = x - 1,
            cy = y - 1,
            cz = z - 1,
            sx = sx,
            sy = sy,
            sz = sz,
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }
}

pub fn function_id(name: &str, input: &[VarType]) -> String {
    let mut id = String::from("___");
    for v in input {
        let s = match v {
            VarType::Bool => String::from("Bool_"),
            VarType::Int => String::from("Int_"),
            VarType::Float => String::from("Float_"),
            VarType::Vec => String::from("Vec_"),
            VarType::BoolArray(n, x, y, z, w) => {
                format!("BoolArray_{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::IntArray(n, x, y, z, w) => format!("IntArray_{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::FloatArray(n, x, y, z, w) => {
                format!("FloatArray_{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::VecArray(n, x, y, z, w) => format!("VecArray_{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::Buffer {
                x,
                y,
                z,
                sx,
                sy,
                sz,
                cs,
            } => format!(
                "Buffer_{}_{}_{}_{}_{}_{}_{}_",
                x,
                y,
                z,
                sx,
                sy,
                sz,
                match cs {
                    ColorSpace::SRGB => "SRGB",
                    ColorSpace::LRGB => "LRGB",
                    ColorSpace::XYZ => "XYZ",
                    ColorSpace::LAB => "LAB",
                    ColorSpace::LCH => "LCH",
                    ColorSpace::Y => "Y",
                    ColorSpace::L => "L",
                }
            ),
            _ => String::from("/*** Error: Unknown type ***/"),
        };
        id.push_str(&s);
    }
    id.push_str("__");
    id.push_str(name);
    id
}
