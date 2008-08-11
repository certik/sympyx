from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

#print Add((x, y, z))

#e = Integer(1) + Integer(2)
#print e

print hash(x*y) == hash(y*x)
print (x*y) == (y*x)
print (x*y).args
print (y*x).args
e = x*y-y*x
print e
