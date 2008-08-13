#!/usr/bin/env python
from timeit import default_timer as clock
from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

e = (x+y+z+1)**10
e = e*(e+1)
t = clock()
f = e.expand()
t = clock() - t
print len(f.args)
print t
