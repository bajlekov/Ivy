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

use crate::fragment::Fragment;

#[derive(Debug, PartialEq)]
pub enum TokenType {
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    Comma,
    Dot,

    Minus,
    Plus,
    Slash,
    Star,
    Percent,
    Caret,

    MinusEqual,
    PlusEqual,
    SlashEqual,
    StarEqual,
    PercentEqual,
    CaretEqual,

    Equal,
    NotEqual,
    EqualEqual,
    Greater,
    GreaterEqual,
    Less,
    LessEqual,

    Identifier(String),
    Float(f32),
    Int(i32),
    Bool(bool),

    And,
    Or,
    Not,

    If,
    Then, // optional
    Else,
    ElseIf,

    For,
    While,
    Do, // optional + scopes

    Function,
    Kernel,
    Return,
    Continue,
    Break,

    End,

    Var,
    Const,

    Comment(String),
    EOF,
}

#[derive(Debug)]
pub struct Token {
    pub token: TokenType,
    pub fragment: Fragment,
}
