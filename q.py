from csympy import HashTable
from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

e = (1 + y + x + z)**2

f = e*(e+1)

print f
g = f.expand()
print g
