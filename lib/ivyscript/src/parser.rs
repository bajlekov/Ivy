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

use std::cell::Cell;

use crate::ast::{
    AssignOp, BinaryExpr, BinaryOp, ColorSpace, Cond, Expr, Index, Literal, Prop, Stmt, UnaryExpr,
    UnaryOp,
};

use crate::tokens::{Token, TokenType};

pub struct Parser {
    tokens: Vec<Token>,
    current: Cell<Option<usize>>,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Parser {
        Parser {
            tokens,
            current: Cell::new(Some(0)),
        }
    }

    pub fn parse(&self) -> Vec<Stmt> {
        let mut stmts = Vec::new();
        while let Some(_) = self.current.get() {
            stmts.push(self.statement());
        }
        stmts
    }

    fn advance(&self) {
        if let Some(mut current) = self.current.get() {
            current += 1;
            if current < self.tokens.len() {
                self.current.set(Some(current));
            } else {
                self.current.set(None);
            }
        }
    }

    fn peek(&self) -> &TokenType {
        if let Some(current) = self.current.get() {
            &self.tokens[current].token
        } else {
            &TokenType::EOF
        }
    }

    fn peek_next(&self) -> &TokenType {
        if let Some(current) = self.current.get() {
            if current + 1 < self.tokens.len() {
                &self.tokens[current + 1].token
            } else {
                &TokenType::EOF
            }
        } else {
            &TokenType::EOF
        }
    }

    fn var_decl(&self) -> Option<(String, Expr)> {
        self.advance(); // skip var
        if let TokenType::Identifier(id) = self.peek() {
            self.advance(); // skip identifier
            if &TokenType::Equal == self.peek() {
                self.advance(); // skip =
                return Some((id.clone(), self.expression()));
            }
        }

        None
    }

    fn if_branch(&self) -> Option<(Vec<Cond>, Vec<Stmt>)> {
        let mut cond_list = Vec::new();
        let mut else_body = Vec::new();

        self.advance(); // skip if
        let cond = self.expression();
        let mut body = Vec::new();
        if self.peek() == &TokenType::Then {
            self.advance(); // skip optional then
        }
        loop {
            match self.peek() {
                &TokenType::ElseIf => break,
                &TokenType::Else => break,
                &TokenType::End => break,
                _ => {}
            }

            match self.statement() {
                Stmt::Error => return None,
                Stmt::EOF => return None,
                s => body.push(s),
            }
        }
        cond_list.push(Cond { cond, body });

        while self.peek() == &TokenType::ElseIf {
            self.advance(); // skip elseIf
            let cond = self.expression();
            let mut body = Vec::new();
            if self.peek() == &TokenType::Then {
                self.advance(); // skip optional then
            }
            loop {
                match self.peek() {
                    &TokenType::ElseIf => continue,
                    &TokenType::Else => break,
                    &TokenType::End => break,
                    _ => {}
                }

                match self.statement() {
                    Stmt::Error => return None,
                    Stmt::EOF => return None,
                    s => body.push(s),
                }
            }
            cond_list.push(Cond { cond, body });
        }

        if self.peek() == &TokenType::Else {
            self.advance(); // skip else
            loop {
                match self.peek() {
                    &TokenType::End => break,
                    _ => {}
                }

                match self.statement() {
                    Stmt::Error => return None,
                    Stmt::EOF => return None,
                    s => else_body.push(s),
                }
            }
        }

        self.advance(); // skip end

        Some((cond_list, else_body))
    }

    fn while_loop(&self) -> Option<(Expr, Vec<Stmt>)> {
        self.advance(); // skip while

        let cond = self.expression();

        if self.peek() == &TokenType::Do {
            // skip optional do
            self.advance();
        }

        let mut body = Vec::new();
        loop {
            if self.peek() == &TokenType::End {
                self.advance();
                break;
            }
            match self.statement() {
                Stmt::Error => return None,
                Stmt::EOF => return None,
                s => body.push(s),
            }
        }

        Some((cond, body))
    }

