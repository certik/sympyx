#!/usr/bin/env python
from timeit import default_timer as clock
try:
    from sympy import Symbol
    print 'I: Running SymPy'
except ImportError:
    from sympycore import Symbol
    print 'I: Running sympycore'

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")

def bench1():
    "e=(x+y+z+1)**10;f=e*(e+1);f.expand()"
    e = (x+y+z+1)**10
    f = e*(e+1)
    f = f.expand()

def bench2():
    "e=(x+y+z+1)**10; f=e**2+e; f.expand()"
    e = (x+y+z+1)**10
    f = e**2 + e
    f = f.expand()

def bench3():
    "e=(x+y+z+1)**50; e.expand()"
    e = (x+y+z+1)**50
    e = e.expand()

benchmarks = [
        bench1,
        bench2,
        bench3,
        ]

report = []
for b in benchmarks:
    t = clock()
    b()
    t = clock()-t
    print "%65s: %f" % (b.__doc__, t)
