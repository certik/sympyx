from csympy import HashTable
from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

#h = HashTable()
#h[x+1] = 3
#h.insert(x, 3)
#h.insert(3, x**2)
#print h[x+1]
#print x+2 in h
#
#print ( x*(x+y)**2 + z*(x+y)**2 ).expand()
#print ( (x+z)*(x+y)**2 ).expand()

#print x*y+x+y+x**2 == y*x + x + y + x**2
e1 = z+x+y*x
e2 = x*y+x+z
f = e1.args
g = e2.args
print f
print g
print set(f) == set(g)
d = {}
d[e1] = 1
print e1 in d
print e2 in d
