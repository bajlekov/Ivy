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
#![allow(clippy::many_single_char_names)]
#![allow(clippy::type_complexity)]

use std::ffi::{CStr, CString};

mod ast;
mod buf_idx;
mod fragment;
mod function_id;
//mod generator_ispc;
mod generator_ocl;
mod inference;
mod parser;
mod scanner;
mod scope;
mod tokens;

use function_id::function_id;
//use generator_ispc::Generator as GeneratorISPC;
use generator_ocl::Generator as GeneratorOCL;
use parser::Parser;
use scanner::Scanner;

use ast::ColorSpace;
use inference::VarType;

pub enum Generator<'a> {
    Ocl(GeneratorOCL<'a>),
    //Ispc(GeneratorISPC<'a>),
}

pub struct Translator<'a> {
    generator: Generator<'a>,
    inputs: Vec<VarType>,
}

// create new generator with source file:
#[no_mangle]
pub extern "C" fn translator_new_ocl<'a>(source: *const i8) -> *mut Translator<'a> {
    let source = unsafe {
        assert!(!source.is_null());
        CStr::from_ptr(source)
    };

    let source = source.to_str().unwrap_or_default().to_string();

    let mut scanner = Scanner::new(source.clone());
    let tokens = scanner.scan();
    if let Err((err, line)) = &tokens {
        println!("[Line {}]: {}", line, err);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(l, s)| {
                println!("{} {}: {}", if l == line { "=>" } else { "  " }, l + 1, s)
            });
    }

    let tokens = tokens.unwrap_or_default();

    let parser = Parser::new(tokens);
    let ast = parser.parse();
    if let Err((err, line)) = &ast {
        println!("[Line {}]: {}", line, err);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(l, s)| {
                println!("{} {}: {}", if l == line { "=>" } else { "  " }, l + 1, s)
            });
    }
    let ast = ast.unwrap_or_default();

    let generator = GeneratorOCL::new(ast);

    let translator = Box::new(Translator {
        generator: Generator::Ocl(generator),
        inputs: Vec::new(),
    });

    let ptr = Box::into_raw(translator);

    let translator = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    match &translator.generator {
        Generator::Ocl(g) => g.prepare(),
        //Generator::Ispc(g) => g.prepare(),
    }

    ptr
}

/*
#[no_mangle]
pub extern "C" fn translator_new_ispc<'a>(source: *const i8) -> *mut Translator<'a> {
    let source = unsafe {
        assert!(!source.is_null());
        CStr::from_ptr(source)
    };

    let source = source.to_str().unwrap_or_default().to_string();

    let mut scanner = Scanner::new(source.clone());
    let tokens = scanner.scan();
    if let Err((err, line)) = &tokens {
        println!("[Line {}]: {}", line, err);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(l, s)| {
                println!("{} {}: {}", if l == line { "=>" } else { "  " }, l + 1, s)
            });
    }
    let tokens = tokens.unwrap_or(Vec::new());

    let parser = Parser::new(tokens);
    let ast = parser.parse();
    if let Err((err, line)) = &ast {
        println!("[Line {}]: {}", line, err);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(l, s)| {
                println!("{} {}: {}", if l == line { "=>" } else { "  " }, l + 1, s)
            });
    }
    let ast = ast.unwrap_or(Vec::new());

    let generator = GeneratorISPC::new(ast);

    let translator = Box::new(Translator {
        generator: Generator::Ispc(generator),
        inputs: Vec::new(),
    });

    let ptr = Box::into_raw(translator);

    let translator = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    match &translator.generator {
        Generator::Ocl(g) => g.prepare(),
        Generator::Ispc(g) => g.prepare(),
    }

    ptr
*/

#[no_mangle]
pub extern "C" fn translator_free(t: *mut Translator) {
    if t.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(t);
    }
}

#[no_mangle]
pub extern "C" fn translator_generate(t: *mut Translator, kernel: *const i8) -> *mut i8 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    let kernel = unsafe {
        assert!(!kernel.is_null());
        CStr::from_ptr(kernel)
    };
    let kernel = kernel.to_str().unwrap_or_default();

    let source = match &t.generator {
        Generator::Ocl(g) => g.kernel(kernel, &t.inputs),
    };

    if let Err(err) = &source {
        println!("[Generator]: {}", err);
    }
    let source = source.unwrap_or_default();

    CString::new(source).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn translator_get_id(t: *mut Translator, name: *const i8) -> *const i8 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    let name = unsafe {
        assert!(!name.is_null());
        CStr::from_ptr(name)
    };

    CString::new(function_id(name.to_str().unwrap_or_default(), &t.inputs))
        .unwrap()
        .into_raw()
}

#[no_mangle]
pub extern "C" fn translator_clear_inputs(t: *mut Translator) {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs = Vec::new();
}

#[no_mangle]
pub extern "C" fn translator_add_int(t: *mut Translator) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Int);
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_float(t: *mut Translator) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Float);
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_srgb(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Srgb,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lrgb(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Lrgb,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_xyz(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Xyz,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lab(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Lab,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lch(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Lch,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_y(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::Y,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_l(t: *mut Translator, x: u64, y: u64, z: u64) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        z,
        cs: ColorSpace::L,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[cfg(test)]
mod test;