    fn for_loop(&self) -> Option<(String, Expr, Expr, Option<Expr>, Vec<Stmt>)> {
        self.advance(); // skip for

        let var;
        let from;
        let to;
        let step;

        if let TokenType::Identifier(s) = self.peek() {
            var = s.clone();
            self.advance(); // skip identifier
        } else {
            return None;
        }

        if self.peek() != &TokenType::Equal {
            return None;
        }
        self.advance(); // skip =
        from = self.expression();
        if self.peek() != &TokenType::Comma {
            return None;
        }
        self.advance(); // skip ,
        to = self.expression();
        if self.peek() == &TokenType::Comma {
            self.advance(); // skip comma
            step = Some(self.expression());
        } else {
            step = None
        }

        if self.peek() == &TokenType::Do {
            // skip optional do
            self.advance();
        }

        // get body
        let mut body = Vec::new();
        loop {
            if self.peek() == &TokenType::End {
                self.advance();
                break;
            }
            match self.statement() {
                Stmt::Error => return None,
                Stmt::EOF => return None,
                s => body.push(s),
            }
        }

        Some((var, from, to, step, body))
    }

    fn fun_decl(&self) -> Option<(String, Vec<String>, Vec<Stmt>)> {
        self.advance(); // skip fun

        let id;
        if let TokenType::Identifier(s) = self.peek() {
            id = s.clone();
            self.advance(); // skip identifier
        } else {
            return None;
        }

        // get arguments
        if self.peek() == &TokenType::LeftParen {
            self.advance(); // skip left parenthesis

            let mut args = Vec::new();
            loop {
                match self.peek() {
                    TokenType::Identifier(s) => {
                        args.push(s.clone());
                    }
                    TokenType::RightParen => break,
                    _ => return None,
                }
                self.advance();
                match self.peek() {
                    TokenType::Comma => self.advance(), // skip comma
                    TokenType::RightParen => break,
                    _ => return None,
                }
            }
            self.advance();

            // get body
            let mut body = Vec::new();
            loop {
                if self.peek() == &TokenType::End {
                    self.advance();
                    break;
                }
                match self.statement() {
                    Stmt::Error => return None,
                    Stmt::EOF => return None,
                    s => body.push(s),
                }
            }

            Some((id, args, body))
        } else {
            None
        }
    }

    fn fun_return(&self) -> Option<Expr> {
        self.advance(); // skip return

        let expr = match self.peek() {
            TokenType::End | TokenType::Else | TokenType::ElseIf => return None,
            _ => self.expression(),
        };

        match self.peek() {
            TokenType::End | TokenType::Else | TokenType::ElseIf => Some(expr),
            _ => Some(Expr::Error),
        }
    }

