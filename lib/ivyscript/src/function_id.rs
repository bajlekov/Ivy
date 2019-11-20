use crate::ast::ColorSpace;
use crate::inference::VarType;

pub fn function_id(name: &str, input: &[VarType]) -> String {
    let mut id = String::from("___");
    for v in input {
        let s = match v {
            VarType::Bool => String::from("B_"),
            VarType::Int => String::from("I_"),
            VarType::Float => String::from("F_"),
            VarType::Vec => String::from("V_"),
            VarType::BoolArray(n, x, y, z, w) => format!("BA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::IntArray(n, x, y, z, w) => format!("IA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::FloatArray(n, x, y, z, w) => format!("FA{}_{}_{}_{}_{}_", n, x, y, z, w),
            VarType::VecArray(n, x, y, z, w) => format!("VA{}_{}_{}_{}_{}_", n, x, y, z, w),
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
