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

use std::cell::{Cell, RefCell};
use std::collections::HashMap;

use crate::inference::VarType;

#[derive(Debug)]
struct Scope {
    parent: usize,
    vars: HashMap<String, Option<VarType>>,
}

#[derive(Debug)]
pub struct ScopeTree {
    scopes: RefCell<Vec<Scope>>,
    pub current: Cell<usize>,
}

impl ScopeTree {
    pub fn new() -> ScopeTree {
        ScopeTree {
            scopes: RefCell::new(vec![Scope {
                parent: 0,
                vars: HashMap::new(),
            }]),
            current: Cell::new(0),
        }
    }

    pub fn clear(&self) {
        self.current.set(0);
        self.scopes.borrow_mut().drain(1..);
    }

    pub fn add(&self, id: &str, t: VarType) -> usize {
        let n = self.current.get();
        self.scopes.borrow_mut()[n].vars.insert(id.into(), Some(t));
        n
    }

    pub fn placeholder(&self, id: &str) -> usize {
        let n = self.current.get();
        self.scopes.borrow_mut()[n].vars.insert(id.into(), None);
        n
    }

    pub fn overwrite(&self, var: &str, t: VarType) -> usize {
        let mut id = self.current.get();
        loop {
            let scope = &mut self.scopes.borrow_mut()[id];
            if scope.vars.get(var).is_some() {
                scope.vars.insert(var.into(), Some(t));
                return id;
            } else {
                if id == 0 {
                    return 0;
                }
                id = scope.parent;
            }
        }
    }

    pub fn get(&self, var: &str) -> Option<VarType> {
        let mut id = self.current.get();
        loop {
            let scope = &self.scopes.borrow()[id];
            if let Some(t) = scope.vars.get(var) {
                return *t;
            } else {
                if id == 0 {
                    return None;
                }
                id = scope.parent;
            }
        }
    }

    pub fn set_parent(&self, parent: usize) {
        let n = self.current.get();
        self.scopes.borrow_mut()[n].parent = parent;
    }

    pub fn set_current(&self, current: usize) {
        self.current.set(current);
    }

    pub fn open(&self) -> usize {
        self.scopes.borrow_mut().push(Scope {
            parent: self.current.get(),
            vars: HashMap::new(),
        });
        self.current.set(self.scopes.borrow().len() - 1);
        self.current.get()
    }

    pub fn close(&self) -> usize {
        self.current
            .set(self.scopes.borrow_mut()[self.current.get()].parent);
        self.current.get()
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn scope_add() {
        let key1 = "abc".to_string();
        let key2 = "def".to_string();

        let s = ScopeTree::new();

        s.add(&key1, VarType::Float);

        s.open();
        s.add(&key1, VarType::Float);
        s.close();

        s.open();
        s.add(&key1, VarType::Bool);
        s.open();
        s.close();
        s.add(&key2, VarType::Float);
        s.close();

        s.open();
        s.add(&key1, VarType::Float);
        s.close();

        assert_eq!(s.current.get(), 0);
        assert_eq!(s.get(&key1), Some(VarType::Float));
        assert_eq!(s.get(&key2), None);
    }
}
