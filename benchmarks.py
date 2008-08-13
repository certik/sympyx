#!/usr/bin/env python

from timeit import default_timer as clock
from random import randint
try:
    from sympy import Symbol, Add, Mul
    print 'I: Running SymPy'
except ImportError:
    from sympycore import Symbol
    print 'I: Running sympycore'

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")


def bench_e2e_1():
    "e=(x+y+z+1)**10;f=e*(e+1);f.expand()"
    e = (x+y+z+1)**10
    f = e*(e+1)
    f = f.expand()

def bench_e2e_2():
    "e=(x+y+z+1)**10; f=e**2+e; f.expand()"
    e = (x+y+z+1)**10
    f = e**2 + e
    f = f.expand()

def bench_e2e_3():
    "e=(x+y+z+1)**20; f=e**2+e; f.expand()"
    e = (x+y+z+1)**20
    f = e**2 + e
    f = f.expand()

def bench_e2e_4():
    "e=(x+y+z+1)**30; f=e**2+e; f.expand()"
    e = (x+y+z+1)**30
    f = e**2 + e
    f = f.expand()

def bench_e2e_5():
    "e=(x+y+z+1)**40; f=e**2+e; f.expand()"
    e = (x+y+z+1)**40
    f = e**2 + e
    f = f.expand()

def bench_expand1():
    "e=(x+y+z+1)**10; e.expand()"
    e = (x+y+z+1)**10
    e = e.expand()

def bench_expand2():
    "e=(x+y+z+1)**50; e.expand()"
    e = (x+y+z+1)**50
    e = e.expand()

def bench_expand3():
    "e=(x+z+y)**20 * (z+x)**9; e.expand()"
    e = (x+z+y)**20 * (z+x)**9
    e = e.expand()

def add1():
    "Add(x,<random integer>,y), 2000x"
    i = 2000
    while i:
        i -= 1
        Add((x, randint(0, 1000000), y))

def mul1():
    "Mul(x,<random integer>,y), 2000x"
    i = 2000
    while i:
        i -= 1
        Mul((x, randint(0, 1000000), y))

def sum1():
    "sum(x**i/i,i=1..400)"
    s = 0
    i = 401
    while i:
        s += x**i/i
        i -= 1

def sum2():
    "sum(x**i/i,i=1..400), using Add(terms)"
    terms = []
    i = 401
    while i:
        terms.append(x**i/i)
        i -= 1
    s = Add(terms)


benchmarks = [
        bench_e2e_1,
        bench_e2e_2,
        #bench_e2e_3,
        # too slow:
        #bench_e2e_4,
        #bench_e2e_5,
        bench_expand1,
        #bench_expand2,
        bench_expand3,
        add1,
        mul1,
        sum1,
        sum2,
        ]

report = []
for b in benchmarks:
    t = clock()
    b()
    t = clock()-t
    print "%65s: %f" % (b.__doc__, t)
