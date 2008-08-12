#!/usr/bin/env python
from timeit import default_timer as clock
from sympy import Symbol, Add, Mul, Integer, ADD, MUL, POW, INTEGER, SYMBOL, \
        multinomial_coefficients

N = 10

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")

def doit1(e):
    f = e*(e+1)
    f = f.expand()
    return f

e = (x+y+z+1)**N

t_tot = clock()
a2 = doit1(e)
t_tot = clock()-t_tot

print "done"

t_mul = clock()
a= multinomial_coefficients(4, N)
b= multinomial_coefficients(4, 2*N)
t_mul = clock() - t_mul
print e
print "# of terms:", len(a2.args)
print "time doing multinomial_coefficients:", t_mul
print "total time2:", t_tot


def csympy2sympy(a):
    import sympy
    if a.type == ADD:
        return sympy.Add(*[csympy2sympy(x) for x in a.args])
    elif a.type == MUL:
        return sympy.Mul(*[csympy2sympy(x) for x in a.args])
    elif a.type == POW:
        return sympy.Pow(*[csympy2sympy(x) for x in a.args])
    elif a.type == INTEGER:
        return sympy.sympify(str(a))
    elif a.type == SYMBOL:
        return sympy.sympify(str(a))
    print a
    raise NotImplementedError("sorry")

#e_sympy = csympy2sympy(e)
#a2_sympy = doit2(e_sympy)[0]
#a2_csympy = csympy2sympy(a2)
#print "comparison with sympy:"
#print a2_sympy == a2_csympy
