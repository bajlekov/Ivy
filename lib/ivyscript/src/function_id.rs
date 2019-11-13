use crate::ast::ColorSpace;
use crate::inference::VarType;

pub fn function_id(name: &str, input: &[VarType]) -> String {
    let mut id = String::from("___");
    for v in input {
        let s = match v {
            VarType::Bool => String::from("Bool_"),
            VarType::Int => String::from("Int_"),
            VarType::Float => String::from("Float_"),
            VarType::Vec => String::from("Vec_"),
            VarType::BoolArray(n, x, y, z, w) => {
                format!("BoolArray_{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::IntArray(n, x, y, z, w) => format!("IntArray_{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::FloatArray(n, x, y, z, w) => {
                format!("FloatArray_{}_{}_{}_{}_{}_", n, x, y, z, w)
            }
            VarType::VecArray(n, x, y, z, w) => format!("VecArray_{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::Buffer {
                x,
                y,
                z,
                sx,
                sy,
                sz,
                cs,
            } => format!(
                "Buffer_{}_{}_{}_{}_{}_{}_{}_",
                x,
                y,
                z,
                sx,
                sy,
                sz,
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
    id.push_str("__");
    id.push_str(name);
    id
}
