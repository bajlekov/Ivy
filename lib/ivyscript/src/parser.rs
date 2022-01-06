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

use std::cell::Cell;

use crate::ast::{
    AssignOp, BinaryExpr, BinaryOp, ColorSpace, Cond, Expr, Index, Literal, Prop, Stmt, UnaryExpr,
    UnaryOp,
};

use crate::tokens::{Token, TokenType};

pub struct ParseError {
    pub error: String,
    pub line: usize,
}

struct VarDecl {
    id: String,
    expr: Expr,
}
struct IfBranch {
    cond_list: Vec<Cond>,
    else_body: Vec<Stmt>,
}
struct WhileLoop {
    cond: Expr,
    body: Vec<Stmt>,
}
struct ForLoop {
    var: String,
    from: Expr,
    to: Expr,
    step: Option<Expr>,
    body: Vec<Stmt>,
}
struct FunDecl {
    id: String,
    args: Vec<String>,
    body: Vec<Stmt>,
}

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

    pub fn parse(&self) -> Result<Vec<Stmt>, ParseError> {
        let mut stmts = Vec::new();
        while self.current.get().is_some() {
            stmts.push(self.statement()?.0);
        }
        Ok(stmts)
    }

    fn advance(&self) {
        let current = match self.current.get() {
            Some(n) if n < self.tokens.len() => Some(n + 1),
            _ => None,
        };
        self.current.set(current);
    }

    fn peek(&self) -> &TokenType {
        self.current
            .get()
            .map_or(&TokenType::Eof, |current| match &self.tokens.get(current) {
                Some(token) => &token.token,
                None => &TokenType::Eof,
            })
    }

    fn peek_next(&self) -> &TokenType {
        self.current.get().map_or(&TokenType::Eof, |current| {
            if current + 1 < self.tokens.len() {
                &self.tokens[current + 1].token
            } else {
                &TokenType::Eof
            }
        })
    }

    fn line(&self) -> usize {
        if let Some(current) = self.current.get() {
            match &self.tokens.get(current) {
                Some(token) => {
                    return token.fragment.line;
                }
                None => {}
            }
        }

        self.tokens
            .iter()
            .last()
            .map_or(0, |last| last.fragment.line)
    }

    fn var_decl(&self) -> Result<VarDecl, ParseError> {
        let line = self.line();
        self.advance(); // skip var
        if let TokenType::Identifier(id) = self.peek() {
            self.advance(); // skip identifier
            if &TokenType::Equal == self.peek() {
                self.advance(); // skip =
                Ok(VarDecl {
                    id: id.clone(),
                    expr: self.expression()?.0,
                })
            } else {
                Err(ParseError {
                    error: format!("Missing initial value assignment to {}", id),
                    line,
                })
            }
        } else {
            Err(ParseError {
                error: "Missing identifier".into(),
                line,
            })
        }
    }

    fn if_branch(&self) -> Result<IfBranch, ParseError> {
        let mut cond_list = Vec::new();
        let mut else_body = Vec::new();

        self.advance(); // skip if
        let (cond, _) = self.expression()?;
        let mut body = Vec::new();
        if self.peek() == &TokenType::Then {
            self.advance(); // skip optional then
        }
        loop {
            match self.peek() {
                TokenType::ElseIf | TokenType::Else | TokenType::End => break,
                _ => {}
            }

            match self.statement()? {
                (Stmt::Eof, line) => {
                    return Err(ParseError {
                        error: "Unexpected end of file in 'if' body".into(),
                        line,
                    })
                }
                (stmt, _) => body.push(stmt),
            }
        }
        cond_list.push(Cond { cond, body });

        while self.peek() == &TokenType::ElseIf {
            self.advance(); // skip elseIf
            let (cond, _) = self.expression()?;
            let mut body = Vec::new();
            if self.peek() == &TokenType::Then {
                self.advance(); // skip optional then
            }
            loop {
                match self.peek() {
                    TokenType::ElseIf => continue,
                    TokenType::Else | TokenType::End => break,
                    _ => {}
                }

                match self.statement()? {
                    (Stmt::Eof, line) => {
                        return Err(ParseError {
                            error: "Unexpected end of file in 'elseif' body".into(),
                            line,
                        })
                    }
                    (stmt, _) => body.push(stmt),
                }
            }
            cond_list.push(Cond { cond, body });
        }

        if self.peek() == &TokenType::Else {
            self.advance(); // skip else
            loop {
                if self.peek() == &TokenType::End {
                    break;
                }

                match self.statement()? {
                    (Stmt::Eof, line) => {
                        return Err(ParseError {
                            error: "Unexpected end of file in 'else' body".into(),
                            line,
                        })
                    }
                    (stmt, _) => else_body.push(stmt),
                }
            }
        }

        self.advance(); // skip end
        Ok(IfBranch {
            cond_list,
            else_body,
        })
    }

    fn while_loop(&self) -> Result<WhileLoop, ParseError> {
        self.advance(); // skip while

        let (cond, _) = self.expression()?;

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
            match self.statement()? {
                (Stmt::Eof, line) => {
                    return Err(ParseError {
                        error: "Unexpected end of file in 'while' loop body".into(),
                        line,
                    })
                }
                (stmt, _) => body.push(stmt),
            }
        }

        Ok(WhileLoop { cond, body })
    }

    fn for_loop(&self) -> Result<ForLoop, ParseError> {
        let line = self.line();
        self.advance(); // skip for

        let var;
        if let TokenType::Identifier(name) = self.peek() {
            var = name.clone();
            self.advance(); // skip identifier
        } else {
            return Err(ParseError {
                error: "Missing for loop variable".into(),
                line,
            });
        }

        if self.peek() != &TokenType::Equal {
            return Err(ParseError {
                error: "Missing for loop range assignment".into(),
                line,
            });
        }
        self.advance(); // skip =

        let (from, _) = self.expression()?;

        if self.peek() != &TokenType::Comma {
            return Err(ParseError {
                error: "Expected ',' in loop range".into(),
                line,
            });
        }
        self.advance(); // skip ,

        let (to, _) = self.expression()?;

        let step;
        if self.peek() == &TokenType::Comma {
            self.advance(); // skip comma
            step = Some(self.expression()?.0);
        } else {
            step = None;
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
            match self.statement()? {
                (Stmt::Eof, line) => {
                    return Err(ParseError {
                        error: "Unexpected end of file in 'for' loop body".into(),
                        line,
                    })
                }
                (stmt, _) => body.push(stmt),
            }
        }

        Ok(ForLoop {
            var,
            from,
            to,
            step,
            body,
        })
    }

    fn fun_decl(&self) -> Result<FunDecl, ParseError> {
        let line = self.line();
        self.advance(); // skip fun

        let id;
        if let TokenType::Identifier(name) = self.peek() {
            id = name.clone();
            self.advance(); // skip identifier
        } else {
            return Err(ParseError {
                error: "Missing function declaration idetifier".into(),
                line,
            });
        }

        // get arguments
        if self.peek() == &TokenType::LeftParen {
            self.advance(); // skip left parenthesis

            let mut args = Vec::new();
            loop {
                match self.peek() {
                    TokenType::Identifier(name) => {
                        args.push(name.clone());
                    }
                    TokenType::RightParen => break,
                    _ => return Err(ParseError{ error: "Expected argument identifier or ')' in function declaration argument list"
                            .into(),
                        line,
                    }),
                }
                self.advance();
                match self.peek() {
                    TokenType::Comma => self.advance(), // skip comma
                    TokenType::RightParen => break,
                    _ => {
                        return Err(ParseError {
                            error: "Expected ',' or ')' in function declaration argument list"
                                .into(),
                            line,
                        })
                    }
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
                match self.statement()? {
                    (Stmt::Eof, line) => {
                        return Err(ParseError {
                            error: "Unexpected end of file in function declaration body".into(),
                            line,
                        })
                    }
                    (stmt, _) => body.push(stmt),
                }
            }

            Ok(FunDecl { id, args, body })
        } else {
            Err(ParseError {
                error: "Expected argument list in function declaration".into(),
                line,
            })
        }
    }

    fn fun_return(&self) -> Result<(Option<Expr>, usize), ParseError> {
        let line = self.line();
        self.advance(); // skip return

        let (expr, _) = match self.peek() {
            TokenType::End | TokenType::Else | TokenType::ElseIf => return Ok((None, line)),
            _ => self.expression()?,
        };

        match self.peek() {
            TokenType::End | TokenType::Else | TokenType::ElseIf => Ok((Some(expr), line)),
            _ => Err(ParseError {
                error: "Expected end of body after return statement".into(),
                line,
            }),
        }
    }

    fn statement(&self) -> Result<(Stmt, usize), ParseError> {
        let line = self.line();
        let stmt = match self.peek() {
            TokenType::Var => {
                let VarDecl { id, expr } = self.var_decl()?;
                Stmt::Var(id, expr)
            }

            TokenType::Const => {
                let VarDecl { id, expr } = self.var_decl()?;
                Stmt::Const(id, expr)
            }

            TokenType::Function => {
                let FunDecl { id, args, body } = self.fun_decl()?;
                Stmt::Function { id, args, body }
            }

            TokenType::Kernel => {
                let FunDecl { id, args, body } = self.fun_decl()?;
                Stmt::Kernel { id, args, body }
            }

            TokenType::Return => match self.fun_return()? {
                (Some(expr), _) => Stmt::Return(Some(expr)),
                (None, _) => Stmt::Return(None),
            },

            TokenType::Continue => match self.fun_return()? {
                (None, _) => Stmt::Continue,
                (_, line) => {
                    return Err(ParseError {
                        error: "Expected end of body after continue statement".into(),
                        line,
                    })
                }
            },

            TokenType::Break => match self.fun_return()? {
                (None, _) => Stmt::Break,
                (_, line) => {
                    return Err(ParseError {
                        error: "Expected end of body after break statement".into(),
                        line,
                    })
                }
            },

            TokenType::If => {
                let IfBranch {
                    cond_list,
                    else_body,
                } = self.if_branch()?;
                Stmt::IfElse {
                    cond_list,
                    else_body,
                }
            }

            TokenType::While => {
                let WhileLoop { cond, body } = self.while_loop()?;
                Stmt::While { cond, body }
            }

            TokenType::For => {
                let ForLoop {
                    var,
                    from,
                    to,
                    step,
                    body,
                } = self.for_loop()?;
                Stmt::For {
                    var,
                    from,
                    to,
                    step,
                    body,
                }
            }

            TokenType::Identifier(id_str) if self.peek_next() == &TokenType::LeftParen => {
                self.advance(); // skip identifier
                self.advance(); // skip left parenthesis

                let mut args = Vec::new();
                loop {
                    args.push(self.expression()?.0);
                    match self.peek() {
                        TokenType::Comma => self.advance(),
                        TokenType::RightParen => {
                            self.advance();
                            break;
                        }
                        _ => {
                            return Err(ParseError {
                                error: "Expected ',' or ')' in function call argument list".into(),
                                line,
                            })
                        }
                    }
                }

                Stmt::Call(id_str.clone(), args)
            }

            TokenType::Identifier(id_str) => {
                let (id, line) = self.identifier()?;
                self.advance();

                // match equal sign
                let token = self.peek();
                self.advance();
                let (expr, _) = self.expression()?;

                match token {
                    TokenType::Equal => Stmt::Assign(id, expr),
                    TokenType::PlusEqual => Stmt::AssignOp(id, AssignOp::Add, expr),
                    TokenType::MinusEqual => Stmt::AssignOp(id, AssignOp::Sub, expr),
                    TokenType::SlashEqual => Stmt::AssignOp(id, AssignOp::Div, expr),
                    TokenType::StarEqual => Stmt::AssignOp(id, AssignOp::Mul, expr),
                    TokenType::PercentEqual => Stmt::AssignOp(id, AssignOp::Mod, expr),
                    TokenType::CaretEqual => Stmt::AssignOp(id, AssignOp::Pow, expr),
                    _ => {
                        return Err(ParseError {
                            error: format!(
                                "Expected assignment to or call of identifier {}",
                                id_str
                            ),
                            line,
                        })
                    }
                }
            }

            TokenType::Comment(comment) => {
                self.advance();
                Stmt::Comment(comment.clone())
            }
            TokenType::Eof => {
                self.advance();
                Stmt::Eof
            }
            _ => {
                return Err(ParseError {
                    error: "Unable to parse statement".into(),
                    line: self.line(),
                });
            }
        };

        Ok((stmt, line))
    }

    fn expression(&self) -> Result<(Expr, usize), ParseError> {
        self.logic_or()
    }

    fn logic_or(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.logic_and()?;
        while let Some(op) = match self.peek() {
            TokenType::Or => Some(BinaryOp::Or),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.logic_and()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn logic_and(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.equality()?;
        while let Some(op) = match self.peek() {
            TokenType::And => Some(BinaryOp::And),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.equality()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn equality(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.comparison()?;
        while let Some(op) = match self.peek() {
            TokenType::NotEqual => Some(BinaryOp::NotEqual),
            TokenType::EqualEqual => Some(BinaryOp::Equal),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.comparison()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn comparison(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.addition()?;
        while let Some(op) = match self.peek() {
            TokenType::Greater => Some(BinaryOp::Greater),
            TokenType::GreaterEqual => Some(BinaryOp::GreaterEqual),
            TokenType::Less => Some(BinaryOp::Less),
            TokenType::LessEqual => Some(BinaryOp::LessEqual),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.addition()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn addition(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.multiplication()?;
        while let Some(op) = match self.peek() {
            TokenType::Minus => Some(BinaryOp::Sub),
            TokenType::Plus => Some(BinaryOp::Add),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.multiplication()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn multiplication(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.unary()?;
        while let Some(op) = match self.peek() {
            TokenType::Slash => Some(BinaryOp::Div),
            TokenType::BackSlash => Some(BinaryOp::DivInt),
            TokenType::Star => Some(BinaryOp::Mul),
            TokenType::Percent => Some(BinaryOp::Mod),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.unary()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn unary(&self) -> Result<(Expr, usize), ParseError> {
        if let Some(op) = match self.peek() {
            TokenType::Not => Some(UnaryOp::Not),
            TokenType::Minus => Some(UnaryOp::Neg),
            _ => None,
        } {
            self.advance();
            let (right, line) = self.unary()?;
            Ok((Expr::Unary(Box::new(UnaryExpr { op, right })), line))
        } else {
            self.exponentiation()
        }
    }

    fn exponentiation(&self) -> Result<(Expr, usize), ParseError> {
        let (mut left, line) = self.primary()?;
        while let Some(op) = match self.peek() {
            TokenType::Caret => Some(BinaryOp::Pow),
            _ => None,
        } {
            self.advance();
            let (right, _) = self.primary()?;
            left = Expr::Binary(Box::new(BinaryExpr { left, op, right }));
        }
        Ok((left, line))
    }

    fn primary(&self) -> Result<(Expr, usize), ParseError> {
        let line = self.line();
        let expr = match self.peek() {
            TokenType::Identifier(_) => self.identifier()?.0,
            TokenType::Bool(val) => Expr::Literal(Literal::Bool(*val)),
            TokenType::Float(val) => Expr::Literal(Literal::Float(*val)),
            TokenType::Int(val) => Expr::Literal(Literal::Int(*val)),
            TokenType::LeftParen => {
                self.advance();
                let (expr, _) = self.expression()?;
                if self.peek() == &TokenType::RightParen {
                    Expr::Grouping(Box::new(expr))
                } else {
                    return Err(ParseError {
                        error: "Invalid sub-expression".into(),
                        line,
                    });
                }
            }
            TokenType::LeftBrace => {
                self.advance();
                let mut elems = Vec::new();
                loop {
                    elems.push(self.expression()?.0);
                    match self.peek() {
                        TokenType::Comma => self.advance(), // skip comma
                        TokenType::RightBrace => break,     // advanced in identifier
                        _ => {
                            return Err(ParseError {
                                error: "Expected ',' or '}}' in array list".into(),
                                line,
                            })
                        }
                    }
                }
                Expr::Array(elems)
            }
            _ => {
                return Err(ParseError {
                    error: "Invalid expression".into(),
                    line,
                })
            }
        };

        self.advance();
        Ok((expr, line))
    }

    fn identifier(&self) -> Result<(Expr, usize), ParseError> {
        let line = self.line();
        let id;

        if let TokenType::Identifier(name) = self.peek() {
            id = name.clone();
        } else {
            return Err(ParseError {
                error: "Missing identifier".into(),
                line,
            });
        }

        // function call()
        if self.peek_next() == &TokenType::LeftParen {
            self.advance(); // skip identifier
            self.advance(); // skip left parenthesis

            let mut args = Vec::new();
            loop {
                args.push(self.expression()?.0);
                match self.peek() {
                    TokenType::Comma => self.advance(), // skip comma
                    TokenType::RightParen => break,     // advanced in identifier
                    _ => {
                        return Err(ParseError {
                            error: "Expected ',' or ')' in function call argument list".into(),
                            line,
                        })
                    }
                }
            }

            return Ok((Expr::Call(id, args), line));
        }

        let mut id = Expr::Identifier(id);

        // match index[]
        if &TokenType::LeftBracket == self.peek_next() {
            self.advance(); // skip identifier
            self.advance(); // skip left bracket
            let mut idx = Vec::new();
            loop {
                idx.push(self.expression()?.0);
                match self.peek() {
                    TokenType::Comma => self.advance(),
                    TokenType::RightBracket => break,
                    _ => {
                        return Err(ParseError {
                            error: "Expected ',' or ']' in index list".into(),
                            line,
                        })
                    }
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
                _ => {
                    return Err(ParseError {
                        error: "Invalid index count in index list".into(),
                        line,
                    })
                }
            }
        }

        // match .property access
        while &TokenType::Dot == self.peek_next() {
            self.advance(); // skip identifier
            self.advance(); // skip dot
            if let TokenType::Identifier(name) = self.peek() {
                id = match name.as_ref() {
                    "SRGB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Srgb)))
                    }
                    "LRGB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Lrgb)))
                    }
                    "XYZ" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Xyz)))
                    }
                    "LAB" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Lab)))
                    }
                    "LCH" => {
                        Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Lch)))
                    }
                    "Y" => Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::Y))),
                    "L" => Expr::Index(Box::new(id), Box::new(Index::ColorSpace(ColorSpace::L))),
                    "x" | "r" | "l" => Expr::Index(Box::new(id), Box::new(Index::Vec(0))), // also buffer size x
                    "y" | "g" | "a" | "c" => Expr::Index(Box::new(id), Box::new(Index::Vec(1))), // also buffer size y
                    "z" | "b" | "h" => Expr::Index(Box::new(id), Box::new(Index::Vec(2))), // also buffer size z

                    // property access
                    "int" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Int))), // cast to int* before access
                    "idx" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Idx))), // returns buffer's linear index
                    "ptr" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::Ptr))), // returns ptr at origin or index
                    "intptr" => Expr::Index(Box::new(id), Box::new(Index::Prop(Prop::IntPtr))), // returns ptr at origin or index
                    _ => {
                        return Err(ParseError {
                            error:
                                "Invalid property, channel selection or color space transformation"
                                    .into(),
                            line,
                        })
                    }
                }
            } else {
                return Err(ParseError {
                    error: "Invalid '.' syntax, expected identifier".into(),
                    line,
                });
            }
        }

        Ok((id, line))
    }
}
