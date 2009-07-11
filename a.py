from sympy import x, y, Symbol

class Constant(Symbol):

    def __new__(cls, name, sym):
        obj = Symbol.__new__(cls, name)
        obj.sym = sym
        obj.changes_add = True
        return obj

    def combine_add(self, d):
        if self.sym in d:
            e = {self: 1, self.sym: d[self.sym]}
            d.clear()
            d.update(e)
        else:
            return Symbol.combine_add(self, d)

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


if __name__ == "__main__":
    e = x + y
    A = Constant("A", x)
    print e
    print "-"*40
    print e + A
    print "-"*40
    print y+A + e
    print "-"*40
    #print x + y + A + x + y
    #print x + A + x
