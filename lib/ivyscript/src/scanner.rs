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
use crate::tokens::Token;
use crate::tokens::TokenType;

pub struct Scanner {
    source: Vec<char>,

    start: usize,
    current: usize,
    line: usize,
    line_start: usize, // starting character of current line
}

impl Scanner {
    pub fn new(source: String) -> Scanner {
        Scanner {
            source: source.chars().collect(),
            start: 0,
            current: 0,
            line: 0,
            line_start: 0,
        }
    }

    fn is_at_end(&self) -> bool {
        self.current >= self.source.len()
    }

    pub fn scan(&mut self) -> Result<Vec<Token>, (String, usize)> {
        let mut tokens = Vec::<Token>::new();

        while !self.is_at_end() {
            self.start = self.current;
            self.scan_token(&mut tokens)?;
        }

        tokens.push(Token {
            token: TokenType::EOF,
            fragment: Fragment {
                line: self.line + 1,
                position: self.start - self.line_start + 1,
                lexeme: String::from("[End of file]"),
            },
        });

        Ok(tokens)
    }

    fn advance(&mut self) -> char {
        self.current += 1;
        self.source[self.current - 1]
    }

    fn match_advance(&mut self, expected: char) -> bool {
        if self.is_at_end() {
            return false;
        }
        if self.source[self.current] != expected {
            false
        } else {
            self.current += 1;
            true
        }
    }

    fn peek(&self) -> char {
        if self.is_at_end() {
            '\0'
        } else {
            self.source[self.current]
        }
    }

    fn peek_next(&self) -> char {
        if self.current + 1 >= self.source.len() {
            '\0'
        } else {
            self.source[self.current + 1]
        }
    }

    fn match_number(&mut self) -> Result<TokenType, (String, usize)> {
        let line = self.line;
        while self.peek().is_digit(10) {
            self.advance();
        }

        if self.peek() == '.' && self.peek_next().is_digit(10) {
            self.advance();

            while self.peek().is_digit(10) {
                self.advance();
            }

            let value = self.source[self.start..self.current]
                .iter()
                .collect::<String>();
            if let Ok(value) = value.parse::<f32>() {
                Ok(TokenType::Float(value))
            } else {
                Err((
                    format!("Unable to parse as floating point literal: '{}'", value),
                    line,
                ))
            }
        } else {
            let value = self.source[self.start..self.current]
                .iter()
                .collect::<String>();
            if let Ok(value) = value.parse::<i32>() {
                Ok(TokenType::Int(value))
            } else {
                Err((
                    format!("Unable to parse as integer literal: '{}'", value),
                    line,
                ))
            }
        }
    }

    fn match_identifier(&mut self) -> TokenType {
        while self.peek().is_alphanumeric() || self.peek() == '_' {
            self.advance();
        }

        let value = self.source[self.start..self.current]
            .iter()
            .collect::<String>();

        // match keywords
        match value.as_ref() {
            "and" => TokenType::And,
            "or" => TokenType::Or,
            "not" => TokenType::Not,

            "if" => TokenType::If,
            "then" => TokenType::Then,
            "else" => TokenType::Else,
            "elseif" => TokenType::ElseIf,

            "for" => TokenType::For,
            "while" => TokenType::While,
            "do" => TokenType::Do,

            "false" => TokenType::Bool(false),
            "true" => TokenType::Bool(true),

            "function" => TokenType::Function,
            "kernel" => TokenType::Kernel,
            "return" => TokenType::Return,
            "continue" => TokenType::Continue,
            "break" => TokenType::Break,

            "end" => TokenType::End,

            "var" => TokenType::Var,
            "const" => TokenType::Const,

            v => TokenType::Identifier(String::from(v)),
        }
    }

    fn scan_token(&mut self, tokens: &mut Vec<Token>) -> Result<(), (String, usize)> {
        let token = match self.advance() {
            '(' => TokenType::LeftParen,
            ')' => TokenType::RightParen,
            '{' => TokenType::LeftBrace,
            '}' => TokenType::RightBrace,
            '[' => TokenType::LeftBracket,
            ']' => TokenType::RightBracket,
            ',' => TokenType::Comma,
            '.' => TokenType::Dot,
            '-' => {
                if self.match_advance('-') {
                    // handle comments
                    let start = self.current;
                    while self.peek() != '\n' && !self.is_at_end() {
                        self.advance();
                    }

                    let comment = self.source[start..self.current].iter().collect::<String>();
                    TokenType::Comment(comment)
                } else if self.match_advance('=') {
                    TokenType::MinusEqual
                } else {
                    TokenType::Minus
                }
            }
            '+' => {
                if self.match_advance('=') {
                    TokenType::PlusEqual
                } else {
                    TokenType::Plus
                }
            }
            '/' => {
                if self.match_advance('=') {
                    TokenType::SlashEqual
                } else {
                    TokenType::Slash
                }
            }
            '*' => {
                if self.match_advance('=') {
                    TokenType::StarEqual
                } else {
                    TokenType::Star
                }
            }
            '^' => {
                if self.match_advance('=') {
                    TokenType::CaretEqual
                } else {
                    TokenType::Caret
                }
            }
            '%' => {
                if self.match_advance('=') {
                    TokenType::PercentEqual
                } else {
                    TokenType::Percent
                }
            }
            '!' => {
                if self.match_advance('=') {
                    TokenType::NotEqual
                } else {
                    TokenType::Not
                }
            }
            '~' => {
                if self.match_advance('=') {
                    TokenType::NotEqual
                } else {
                    TokenType::Not
                }
            }
            '=' => {
                if self.match_advance('=') {
                    TokenType::EqualEqual
                } else {
                    TokenType::Equal
                }
            }
            '<' => {
                if self.match_advance('=') {
                    TokenType::LessEqual
                } else {
                    TokenType::Less
                }
            }
            '>' => {
                if self.match_advance('=') {
                    TokenType::GreaterEqual
                } else {
                    TokenType::Greater
                }
            }
            ' ' | '\r' | '\t' => return Ok(()), // skip
            '\n' => {
                self.line += 1;
                self.line_start = self.current;
                return Ok(()); // skip
            }
            c if c.is_digit(10) => self.match_number()?,
            c if c.is_alphabetic() => self.match_identifier(),
            c => {
                return Err((format!("Invalid character: '{}'", c), self.line));
            }
        };

        let lexeme = self.source[self.start..self.current]
            .iter()
            .collect::<String>();

        tokens.push(Token {
            token,
            fragment: Fragment {
                line: self.line + 1,
                position: self.start - self.line_start + 1,
                lexeme,
            },
        });

        Ok(())
    }
}
