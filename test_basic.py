from sympy import Symbol, Add, Mul, Pow, Integer, SYMBOL, ADD, MUL, POW, \
        INTEGER

def test_eq():

    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")
    a = Symbol("x")

    assert x == x
    assert not (x != x)
    assert x == a
    assert not (x != a)
    assert x != y

    assert Add(x, y) == Add(x, y)
    assert Add(a, y) == Add(x, y)
    assert Add(x, y) == Add(y, x)
    assert Add(x, y) != Add(y, z)

    assert Mul(x, y) == Mul(x, y)
    assert Mul(a, y) == Mul(x, y)
    assert Mul(x, y) == Mul(y, x)
    assert Mul(x, y) != Mul(y, z)

    assert Pow(x, y) == Pow(x, y)
    assert Pow(a, y) == Pow(x, y)
    assert Pow(x, y) != Pow(y, x)
    assert Pow(x, y) != Pow(y, z)
    assert Pow(a, y) != Pow(x, z)

    assert Integer(3) == Integer(3)
    assert Integer(3) != Integer(4)

def test_add():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert Add(Add(x, y), z) == Add(x, Add(y, z))
    assert Add(Add(z, x), y) == Add(x, Add(y, z))
    assert Add(Add(z, x), x) != Add(x, Add(y, z))

    assert Add(x, x) == Mul(Integer(2), x)
    assert Add(Add(Add(x, y), z), x) == Add(Add(Mul(Integer(2), x), y), z)

def test_mul():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert Mul(Mul(x, y), z) == Mul(x, Mul(y, z))
    assert Mul(Mul(z, x), y) == Mul(x, Mul(y, z))
    assert Mul(Mul(z, x), x) != Mul(x, Mul(y, z))

    assert Mul(x, x) == Pow(x, Integer(2))
    assert Mul(Mul(Mul(x, y), z), x) == Mul(Mul(Pow(x, Integer(2)), y), z)

def test_arit():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert x+y == Add(x, y)
    assert x+y+z == Add(Add(x, y), z)

    assert x-y == Add(x, Mul(Integer(-1), y))
    assert y-x == Add(Mul(Integer(-1), x), y)

    assert x*y == Mul(x, y)
    assert x*y*z == Mul(z, Mul(x, y))

    assert x/y == Mul(x, Pow(y, Integer(-1)))
    assert y/x == Mul(Pow(x, Integer(-1)), y)

    assert x**Integer(2) == Pow(x, Integer(2))

    assert -x == Mul(Integer(-1), x)
    assert +x == x

def test_int_conversion():
    x = Symbol("x")
    assert x+1 == Add(x, 1)
    assert x*1 == x
    assert x**1 == x
    assert x/2 == Mul(x, Pow(2, -1))

def test_expand1():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert ( (x+y)**2 ).expand() == x**2 + 2*x*y + y**2
    assert ( (x+y)**3 ).expand() == x**3 + 3*x**2*y +3*x*y**2 + y**3

    assert ( (x+y+z)**2 ).expand() == x**2 + y**2 + z**2 + 2*x*y + 2*x*z + 2*y*z

def test_expand2():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert ( 2*x*y ).expand() == 2*x*y
    assert ( (x+y) * (x+z) ).expand() == x**2 + x*y + x*z + y*z
    assert ( x*(x+y)**2 ).expand() == x**3 + 2*x**2*y + x*y**2
    assert ( x*(x+y)**2 + z*(x+y)**2 ).expand() == \
            x**3 + 2*x**2*y + y**2*z + x**2*z + x*y**2 + 2*x*y*z

    assert ( 2*x * (y*x + y*z) ).expand() == 2*x**2*y + 2*x*y*z
    assert ( (x+y)**2 * (x+z) ).expand() == \
            x**3 + 2*x**2*y + y**2*z + x**2*z + x*y**2 + 2*x*y*z

def test_canonicalization():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert x-x == 0
    assert x*1 == x
    assert x+0 == x
    assert x-0 == x
    assert x**1 == x
    assert 1**x == 1
    assert 0**x == 0

def test_pow():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert (x**2)**3 == x**6
    assert (x**y)**3 == x**(3*y)
    # this is maybe not mathematically correct:
    assert (x**y)**z == x**(y*z)

def test_args_type():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")

    assert (x+y).type == ADD
    assert set((x+y).args) == set((x, y))
    assert set((x+y).args) != set((x, z))

    assert (x*y*z).type == MUL
    assert set((x*y*z).args) == set((x, y, z))

    assert (x**y).type == POW
    assert (x**y).args == (x, y)
    assert x.type == SYMBOL
    assert x.args == ()
    assert Integer(5).type == INTEGER
    assert Integer(5).args == ()

    assert ( x-y ).type == ADD
    assert set(( x-y ).args) == set((x, -y))

def test_hash():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")
    a = Symbol("x")

    assert hash(x) != hash(y)
    assert hash(x) != hash(z)
    assert hash(x) == hash(a)

    assert hash(Integer(3)) == hash(Integer(3))
    assert hash(Integer(3)) != hash(Integer(4))

    assert hash(x*y) == hash(y*x)
    assert hash(x*y) == hash(y*a)
    #assert hash(x*y) != hash(y*z)
    assert hash(x*y*z) == hash(y*z*x)
    assert hash(x*y*z) == hash(y*z*a)

def test_hash2():
    x = Symbol("x")
    y = Symbol("y")
    z = Symbol("z")
    a = Symbol("x")

    assert x*y+y*x == 2*x*y
    assert x*y-y*x == 0
    assert x*y+y*a == 2*x*y
    assert x*y-y*a == 0
