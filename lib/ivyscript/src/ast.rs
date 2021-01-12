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

#[derive(Debug)]
pub enum Expr {
    Literal(Literal),
    Unary(Box<UnaryExpr>),
    Binary(Box<BinaryExpr>),
    Identifier(String),
    Index(Box<Expr>, Box<Index>),
    Grouping(Box<Expr>),
    Call(String, Vec<Expr>),
    Array(Vec<Expr>),
}

#[derive(Debug)]
pub enum Index {
    Prop(Prop),
    Vec(u8),
    ColorSpace(ColorSpace),
    Array1D(Expr),
    Array2D(Expr, Expr),
    Array3D(Expr, Expr, Expr),
    Array4D(Expr, Expr, Expr, Expr),
}

#[derive(Debug)]
pub enum Prop {
    Int,
    Idx,
    Ptr,
    IntPtr,
}

#[derive(Debug, Eq, PartialEq, Copy, Clone)]
pub enum ColorSpace {
    SRGB,
    LRGB,
    XYZ,
    LAB,
    LCH,
    Y,
    L,
}

impl std::fmt::Display for ColorSpace {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                ColorSpace::SRGB => "SRGB",
                ColorSpace::LRGB => "LRGB",
                ColorSpace::XYZ => "XYZ",
                ColorSpace::LAB => "LAB",
                ColorSpace::LCH => "LCH",
                ColorSpace::Y => "Y",
                ColorSpace::L => "L",
            }
        )
    }
}

#[derive(Debug)]
pub enum Literal {
    Bool(bool),
    Int(i32),
    Float(f32),
    //Array(Vec<f32>),
}

#[derive(Debug)]
pub struct UnaryExpr {
    pub op: UnaryOp,
    pub right: Expr,
}

#[derive(Debug)]
pub struct BinaryExpr {
    pub left: Expr,
    pub op: BinaryOp,
    pub right: Expr,
}

#[derive(Debug)]
pub enum UnaryOp {
    Not,
    Neg,
}

#[derive(Debug)]
pub enum BinaryOp {
    And,
    Or,

    Sub,
    Add,
    Div,
    Mul,
    Mod,
    Pow,

    Equal,
    NotEqual,

    Less,
    LessEqual,
    Greater,
    GreaterEqual,
}

#[derive(Debug)]
pub enum AssignOp {
    Sub,
    Add,
    Div,
    Mul,
    Mod,
    Pow,
}

#[derive(Debug)]
pub struct Cond {
    pub cond: Expr,
    pub body: Vec<Stmt>,
}

#[derive(Debug)]
pub enum Stmt {
    Var(String, Expr),
    Const(String, Expr),
    Local(String, Expr),
    Assign(Expr, Expr),
    AssignOp(Expr, AssignOp, Expr),

    Call(String, Vec<Expr>),
    Return(Option<Expr>),
    Continue,
    Break,

    IfElse {
        cond_list: Vec<Cond>,
        else_body: Vec<Stmt>,
    },
    For {
        var: String,
        from: Expr,
        to: Expr,
        step: Option<Expr>,
        body: Vec<Stmt>,
    },
    While {
        cond: Expr,
        body: Vec<Stmt>,
    },

    Kernel {
        id: String,
        args: Vec<String>,
        body: Vec<Stmt>,
    },
    Function {
        id: String,
        args: Vec<String>,
        body: Vec<Stmt>,
    },

    Comment(String),
    EOF,
    //Error(String),
}
