BASIC   = 0
SYMBOL  = 1
ADD     = 2
MUL     = 3
POW     = 4
INTEGER = 5

def hash_seq(args):
    """
    Hash of a sequence, that *depends* on the order of elements.
    """
    # make this more robust:
    m = 2
    for x in args:
        m = hash(m + 1001 ^ hash(x))
    return m



cdef class Basic:
    cdef int _type
    cdef long long int mhash
    #cdef tuple _args

    def __init__(obj, _type, args):
        obj._type = _type
        obj._args = tuple(args)
        obj.mhash = -1

    def __repr__(self):
        return str(self)

    def __hash__(self):
        if self.mhash == -1:
            h = hash_seq(self.args)
            self.mhash = h
            return h
        else:
            return self.mhash

    @property
    def type(self):
        return self._type

    @property
    def args(self):
        return self._args

    def as_coeff_rest(self):
        return (Integer(1), self)

    def as_base_exp(self):
        return (self, Integer(1))

    def expand(self):
        return self

    def __add__(x, y):
        return Add((x, y))

    def __radd__(x, y):
        return x.__add__(y)

    def __sub__(x, y):
        return Add((x, -y))

    def __rsub__(x, y):
        return Add((y, -x))

    def __mul__(x, y):
        return Mul((x, y))

    def __rmul__(x, y):
        return Mul((y, x))

    def __div__(x, y):
        return Mul((x, Pow((y, Integer(-1)))))

    def __rdiv__(x, y):
        return Mul((y, Pow((x, Integer(-1)))))

    def __pow__(x, y, z):
        return Pow((x, y))

    def __rpow__(x, y):
        return Pow((y, x))

    def __neg__(x):
        return Mul((Integer(-1), x))

    def __pos__(x):
        return x

    def equal(self, Basic o):
        if o._type == self._type:
            return self.args == o.args
        else:
            return False

    def __richcmp__(Basic self, o, int op):
        o = sympify(o)
        if op == 2:
            return self.equal(o)
        elif op == 3:
            return not self.equal(o)
        else:
            return False


def Integer(i):
    obj = _Integer(INTEGER, [])
    obj.i = i
    return obj


class _Integer(Basic):
    #cdef int i

    #def __init__(self, _type, args):
    #    Basic.__init__(self, _type, args)

    def __hash__(Basic self):
        if self.mhash == -1:
            h = hash(self.i)
            self.mhash = h
            return h
        else:
            return self.mhash

    def equal(self, Basic o):
        if o._type == INTEGER:
            return self.i == o.i
        else:
            return False

    def __str__(self):
        return str(self.i)

    def __add__(self, a):
        cdef Basic o
        o = sympify(a)
        if o._type == INTEGER:
            return Integer(self.i+o.i)
        return Basic.__add__(self, o)

    def __mul__(self, a):
        cdef Basic o
        o = sympify(a)
        if o._type == INTEGER:
            return Integer(self.i*o.i)
        return Basic.__mul__(self, o)

def Symbol(name):
    obj = _Symbol(SYMBOL, [])
    obj.name = name
    return obj


class _Symbol(Basic):

    def __hash__(Basic self):
        if self.mhash == -1:
            h = hash(self.name)
            self.mhash = h
            return h
        else:
            return self.mhash

    def equal(self, Basic o):
        if o._type == SYMBOL:
            return self.name == o.name
        return False

    def __str__(self):
        return self.name

def Add(args, canonicalize=True):
    if canonicalize == False:
        obj = _Add(ADD, args)
        obj._args_set = None
        return obj
    args = [sympify(x) for x in args]
    return _Add.canonicalize(args)

class _Add(Basic):


    @classmethod
    def canonicalize(cls, args):
        use_glib = 0
        if use_glib:
            from csympy import HashTable
            d = HashTable()
        else:
            d = {}
        num = Integer(0)
        cdef Basic a, b
        for a in args:
            if a._type == INTEGER:
                num += a
            elif a._type == ADD:
                for b in a.args:
                    if b._type == INTEGER:
                        num += b
                    else:
                        coeff, key = b.as_coeff_rest()
                        if key in d:
                            d[key] += coeff
                        else:
                            d[key] = coeff
            else:
                coeff, key = a.as_coeff_rest()
                if key in d:
                    d[key] += coeff
                else:
                    d[key] = coeff
        if len(d)==0:
            return num
        args = []
        for a, b in d.iteritems():
            args.append(Mul((a, b)))
        if num.i != 0:
            args.insert(0, num)
        if len(args) == 1:
            return args[0]
        else:
            return Add(args, False)

    def freeze_args(self):
        #print "add is freezing"
        if self._args_set is None:
            self._args_set = frozenset(self.args)
        #print "done"

    def equal(self, Basic o):
        if o._type == ADD:
            self.freeze_args()
            o.freeze_args()
            return self._args_set == o._args_set
        else:
            return False

    def __str__(self):
        s = str(self.args[0])
        cdef Basic x
        x = self.args[0]
        if x._type == ADD:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            s = "%s + %s" % (s, str(x))
            if x._type == ADD:
                s = "(%s)" % s
        return s

    def __hash__(Basic self):
        if self.mhash == -1:
            # XXX: it is surprising, but this is *not* faster:
            #self.freeze_args()
            #h = hash(self._args_set)

            # this is faster:
            a = list(self.args[:])
            a.sort(key=hash)
            h = hash_seq(a)
            self.mhash = h
            return h
        else:
            return self.mhash

    def expand(self):
        r = Integer(0)
        for term in self.args:
            r += term.expand()
        return r

