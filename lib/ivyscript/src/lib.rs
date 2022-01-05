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
mod generator_ispc;
mod generator_ocl;
mod inference;
mod parser;
mod scanner;
mod scope;
mod tokens;

use function_id::function_id;
use generator_ispc::Generator as GeneratorISPC;
use generator_ocl::Generator as GeneratorOCL;
use parser::{ParseError, Parser};
use scanner::Scanner;

use ast::ColorSpace;
use inference::VarType;

pub enum Generator<'a> {
    Ocl(GeneratorOCL<'a>),
    Ispc(GeneratorISPC<'a>),
}

pub struct Translator<'a> {
    generator: Generator<'a>,
    inputs: Vec<VarType>,
}

unsafe fn unsafe_cstr<'a>(source: *const i8) -> &'a CStr {
    assert!(!source.is_null());
    CStr::from_ptr(source)
}

// create new generator with source file:
#[no_mangle]
pub extern "C" fn translator_new_ocl<'a>(source: *const i8) -> *mut Translator<'a> {
    let source = unsafe { unsafe_cstr(source) }
        .to_str()
        .unwrap_or_default()
        .to_string();

    let mut scanner = Scanner::new(&source);
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
            .for_each(|(current_line, source)| {
                println!(
                    "{} {}: {}",
                    if current_line == line { "=>" } else { "  " },
                    line + 1,
                    source
                );
            });
    }

    let tokens = tokens.unwrap_or_default();

    let parser = Parser::new(tokens);
    let ast = parser.parse();
    if let Err(ParseError { error, line }) = &ast {
        println!("[Line {}]: {}", line, error);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(current_line, source)| {
                println!(
                    "{} {}: {}",
                    if current_line == line { "=>" } else { "  " },
                    line + 1,
                    source
                );
            });
    }
    let ast = ast.unwrap_or_default();

    let generator = GeneratorOCL::new(ast);

    let translator = Translator {
        generator: Generator::Ocl(generator),
        inputs: Vec::new(),
    };

    Box::into_raw(Box::new(translator))
}

#[no_mangle]
pub extern "C" fn translator_new_ispc<'a>(source: *const i8) -> *mut Translator<'a> {
    let source = unsafe { unsafe_cstr(source) }
        .to_str()
        .unwrap_or_default()
        .to_string();

    let mut scanner = Scanner::new(&source);
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
            .for_each(|(current_line, source)| {
                println!(
                    "{} {}: {}",
                    if current_line == line { "=>" } else { "  " },
                    line + 1,
                    source
                );
            });
    }

    let tokens = tokens.unwrap_or_default();

    let parser = Parser::new(tokens);
    let ast = parser.parse();
    if let Err(ParseError { error, line }) = &ast {
        println!("[Line {}]: {}", line, error);
        let line = line - 1;

        let start = if line >= 3 { line - 3 } else { 0 };
        source
            .lines()
            .enumerate()
            .skip(start)
            .take(7)
            .for_each(|(current_line, source)| {
                println!(
                    "{} {}: {}",
                    if current_line == line { "=>" } else { "  " },
                    line + 1,
                    source
                );
            });
    }
    let ast = ast.unwrap_or_default();

    let generator = GeneratorISPC::new(ast);

    let translator = Translator {
        generator: Generator::Ispc(generator),
        inputs: Vec::new(),
    };

    Box::into_raw(Box::new(translator))
}

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
    let kernel = unsafe { unsafe_cstr(kernel) }.to_str().unwrap_or_default();

    let source = match &t.generator {
        Generator::Ocl(g) => g.kernel(kernel, &t.inputs),
        Generator::Ispc(g) => g.kernel(kernel, &t.inputs),
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
    let name = unsafe { unsafe_cstr(name) }.to_str().unwrap_or_default();

    CString::new(function_id(name, &t.inputs))
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
        z: z as usize,
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
        z: z as usize,
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
        z: z as usize,
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
        z: z as usize,
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
        z: z as usize,
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
        z: z as usize,
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
        z: z as usize,
        cs: ColorSpace::L,
        x1y1: x == 1 && y == 1,
    });
    t.inputs.len() as u64
}

#[cfg(test)]
mod test;
