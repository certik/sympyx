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

def doit2(e):
    e1 = e**2
    e = e.expand()
    e1 = e1.expand()
    t = clock()
    f = e + e1
    t = clock() - t
    return f, t

e = (x+y+z+1)**N

print "1:"
#t_tot1 = clock()
#a1 = doit1(e)
#t_tot1 = clock()-t_tot1
print "2:"
t_tot = clock()
a2, t = doit2(e)
t_tot = clock()-t_tot

#e = e*(e+1)
#f = e.expand()

print "done"

t_mul = clock()
a= multinomial_coefficients(4, N)
b= multinomial_coefficients(4, 2*N)
t_mul = clock() - t_mul
#print "a1: ", a1
#print "a2: ", a2
#print "a1 == a2: ", a1 == a2
#print "hash(a1) == hash(a2)", hash(a1) == hash(a2)
print e
print "# of terms:", len(a2.args)
print "time spent doing e+e2:", t
print "time doing multinomial_coefficients:", t_mul
#print "total time1:", t_tot1
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
