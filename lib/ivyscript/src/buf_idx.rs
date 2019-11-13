use crate::inference::VarType;

impl VarType {
    pub fn buf_idx_1d(&self, id: &str, ix: &str) -> String {
        if let VarType::Buffer { x, y, z, .. } = self {
            format!(
                "{id}[clamp((int)({ix}), 0, {cx})]",
                id = id,
                ix = ix,
                cx = x * y * z - 1,
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }

    pub fn idx_1d(&self, ix: &str) -> String {
        if let VarType::Buffer { x, y, z, .. } = self {
            format!("clamp((int)({ix}), 0, {cx})", ix = ix, cx = x * y * z - 1,)
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
        if let VarType::Buffer {
            x,
            y,
            z,
            sx,
            sy,
            sz,
            ..
        } = self
        {
            format!(
            "{id}[clamp((int)({ix}), 0, {cx})*{sx} + clamp((int)({iy}), 0, {cy})*{sy} + clamp((int)({iz}), 0, {cz})*{sz}]",
            id = id,
            ix = ix,
            iy = iy,
            iz = iz,
            cx = x - 1,
            cy = y - 1,
            cz = z - 1,
            sx = sx,
            sy = sy,
            sz = sz,
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }

    pub fn idx_3d(&self, ix: &str, iy: &str, iz: &str) -> String {
        if let VarType::Buffer {
            x,
            y,
            z,
            sx,
            sy,
            sz,
            ..
        } = self
        {
            format!(
            "(clamp((int)({ix}), 0, {cx})*{sx} + clamp((int)({iy}), 0, {cy})*{sy} + clamp((int)({iz}), 0, {cz})*{sz})",
            ix = ix,
            iy = iy,
            iz = iz,
            cx = x - 1,
            cy = y - 1,
            cz = z - 1,
            sx = sx,
            sy = sy,
            sz = sz,
            )
        } else {
            String::from("// ERROR!!!\n")
        }
    }
}
