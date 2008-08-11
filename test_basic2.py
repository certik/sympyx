from sympy import Symbol, Integer

import py

x = Symbol("x")
y = Symbol("y")
z = Symbol("z")

# basic sympy objects
basic_objs = [
    Integer(2),
    x,
    y,
    pow(x,y)*y,
]

# all supported objects
all_objs = basic_objs + [
    5,
]

def dotest(s):
    for x in all_objs:
        for y in all_objs:
            s(x,y)

def test_basic1():
    def s(a,b):
        x = a
        x = +a
        x = -a
        x = a+b
        x = a-b
        x = a*b
        x = a/b
        x = a**b
    dotest(s)

def test_ibasic():
    def s(a,b):
        x = a
        x += b
        x = a
        x -= b
        x = a
        x *= b
        x = a
        x /= b
    dotest(s)

def xtest_basic_nostr():
    for obj in basic_objs:
        for op in ['+','-','*','/','**']:
            py.test.raises(TypeError, "obj %s '1'" % op)

def test_len():
    e = x*y
    assert len(e.args) == 2
    e = x+y+z
    assert len(e.args) == 3

def test_args():
    assert (x*y).args[:] in ((x, y), (y, x))
    assert (x+y).args[:] in ((x, y), (y, x))
    assert (x*y+1).args[:] in ((x*y, 1), (1, x*y))
    #assert sin(x*y).args[:] == (x*y,)
    #assert sin(x*y).args[0] == x*y
    assert (x**y).args[:] == (x,y)
    assert (x**y).args[0] == x
    assert (x**y).args[1] == y