    fn statement(&self) -> Stmt {
        match self.peek() {
            TokenType::Var => {
                if let Some((id, expr)) = self.var_decl() {
                    Stmt::Var(id, expr)
                } else {
                    Stmt::Error
                }
            }

            TokenType::Const => {
                if let Some((id, expr)) = self.var_decl() {
                    Stmt::Const(id, expr)
                } else {
                    Stmt::Error
                }
            }

            TokenType::Local => {
                if let Some((id, expr)) = self.var_decl() {
                    Stmt::Local(id, expr)
                } else {
                    Stmt::Error
                }
            }

            TokenType::Function => {
                if let Some((id, args, body)) = self.fun_decl() {
                    Stmt::Function { id, args, body }
                } else {
                    Stmt::Error
                }
            }

            TokenType::Kernel => {
                if let Some((id, args, body)) = self.fun_decl() {
                    Stmt::Kernel { id, args, body }
                } else {
                    Stmt::Error
                }
            }

            TokenType::Return => match self.fun_return() {
                Some(Expr::Error) => Stmt::Error,
                Some(expr) => Stmt::Return(Some(expr)),
                None => Stmt::Return(None),
            },

            TokenType::Continue => match self.fun_return() {
                Some(_) => Stmt::Error,
                None => Stmt::Continue,
            },

            TokenType::Break => match self.fun_return() {
                Some(_) => Stmt::Error,
                None => Stmt::Break,
            },

            TokenType::If => {
                if let Some((cond_list, else_body)) = self.if_branch() {
                    Stmt::IfElse {
                        cond_list,
                        else_body,
                    }
                } else {
                    Stmt::Error
                }
            }

            TokenType::While => {
                if let Some((cond, body)) = self.while_loop() {
                    Stmt::While { cond, body }
                } else {
                    Stmt::Error
                }
            }

            TokenType::For => {
                if let Some((var, from, to, step, body)) = self.for_loop() {
                    Stmt::For {
                        var,
                        from,
                        to,
                        step,
                        body,
                    }
                } else {
                    Stmt::Error
                }
            }

            TokenType::Identifier(s) if self.peek_next() == &TokenType::LeftParen => {
                self.advance(); // skip identifier
                self.advance(); // skip left parenthesis

                let mut err = false;
                let mut args = Vec::new();
                loop {
                    args.push(self.expression());
                    match self.peek() {
                        TokenType::Comma => self.advance(),
                        TokenType::RightParen => {
                            self.advance();
                            break;
                        }
                        _ => {
                            err = true;
                            break;
                        }
                    }
                }

                if err {
                    Stmt::Error
                } else {
                    Stmt::Call(s.clone(), args)
                }
            }

            TokenType::Identifier(_) => {
                let id = self.identifier();
                self.advance();

                // match equal sign
                match self.peek() {
                    TokenType::Equal => {
                        self.advance();
                        Stmt::Assign(id, self.expression())
                    }
                    TokenType::PlusEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Add, self.expression())
                    }
                    TokenType::MinusEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Sub, self.expression())
                    }
                    TokenType::SlashEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Div, self.expression())
                    }
                    TokenType::StarEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Mul, self.expression())
                    }
                    TokenType::PercentEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Mod, self.expression())
                    }
                    TokenType::CaretEqual => {
                        self.advance();
                        Stmt::AssignOp(id, AssignOp::Pow, self.expression())
                    }
                    _ => Stmt::Error,
                }
            }

            TokenType::Comment(s) => {
                self.advance();
                Stmt::Comment(s.clone())
            }
            TokenType::EOF => {
                self.advance();
                Stmt::EOF
            }
            _ => {
                self.advance();
                Stmt::Error
            }
        }
    }

    fn expression(&self) -> Expr {
        self.logic_or()
    }

    fn logic_or(&self) -> Expr {
        let mut left = self.logic_and();
        while let Some(op) = match self.peek() {
            TokenType::Or => Some(BinaryOp::Or),
            _ => None,
        } {
            self.advance();
            let right = self.logic_and();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn logic_and(&self) -> Expr {
        let mut left = self.equality();
        while let Some(op) = match self.peek() {
            TokenType::And => Some(BinaryOp::And),
            _ => None,
        } {
            self.advance();
            let right = self.equality();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn equality(&self) -> Expr {
        let mut left = self.comparison();
        while let Some(op) = match self.peek() {
            TokenType::NotEqual => Some(BinaryOp::NotEqual),
            TokenType::EqualEqual => Some(BinaryOp::Equal),
            _ => None,
        } {
            self.advance();
            let right = self.comparison();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn comparison(&self) -> Expr {
        let mut left = self.addition();
        while let Some(op) = match self.peek() {
            TokenType::Greater => Some(BinaryOp::Greater),
            TokenType::GreaterEqual => Some(BinaryOp::GreaterEqual),
            TokenType::Less => Some(BinaryOp::Less),
            TokenType::LessEqual => Some(BinaryOp::LessEqual),
            _ => None,
        } {
            self.advance();
            let right = self.addition();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn addition(&self) -> Expr {
        let mut left = self.multiplication();
        while let Some(op) = match self.peek() {
            TokenType::Minus => Some(BinaryOp::Sub),
            TokenType::Plus => Some(BinaryOp::Add),
            _ => None,
        } {
            self.advance();
            let right = self.multiplication();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn multiplication(&self) -> Expr {
        let mut left = self.unary();
        while let Some(op) = match self.peek() {
            TokenType::Slash => Some(BinaryOp::Div),
            TokenType::Star => Some(BinaryOp::Mul),
            TokenType::Percent => Some(BinaryOp::Mod),
            _ => None,
        } {
            self.advance();
            let right = self.unary();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn unary(&self) -> Expr {
        if let Some(op) = match self.peek() {
            TokenType::Not => Some(UnaryOp::Not),
            TokenType::Minus => Some(UnaryOp::Neg),
            _ => None,
        } {
            self.advance();
            let right = self.unary();
            return Expr::Unary(Box::new(UnaryExpr { op, right }));
        }
        self.exponentiation()
    }

    fn exponentiation(&self) -> Expr {
        let mut left = self.primary();
        while let Some(op) = match self.peek() {
            TokenType::Caret => Some(BinaryOp::Pow),
            _ => None,
        } {
            self.advance();
            let right = self.primary();
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }))
        }
        left
    }

    fn primary(&self) -> Expr {
        if let Some(expr) = match self.peek() {
            TokenType::Identifier(_) => Some(self.identifier()),
            TokenType::Bool(b) => Some(Expr::Literal(Literal::Bool(*b))),
            TokenType::Float(n) => Some(Expr::Literal(Literal::Float(*n))),
            TokenType::Int(n) => Some(Expr::Literal(Literal::Int(*n))),
            TokenType::LeftParen => {
                self.advance();
                let expr = self.expression();
                if self.peek() == &TokenType::RightParen {
                    Some(Expr::Grouping(Box::new(expr)))
                } else {
                    None
                }
            }
            TokenType::LeftBrace => {
                self.advance();
                let mut elems = Vec::new();
                loop {
                    elems.push(self.expression());
                    match self.peek() {
                        TokenType::Comma => self.advance(), // skip comma
                        TokenType::RightBrace => break,     // advanced in identifier
                        _ => return Expr::Error,
                    }
                }
                Some(Expr::Array(elems))
            }
            _ => None,
        } {
            self.advance();
            expr
        } else {
            self.advance();
            Expr::Error
        }
    }

    fn identifier(&self) -> Expr {
        let id;

        if let TokenType::Identifier(s) = self.peek() {
            id = s.clone();
        } else {
            return Expr::Error;
        }

        // function call()
        if self.peek_next() == &TokenType::LeftParen {
            self.advance(); // skip identifier
            self.advance(); // skip left parenthesis

            let mut args = Vec::new();
            loop {
                args.push(self.expression());
                match self.peek() {
                    TokenType::Comma => self.advance(), // skip comma
                    TokenType::RightParen => break,     // advanced in identifier
                    _ => return Expr::Error,
                }
            }

            return Expr::Call(id, args);
        }

        let mut id = Expr::Identifier(id);

        // match index[]
        if &TokenType::LeftBracket == self.peek_next() {
            self.advance(); // skip identifier
            self.advance(); // skip left bracket
            let mut idx = Vec::new();
            loop {
                idx.push(self.expression());
                match self.peek() {
                    TokenType::Comma => self.advance(),
                    TokenType::RightBracket => break,
                    _ => return Expr::Error,
                }
            }

            id = match idx.len() {
                1 => Expr::Index(Box::new(id), Box::new(Index::Array1D(idx.remove(0)))),
                2 => Expr::Index(
                    Box::new(id),
                    Box::new(Index::Array2D(idx.remove(0), idx.remove(0))),
                ),
                3 => Expr::Index(
                    Box::new(id),
                    Box::new(Index::Array3D(idx.remove(0), idx.remove(0), idx.remove(0))),
                ),
                4 => Expr::Index(
                    Box::new(id),
                    Box::new(Index::Array4D(
                        idx.remove(0),
                        idx.remove(0),
                        idx.remove(0),
                        idx.remove(0),
                    )),
                ),
                _ => Expr::Error,
            }
        }

        // match .property access
        while &TokenType::Dot == self.peek_next() {
            self.advance(); // skip identifier
            self.advance(); // skip dot
            if let TokenType::Identifier(s) = self.peek() {
                id = match s.as_ref() {
                    "SRGB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::SRGB)))
                    }
                    "LRGB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::LRGB)))
                    }
                    "XYZ" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::XYZ)))
                    }
                    "LAB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::LAB)))
                    }
                    "LCH" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::LCH)))
                    }
                    "Y" => Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Y))),
                    "L" => Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::L))),
                    "r" => Expr::Index(Box::new(id), Box::new(Index::Vec(0))),
                    "g" => Expr::Index(Box::new(id), Box::new(Index::Vec(1))),
                    "b" => Expr::Index(Box::new(id), Box::new(Index::Vec(2))),
                    "x" => Expr::Index(Box::new(id), Box::new(Index::Vec(0))), // also buffer size x
                    "y" => Expr::Index(Box::new(id), Box::new(Index::Vec(1))), // also buffer size y
                    "z" => Expr::Index(Box::new(id), Box::new(Index::Vec(2))), // also buffer size z
                    "l" => Expr::Index(Box::new(id), Box::new(Index::Vec(0))),
                    "a" => Expr::Index(Box::new(id), Box::new(Index::Vec(1))),
                    "c" => Expr::Index(Box::new(id), Box::new(Index::Vec(1))),
                    "h" => Expr::Index(Box::new(id), Box::new(Index::Vec(2))),

                    // property access
                    "int" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Int))), // cast to int* before access
                    "idx" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Idx))), // returns buffer's linear index
                    "ptr" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Ptr))), // returns ptr at origin or index
                    "intptr" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::IntPtr))), // returns ptr at origin or index
                    _ => Expr::Error,
                }
            } else {
                id = Expr::Error;
            }
        }

        id
    }
}
