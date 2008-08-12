#!/usr/bin/env python
from timeit import default_timer as clock
from csympy import HashTable
from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

e = (1 + y + x + z)**50

#f = e*(e+1)
f = e

print f
t = clock()
g = f.expand()
t = clock() - t
print '#args: %i' % len(g.args)
print 'time:  %f' % t
#print g == x+y