def Mul(args, canonicalize=True):
    if canonicalize == False:
        obj = _Mul(MUL, args)
        obj._args_set = None
        return obj
    args = [sympify(x) for x in args]
    return _Mul.canonicalize(args)


class _Mul(Basic):

    @classmethod
    def canonicalize(cls, args):
        use_glib = 0
        if use_glib:
            from csympy import HashTable
            d = HashTable()
        else:
            d = {}
        num = Integer(1)
        cdef Basic a, b
        for a in args:
            if a._type == INTEGER:
                num *= a
            elif a._type == MUL:
                for b in a.args:
                    if b._type == INTEGER:
                        num *= b
                    else:
                        key, coeff = b.as_base_exp()
                        if key in d:
                            d[key] += coeff
                        else:
                            d[key] = coeff
            else:
                key, coeff = a.as_base_exp()
                if key in d:
                    d[key] += coeff
                else:
                    d[key] = coeff
        if num.i == 0 or len(d)==0:
            return num
        args = []
        for a, b in d.iteritems():
            args.append(Pow((a, b)))
        if num.i != 1:
            args.insert(0, num)
        if len(args) == 1:
            return args[0]
        else:
            return Mul(args, False)

    def __hash__(Basic self):
        if self.mhash == -1:
            # in contrast to Add, here it is faster:
            self.freeze_args()
            h = hash(self._args_set)
            # this is slower:
            #a = list(self.args[:])
            #a.sort(key=hash)
            #h = hash_seq(a)
            self.mhash = h
            return h
        else:
            return self.mhash

    def freeze_args(self):
        #print "mul is freezing"
        if self._args_set is None:
            self._args_set = frozenset(self.args)
        #print "done"

    def equal(self, Basic o):
        if o._type == MUL:
            self.freeze_args()
            o.freeze_args()
            return self._args_set == o._args_set
        else:
            return False


    def as_coeff_rest(self):
        cdef Basic a = self.args[0]
        if a._type == INTEGER:
            return self.as_two_terms()
        return (Integer(1), self)

    def as_two_terms(self):
        return (self.args[0], Mul(self.args[1:]))


    def __str__(self):
        s = str(self.args[0])
        if self.args[0]._type in [ADD, MUL]:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            if x._type in [ADD, MUL]:
                s = "%s * (%s)" % (s, str(x))
            else:
                s = "%s*%s" % (s, str(x))
        return s

    @classmethod
    def expand_two(self, Basic a, Basic b):
        """
        Both a and b are assumed to be expanded.
        """
        if a._type == ADD and b._type == ADD:
            r = Integer(0)
            for x in a.args:
                for y in b.args:
                    r += x*y
            return r
        if a._type == ADD:
            r = Integer(0)
            for x in a.args:
                r += x*b
            return r
        if b._type == ADD:
            r = Integer(0)
            for y in b.args:
                r += a*y
            return r
        return a*b

    def expand(self):
        a, b = self.as_two_terms()
        r = _Mul.expand_two(a, b)
        if r == self:
            a = a.expand()
            b = b.expand()
            return _Mul.expand_two(a, b)
        else:
            return r.expand()

def Pow(args, canonicalize=True):
    if canonicalize == False:
        obj = _Pow(POW, args)
        return obj
    args = [sympify(x) for x in args]
    return _Pow.canonicalize(args)


class _Pow(Basic):

    @classmethod
    def canonicalize(cls, args):
        cdef Basic base, exp
        base, exp = args
        if base._type == INTEGER:
            if base.i == 0:
                return Integer(0)
            if base.i == 1:
                return Integer(1)
        if exp._type == INTEGER:
            if exp.i == 0:
                return Integer(1)
            if exp.i == 1:
                return base
        if base._type == POW:
            return Pow((base.args[0], base.args[1]*exp))
        return Pow(args, False)

    def __str__(self):
        s = str(self.args[0])
        cdef Basic x
        x = self.args[0]  
        if x._type == ADD:
            s = "(%s)" % s
        x = self.args[1]
        if x._type == ADD:
            s = "%s^(%s)" % (s, str(self.args[1]))
        else:
            s = "%s^%s" % (s, str(self.args[1]))
        return s

    def as_base_exp(self):
        return self.args

    def expand(self):
        cdef Basic base, exp
        base, exp = self.args
        if base._type == ADD and exp._type == INTEGER:
            n = exp.i
            m = len(base.args)
            #print "multi"
            d = multinomial_coefficients(m, n)
            #print "assembly"
            r = []
            for powers, coeff in d.iteritems():
                if coeff == 1:
                    t = []
                else:
                    t = [Integer(coeff)]
                for x, p in zip(base.args, powers):
                    if p != 0:
                        t.append(Pow((x, p)))
                assert len(t) != 0
                if len(t) == 1:
                    t = t[0]
                else:
                    t = Mul(t, False)
                r.append(t)
            r = Add(r, False)
            #print "done"
            return r
        return self

