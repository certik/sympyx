from csympy import HashTable
from sympy import *

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")
a = Symbol("x")

h = HashTable()
h[x+1] = 3
h.insert(x, 3)
h.insert(3, x**2)
print h[x+1]
print x+2 in h
