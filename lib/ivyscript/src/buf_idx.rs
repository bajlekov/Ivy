use crate::inference::VarType;

impl VarType {
    pub fn buf_idx_1d(&self, id: &str, ix: &str) -> String {
        format!("{}[{}]", id, self.idx_1d(id, ix))
    }

    pub fn idx_1d(&self, id: &str, ix: &str) -> String {
        if let VarType::Buffer { .. } = self {
            format!(
                "clamp((int)({ix}), 0, {cx})",
                ix = ix,
                cx = format!(
                    "(___str_{}[0] * ___str_{}[1] * ___str_{}[2] - 1)",
                    id, id, id
                )
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }

    pub fn buf_idx_2d(&self, id: &str, x: &str, y: &str) -> String {
        format!(
            "( {}, {}, {} )",
            self.buf_idx_3d(id, x, y, "0"),
            self.buf_idx_3d(id, x, y, "1"),
            self.buf_idx_3d(id, x, y, "2"),
        )
    }

    pub fn buf_idx_3d(&self, id: &str, ix: &str, iy: &str, iz: &str) -> String {
        format!("{}[{}]", id, self.idx_3d(id, ix, iy, iz))
    }

    pub fn idx_3d(&self, id: &str, ix: &str, iy: &str, iz: &str) -> String {
        if let VarType::Buffer { .. } = self {
            format!(
            "(clamp((int)({ix}), 0, {cx})*{sx} + clamp((int)({iy}), 0, {cy})*{sy} + clamp((int)({iz}), 0, {cz})*{sz})",
            ix = ix,
            iy = iy,
            iz = iz,
            cx = format!("(___str_{}[0] - 1)", id),
            cy = format!("(___str_{}[1] - 1)", id),
            cz = format!("(___str_{}[2] - 1)", id),
            sx = format!("(___str_{}[3])", id),
            sy = format!("(___str_{}[4])", id),
            sz = format!("(___str_{}[5])", id),
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }
}
