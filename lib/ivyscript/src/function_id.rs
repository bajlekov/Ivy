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

use crate::ast::ColorSpace;
use crate::inference::VarType;

pub fn function_id(name: &str, input: &[VarType]) -> String {
    let mut id = format!("___{}_", input.len());
    for v in input {
        let s = match v {
            VarType::Bool => String::from("B_"),
            VarType::Int => String::from("I_"),
            VarType::Float => String::from("F_"),
            VarType::Vec => String::from("V_"),
            VarType::BoolArray(n, false, x, y, z, w) => format!("BA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::IntArray(n, false, x, y, z, w) => format!("IA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::FloatArray(n, false, x, y, z, w) => {
                format!("FA{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::VecArray(n, false, x, y, z, w) => format!("VA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::BoolArray(n, true, x, y, z, w) => format!("LBA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::IntArray(n, true, x, y, z, w) => format!("LIA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::FloatArray(n, true, x, y, z, w) => {
                format!("LFA{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::VecArray(n, true, x, y, z, w) => format!("LVA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::Buffer { z, cs } => format!(
                "BUF{}{}_",
                z,
                match cs {
                    ColorSpace::SRGB => "SRGB",
                    ColorSpace::LRGB => "LRGB",
                    ColorSpace::XYZ => "XYZ",
                    ColorSpace::LAB => "LAB",
                    ColorSpace::LCH => "LCH",
                    ColorSpace::Y => "Y",
                    ColorSpace::L => "L",
                }
            ),
            _ => String::from("/*** Error: Unknown type ***/"),
        };
        id.push_str(&s);
    }
    id.push_str("___");
    id.push_str(name);
    id
}
