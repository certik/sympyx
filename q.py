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
print len(g.args)
print t
#print g == x+y
