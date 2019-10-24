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

use std::fs::File;
use std::io::Read;
use std::process;

mod ast;
mod generator;
mod inference;
mod parser;
mod scanner;
mod scope;
mod tokens;

use generator::Generator;
use parser::Parser;
use scanner::Scanner;

use ast::ColorSpace;
use inference::VarType;

fn buf_xyz(x: u64, y: u64, z: u64) -> VarType {
    VarType::Buffer {
        x,
        y,
        z,
        sx: 1,
        sy: x,
        sz: x * y,
        cs: ColorSpace::XYZ,
    }
}

fn buf_y(x: u64, y: u64) -> VarType {
    VarType::Buffer {
        x,
        y,
        z: 1,
        sx: 1,
        sy: x,
        sz: x * y,
        cs: ColorSpace::Y,
    }
}

fn main() {
    // load source
    let file = String::from("bcs.ivy");
    let mut source = String::new();
    if let Ok(mut f) = File::open(file.clone()) {
        f.read_to_string(&mut source).expect("Failed to read file");
    } else {
        let file = String::from("ivyscript/") + &file.clone();
        if let Ok(mut f) = File::open(file) {
            f.read_to_string(&mut source).expect("Failed to read file");
        } else {
            process::exit(-1);
        }
    }

    let mut scanner = Scanner::new(source);
    let tokens = scanner.scan();

    let parser = Parser::new(tokens);
    let ast = parser.parse();

    dbg!(&ast);

    let generator = Generator::new(ast);
    generator.prepare();
    if let Some(k) = generator.kernel(
        "BCS",
        &vec![
            buf_xyz(640, 480, 3),
            buf_y(640, 480),
            buf_y(640, 480),
            buf_y(640, 480),
            buf_xyz(640, 480, 3),
        ],
    ) {
        println!("{}", k);
    }

    /*
    let stmt = stmt
        .into_iter()
        .filter(|x| {
            if let ast::Stmt::VarAssign(_, _) = x {
                true
            } else {
                false
            }
        })
        .collect::<Vec<ast::Stmt>>();
    // */

    /*
    let kernel = String::from("bilateral");
    let args = vec![
        VarType::Buffer {
            x: 40,
            y: 30,
            z: 3,
            sx: 1,
            sy: 40,
            sz: 40 * 30,
            cs: ColorSpace::XYZ,
        },
        VarType::Buffer {
            x: 1,
            y: 1,
            z: 1,
            sx: 1,
            sy: 1,
            sz: 1,
            cs: ColorSpace::Y,
        },
        VarType::Buffer {
            x: 40,
            y: 30,
            z: 1,
            sx: 1,
            sy: 40,
            sz: 40 * 30,
            cs: ColorSpace::Y,
        },
        VarType::Buffer {
            x: 40,
            y: 30,
            z: 3,
            sx: 1,
            sy: 40,
            sz: 40 * 30,
            cs: ColorSpace::XYZ,
        },
    ];

    let generator = Generator::new(&ast);
    let s = generator.kernel(&kernel, &args);

    */
}
