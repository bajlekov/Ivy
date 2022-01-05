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

use crate::ast::ColorSpace;
use crate::inference::VarType;

pub fn function_id(name: &str, input: &[VarType]) -> String {
    let mut id = format!("___{}_", input.len());
    for var_type in input {
        let out = match var_type {
            VarType::Bool => "B_".into(),
            VarType::Int => "I_".into(),
            VarType::Float => "F_".into(),
            VarType::Vec => "V_".into(),
            VarType::BoolArray(dim, false, i1, i2, i3, i4) => {
                format!("BA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::IntArray(dim, false, i1, i2, i3, i4) => {
                format!("IA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::FloatArray(dim, false, i1, i2, i3, i4) => {
                format!("FA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::VecArray(dim, false, i1, i2, i3, i4) => {
                format!("VA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::BoolArray(dim, true, i1, i2, i3, i4) => {
                format!("LBA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::IntArray(dim, true, i1, i2, i3, i4) => {
                format!("LIA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::FloatArray(dim, true, i1, i2, i3, i4) => {
                format!("LFA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::VecArray(dim, true, i1, i2, i3, i4) => {
                format!("LVA{}_{}_{}_{}_{}_", dim, i1, i2, i3, i4)
            }
            VarType::Buffer { z, cs, x1y1 } => format!(
                "BUF{}{}{}_",
                z,
                match cs {
                    ColorSpace::Srgb => "SRGB",
                    ColorSpace::Lrgb => "LRGB",
                    ColorSpace::Xyz => "XYZ",
                    ColorSpace::Lab => "LAB",
                    ColorSpace::Lch => "LCH",
                    ColorSpace::Y => "Y",
                    ColorSpace::L => "L",
                },
                match x1y1 {
                    true => "1",
                    false => "",
                }
            ),
            VarType::Void => "Void".into(),
            VarType::Unknown => "Unknown".into(),
        };
        id.push_str(&out);
    }
    id.push_str("__");
    id.push_str(name);
    id
}
