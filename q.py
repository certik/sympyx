from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

#print x+y == x+y
print ( x*(x+y)**2 + z*(x+y)**2 ).expand()
