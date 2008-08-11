from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

#print x+y == x+y
f = (x+y+z+1)**2
e = f*(f+1)

print f
print f.expand()
