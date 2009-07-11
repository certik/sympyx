from sympy import x, y, Symbol, Integer

class Constant(Symbol):

    def __new__(cls, name, sym):
        obj = Symbol.__new__(cls, name)
        obj.sym = sym
        obj.changes_add = True
        obj.changes_mul = True
        return obj

    def combine_add(self, d):
        #print self, d,
        one = Integer(1)
        e = {one: d[one], self: 1}
        for x in d:
            if x == self.sym or x.has(self.sym):
                e[x] = d[x]
        e[one] = Integer(0)
        d.clear()
        d.update(e)
        #print d

    def combine_mul(self, d):
        #print self, d,
        one = Integer(1)
        e = {one: d[one], self: 1}
        for x in d:
            if x == self.sym or x.has(self.sym) or d[x].has(self.sym):
                e[x] = d[x]
        e[one] = Integer(1)
        d.clear()
        d.update(e)
        #print d

def test_constant_add():
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

    assert 2 + A == A
    assert A + 2 == A
    assert A + x + 2**x + y + 2 == A + x + 2**x
    assert A + x + y + x*y + 2 == A + x + x*y

def test_constant_mul():
    e = x * y
    A = Constant("A", x)
    assert e * A == A * x
    assert A * e == A * x
    assert y * A * e == A * x
    assert y * y * A * e == A * x
    assert A * x * y == A * x
    assert A * y * x == A * x
    assert y * A * y * x == A * x
    assert e * A * e == A * x**2
    assert e * A * y * x == A * x**2
    assert e * A * x * y == A * x**2
    assert A * y == A
    assert y * A == A
    assert A * x * 2**x * y == A * x * 2**x
    assert A * x * y * x*y == A * x * x*y

    assert 2 * A == A
    assert A * 2 == A
    assert A * x * 2**x * y * 2 == A * x * 2**x
    assert A * x * y * x*y * 2 == A * x * x*y

def test_constant_sympy():
    z = Symbol('z')
    C = Constant('C', x)
    assert y*C == C
    assert x*C == x*Constant('C', x)
    assert C*y == C
    assert C*x == x*Constant('C', x)
    assert 2*C == C
    assert C*2 == C
    assert y*C*x == C*x
    assert x*y*C == x*C
    assert y*x*C == x*C
    assert C*y*(y+1) == C
    assert y*C*(y+1) == C
    assert x*(y*C) == x*C
    assert x*(C*y) == x*C
    assert C*(x*y) == C*x
    assert (x*y)*C == x*C
    assert (y*x)*C == x*C
    assert y*(y+1)*C == C
    assert C*x*y == C*x
    assert x*C*y == x*C
    assert (C*x)*y == C*x
    assert y*(x*C) == x*C
    assert (x*C)*y == x*C

def test_more():
    A = Constant("A", x)
    assert A*x+y == A*x + y
    assert A*x+y != A*x
    assert A*x*2**x != A*x
