from sympy import x, y, Symbol

class Constant(Symbol):

    def __new__(cls, name, sym):
        obj = Symbol.__new__(cls, name)
        obj.sym = sym
        obj.changes_add = True
        return obj

    def combine_add(self, d):
        e = {self: 1}
        for x in d:
            if x == self.sym or x.has(self.sym):
                e[x] = d[x]
        d.clear()
        d.update(e)

def test_constant():
    e = x + y
    A = Constant("A", x)
    assert e + A == A + x
    assert A + e == A + x
    assert y + A + e == A + x
    assert y + y + A + e == A + x
    assert A + x + y == A + x
    assert A + y + x == A + x
    assert y + A + y + x == A + x
    assert e + A + e == A + 2*x
    assert e + A + y + x == A + 2*x
    assert e + A + x + y == A + 2*x
    assert A + y == A
    assert y + A == A
    assert A + x + 2**x + y == A + x + 2**x
    assert A + x + y + x*y == A + x + x*y
