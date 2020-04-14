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

use crate::tokens::Token;
use crate::tokens::TokenType;

pub struct Scanner {
    source: Vec<char>,

    start: usize,
    current: usize,
    line: usize,
}

impl Scanner {
    pub fn new(source: String) -> Scanner {
        Scanner {
            source: source.chars().collect(),
            start: 0,
            current: 0,
            line: 1,
        }
    }

    fn is_at_end(&self) -> bool {
        self.current >= self.source.len()
    }

    pub fn scan(&mut self) -> Vec<Token> {
        let mut tokens = Vec::<Token>::new();

        while !self.is_at_end() {
            self.start = self.current;
            self.scan_token(&mut tokens);
        }

        tokens.push(Token {
            token: TokenType::EOF,
            lexeme: String::from(""),
            line: self.line,
        });

        tokens
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

    fn match_number(&mut self) -> Option<TokenType> {
        while self.peek().is_digit(10) {
            self.advance();
        }

        if self.peek() == '.' && self.peek_next().is_digit(10) {
            self.advance();

            while self.peek().is_digit(10) {
                self.advance();
            }

            if let Ok(value) = self.source[self.start..self.current]
                .iter()
                .collect::<String>()
                .parse::<f32>()
            {
                Some(TokenType::Float(value))
            } else {
                eprintln!("[line {}] Unable to parse float", self.line);
                None
            }
        } else if let Ok(value) = self.source[self.start..self.current]
            .iter()
            .collect::<String>()
            .parse::<i32>()
        {
            Some(TokenType::Int(value))
        } else {
            eprintln!("[line {}] Unable to parse integer", self.line);
            None
        }
    }

    fn match_identifier(&mut self) -> Option<TokenType> {
        while self.peek().is_alphanumeric() || self.peek() == '_' {
            self.advance();
        }

        let value = self.source[self.start..self.current]
            .iter()
            .collect::<String>();

        // match keywords
        match value.as_ref() {
            "and" => Some(TokenType::And),
            "or" => Some(TokenType::Or),
            "not" => Some(TokenType::Not),

            "if" => Some(TokenType::If),
            "then" => Some(TokenType::Then),
            "else" => Some(TokenType::Else),
            "elseif" => Some(TokenType::ElseIf),

            "for" => Some(TokenType::For),
            "while" => Some(TokenType::While),
            "do" => Some(TokenType::Do),

            "false" => Some(TokenType::Bool(false)),
            "true" => Some(TokenType::Bool(true)),

            "function" => Some(TokenType::Function),
            "kernel" => Some(TokenType::Kernel),
            "return" => Some(TokenType::Return),

            "end" => Some(TokenType::End),

            "var" => Some(TokenType::Var),
            "const" => Some(TokenType::Const),
            "local" => Some(TokenType::Local),

            v => Some(TokenType::Identifier(String::from(v))),
        }
    }

    fn scan_token(&mut self, tokens: &mut Vec<Token>) {
        let token = match self.advance() {
            '(' => Some(TokenType::LeftParen),
            ')' => Some(TokenType::RightParen),
            '{' => Some(TokenType::LeftBrace),
            '}' => Some(TokenType::RightBrace),
            '[' => Some(TokenType::LeftBracket),
            ']' => Some(TokenType::RightBracket),
            ',' => Some(TokenType::Comma),
            '.' => Some(TokenType::Dot),
            '-' => Some(if self.match_advance('-') {
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
            }),
            '+' => Some(if self.match_advance('=') {
                TokenType::PlusEqual
            } else {
                TokenType::Plus
            }),
            '/' => Some(if self.match_advance('=') {
                TokenType::SlashEqual
            } else {
                TokenType::Slash
            }),
            '*' => Some(if self.match_advance('=') {
                TokenType::StarEqual
            } else {
                TokenType::Star
            }),
            '^' => Some(if self.match_advance('=') {
                TokenType::CaretEqual
            } else {
                TokenType::Caret
            }),
            '%' => Some(if self.match_advance('=') {
                TokenType::PercentEqual
            } else {
                TokenType::Percent
            }),
            '!' => {
                if self.match_advance('=') {
                    Some(TokenType::NotEqual)
                } else {
                    None
                }
            }
            '~' => {
                if self.match_advance('=') {
                    Some(TokenType::NotEqual)
                } else {
                    None
                }
            }
            '=' => Some(if self.match_advance('=') {
                TokenType::EqualEqual
            } else {
                TokenType::Equal
            }),
            '<' => Some(if self.match_advance('=') {
                TokenType::LessEqual
            } else {
                TokenType::Less
            }),
            '>' => Some(if self.match_advance('=') {
                TokenType::GreaterEqual
            } else {
                TokenType::Greater
            }),
            ' ' | '\r' | '\t' => None,
            '\n' => {
                self.line += 1;
                None
            }
            c if c.is_digit(10) => self.match_number(),
            c if c.is_alphabetic() => self.match_identifier(),
            c => {
                eprintln!("[line {}] Unexpected character: {}", self.line, c);
                None
            }
        };

        let lexeme = self.source[self.start..self.current]
            .iter()
            .collect::<String>();
        if let Some(t) = token {
            tokens.push(Token {
                token: t,
                lexeme,
                line: self.line,
            });
        }
    }
}
