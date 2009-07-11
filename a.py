from sympy import x, y, Symbol

class Constant(Symbol):

    def combine_add(self, d):
        x = Symbol("x")
        if x in d:
            del d[x]
        return Symbol.combine_add(self, d)

e = x + y
A = Constant("A")
print e
print "-"*40
print e + A
print "-"*40
print A + e
print "-"*40
print A + x + y
