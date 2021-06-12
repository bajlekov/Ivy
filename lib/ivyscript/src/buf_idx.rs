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

use crate::inference::VarType;

impl VarType {
    pub fn buf_idx_1d(&self, id: &str, ix: &str) -> String {
        format!("{}[{}]", id, self.idx_1d(id, ix))
    }

    pub fn idx_1d(&self, id: &str, ix: &str) -> String {
        if let VarType::Buffer { x1y1: false, .. } = self {
            format!(
                "clamp((int)({ix}), 0, {cx})",
                ix = ix,
                cx = format!(
                    "(___str_{}[0] * ___str_{}[1] * ___str_{}[2] - 1)",
                    id, id, id
                )
            )
        } else if let VarType::Buffer { x1y1: true, .. } = self {
            format!(
                "clamp((int)({ix}), 0, {cx})",
                ix = ix,
                cx = format!("(___str_{}[2] - 1)", id)
            )
        } else {
            "// ERROR!!!\n".into()
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
        if let VarType::Buffer { x1y1: false, .. } = self {
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
        } else if let VarType::Buffer { x1y1: true, .. } = self {
            format!(
                "(clamp((int)({iz}), 0, {cz}))",
                iz = iz,
                cz = format!("(___str_{}[2] - 1)", id),
            )
        } else {
            "// ERROR!!!\n".into()
        }
    }
}
