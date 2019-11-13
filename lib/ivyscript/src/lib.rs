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

extern crate libc;

use libc::c_char;
use std::ffi::{CStr, CString};

mod ast;
mod buf_idx;
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
use parser::Parser;
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

// create new generator with source file:
#[no_mangle]
pub extern "C" fn translator_new_ocl<'a>(source: *const c_char) -> *mut Translator<'a> {
    let source = unsafe {
        assert!(!source.is_null());
        CStr::from_ptr(source)
    };
    let mut scanner = Scanner::new(source.to_str().unwrap_or("").to_string());
    let tokens = scanner.scan();

    let parser = Parser::new(tokens);
    let ast = parser.parse();

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
        Generator::Ispc(g) => g.prepare(),
    }

    ptr
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
pub extern "C" fn translator_generate(t: *mut Translator, kernel: *const c_char) -> *mut c_char {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    let kernel = unsafe {
        assert!(!kernel.is_null());
        CStr::from_ptr(kernel)
    };
    let kernel = kernel.to_str().unwrap_or("");

    let source = match &t.generator {
        Generator::Ocl(g) => g.kernel(kernel, &t.inputs),
        Generator::Ispc(g) => g.kernel(kernel, &t.inputs),
    };

    if let Some(ocl) = source {
        CString::new(ocl).unwrap().into_raw()
    } else {
        CString::new("").unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn translator_get_id(t: *mut Translator, name: *const c_char) -> *mut c_char {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    let name = unsafe {
        assert!(!name.is_null());
        CStr::from_ptr(name)
    };

    CString::new(function_id(name.to_str().unwrap_or(""), &t.inputs))
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
pub extern "C" fn translator_add_buffer_srgb(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::SRGB,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lrgb(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::LRGB,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_xyz(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::XYZ,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lab(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::LAB,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_lch(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::LCH,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_y(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::Y,
    });
    t.inputs.len() as u64
}

#[no_mangle]
pub extern "C" fn translator_add_buffer_l(
    t: *mut Translator,
    x: u64,
    y: u64,
    z: u64,
    sx: u64,
    sy: u64,
    sz: u64,
) -> u64 {
    let t = unsafe {
        assert!(!t.is_null());
        &mut *t
    };
    t.inputs.push(VarType::Buffer {
        x,
        y,
        z,
        sx,
        sy,
        sz,
        cs: ColorSpace::L,
    });
    t.inputs.len() as u64
}
