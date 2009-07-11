from sympy import x, y, Symbol

class Constant(Symbol):

    def __new__(cls, name, sym):
        obj = Symbol.__new__(cls, name)
        obj.sym = sym
        obj.changes_add = True
        return obj

    def combine_add(self, d):
        if self.sym in d:
            del d[x]
        return Symbol.combine_add(self, d)

e = x + y
A = Constant("A", x)
print e
print "-"*40
print e + A
print "-"*40
print A + e
print "-"*40
print A + x + y