def sympify(x):
    if isinstance(x, int):
        return Integer(x)
    return x

def var(s):
    """
        Create a symbolic variable with the name *s*.

        INPUT:
            s -- a string, either a single variable name, or
                 a space separated list of variable names, or
                 a list of variable names.

        NOTE: The new variable is both returned and automatically injected into
        the parent's *global* namespace.  It's recommended not to use "var" in
        library code, it is better to use symbols() instead.

        EXAMPLES:
        We define some symbolic variables:
            >>> var('m')
            m
            >>> var('n xx yy zz')
            (n, xx, yy, zz)
            >>> n
            n

    """
    import re
    import inspect
    frame = inspect.currentframe().f_back

    try:
        if not isinstance(s, list):
            s = re.split('\s|,', s)

        res = []

        for t in s:
            # skip empty strings
            if not t:
                continue
            sym = _Symbol(t)
            frame.f_globals[t] = sym
            res.append(sym)

        res = tuple(res)
        if len(res) == 0:   # var('')
            res = None
        elif len(res) == 1: # var('x')
            res = res[0]
                            # otherwise var('a b ...')
        return res

    finally:
        # we should explicitly break cyclic dependencies as stated in inspect
        # doc
        #del frame
        pass

def binomial_coefficients(n):
    """Return a dictionary containing pairs {(k1,k2) : C_kn} where
    C_kn are binomial coefficients and n=k1+k2."""
    d = {(0, n):1, (n, 0):1}
    a = 1
    for k in xrange(1, n//2+1):
        a = (a * (n-k+1))//k
        d[k, n-k] = d[n-k, k] = a
    return d

def binomial_coefficients_list(n):
    """ Return a list of binomial coefficients as rows of the Pascal's
    triangle.
    """
    d = [1] * (n+1)
    a = 1
    for k in xrange(1, n//2+1):
        a = (a * (n-k+1))//k
        d[k] = d[n-k] = a
    return d

def multinomial_coefficients(m, n, _tuple=tuple, _zip=zip):
    """Return a dictionary containing pairs ``{(k1,k2,..,km) : C_kn}``
    where ``C_kn`` are multinomial coefficients such that
    ``n=k1+k2+..+km``.

    For example:

    >>> print multinomial_coefficients(2,5)
    {(3, 2): 10, (1, 4): 5, (2, 3): 10, (5, 0): 1, (0, 5): 1, (4, 1): 5}

    The algorithm is based on the following result:

       Consider a polynomial and it's ``m``-th exponent::

         P(x) = sum_{i=0}^m p_i x^k
         P(x)^n = sum_{k=0}^{m n} a(n,k) x^k

       The coefficients ``a(n,k)`` can be computed using the
       J.C.P. Miller Pure Recurrence [see D.E.Knuth, Seminumerical
       Algorithms, The art of Computer Programming v.2, Addison
       Wesley, Reading, 1981;]::

         a(n,k) = 1/(k p_0) sum_{i=1}^m p_i ((n+1)i-k) a(n,k-i),

       where ``a(n,0) = p_0^n``.
    """

    if m==2:
        return binomial_coefficients(n)
    symbols = [(0,)*i + (1,) + (0,)*(m-i-1) for i in range(m)]
    s0 = symbols[0]
    p0 = [_tuple([aa-bb for aa,bb in _zip(s,s0)]) for s in symbols]
    r = {_tuple([aa*n for aa in s0]):1}
    r_get = r.get
    r_update = r.update
    l = [0] * (n*(m-1)+1)
    l[0] = r.items()
    for k in xrange(1, n*(m-1)+1):
        d = {}
        d_get = d.get
        for i in xrange(1, min(m,k+1)):
            nn = (n+1)*i-k
            if not nn:
                continue
            t = p0[i]
            for t2, c2 in l[k-i]:
                tt = _tuple([aa+bb for aa,bb in _zip(t2,t)])
                cc = nn * c2
                b = d_get(tt)
                if b is None:
                    d[tt] = cc
                else:
                    cc = b + cc
                    if cc:
                        d[tt] = cc
                    else:
                        del d[tt]
        r1 = [(t, c//k) for (t, c) in d.iteritems()]
        l[k] = r1
        r_update(r1)
    return r
