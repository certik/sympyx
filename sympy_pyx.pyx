# (1) Cython does not support __new__
#
# (2) what to do if we want
#
#   cdef class Base:
#       cdef virt_func(Base a, Base b):
#           # here we ensure that a & b are of the same type
#           ...
#
#   cdef class Child(Base):
#       cdef virt_func(Child a, Child b):
#           ...
#
#   ?
#
#   currently we have to do:
#
#   cdef class Child:
#       cdef cirt_func(Child a, Basic _b):
#           cdef Child b = <Child>_b
#
#
# (3) @staticmethod for cdef methods?
#
# (4) nested cdef like in here:
#
#   if ...:
#       cdef Basic a = ...
#

DEF BASIC   = 0
DEF SYMBOL  = 1
DEF ADD     = 2
DEF MUL     = 3
DEF POW     = 4
DEF INTEGER = 5

cdef int hash_seq(args):
    """
    Hash of a sequence, that *depends* on the order of elements.
    """
    # make this more robust:
    cdef int m = 2
    for x in args:
        m = hash(m + 1001 ^ hash(x))
    return m



cdef class Basic:
    cdef int    type
    cdef int    hash
    cdef tuple  _args   # XXX tuple -> list?

    def __cinit__(self):
        self.hash = -1

    def __repr__(self):
        return str(self)

    def __hash__(self):
        if self.hash == -1:
            self.hash = self._hash()

        return self.hash

    cdef int _hash(self):
            return hash_seq(self.args)

    @property
    def args(self):
        return self._args

    # XXX struct2
    cpdef as_coeff_rest(self):
        return (Integer(1), self)

    def as_base_exp(self):
        return (self, Integer(1))

    def expand(self):
        return self

    def __add__(x, y):
        return Add((x, y))

    # XXX there is no __radd__ in pyrex
    def __radd__(x, y):
        return x.__add__(y)

    def __sub__(x, y):
        return Add((x, -y))

    # XXX no __rsub__
    def __rsub__(x, y):
        return Add((y, -x))

    def __mul__(x, y):
        return Mul((x, y))

    # XXX no __rmul__
    def __rmul__(x, y):
        return Mul((y, x))

    def __div__(x, y):
        return Mul((x, Pow((y, Integer(-1)))))

    # XXX no __rdiv__
    def __rdiv__(x, y):
        return Mul((y, Pow((x, Integer(-1)))))

    # FIXME we should get rid of z?
    def __pow__(x, y, z):
        return Pow((x, y))

    # XXX no __rpow__
    def __rpow__(x, y):
        return Pow((y, x))

    def __neg__(x):
        return Mul((Integer(-1), x))

    def __pos__(x):
        return x

    # in subclasses, you can be sure that _equal(a, b) is called with exactly
    # the same type, e.g.
    #
    # when _Add._equal(a, b) is called a and b are of .type=ADD for sure
    cdef int _equal(Basic self, Basic o):
        # by default we compare .args
        return self._args == o.args

    cdef bint equal(Basic self, Basic o):
        if self.type != o.type:
            return 0

        # now we know self and o are of the same type, lets dispatch to their
        # type's ._equal
        return self._equal(o)



    def __richcmp__(Basic x, y, int op):
        #print '__richcmp__ %s %s %i' % (x,y,op)
        y = sympify(y)

        # eq
        if op==2:
            return x.equal(y)

        # ne
        elif op==3:
            return not x.equal(y)


        else:
            return False

cpdef Integer(i):
    return _Integer(i)


cdef class _Integer(Basic):
    cdef object i   # XXX object -> pyint?

    def __cinit__(self, i):
        self.type = INTEGER
        self.i    = i

    cdef int _hash(self):
        return hash(self.i)

    cdef int _equal(_Integer self, Basic o):
        cdef _Integer other = <_Integer>o
        return self.i == other.i


    def __str__(_Integer self):
        return str(self.i)

    def __repr__(_Integer self):
        return 'Integer(%i)' % self.i

    # there is no __radd__ in pyrex
    def __add__(_a, _b):
        cdef Basic a = sympify(_a)
        cdef Basic b = sympify(_b)
        if a.type == INTEGER and b.type == INTEGER:
            return Integer( (<_Integer>a).i + (<_Integer>b).i )

        return Basic.__add__(a, b)

    # there is no __rmul__ in pyrex
    def __mul__(_a, _b):
        cdef Basic a = sympify(_a)
        cdef Basic b = sympify(_b)
        if a.type == INTEGER and b.type == INTEGER:
            return Integer( (<_Integer>a).i * (<_Integer>b).i )
        return Basic.__mul__(a, b)



# Symbol.__new__
cpdef Basic Symbol(name):
    obj = _Symbol(name)
    return obj


cdef class _Symbol(Basic):
    cdef object name    # XXX object -> str

    def __cinit__(self, name):
        self.type = SYMBOL
        self.name = name

    cdef int _hash(self):
        return hash(self.name)

    cdef int _equal(_Symbol self, Basic o):
        cdef _Symbol other = <_Symbol>o
        #print 'Symbol._equal %s %s' % (self.name, other.name)
        return self.name == other.name

    def __str__(_Symbol self):
        return self.name

    def __repr__(_Symbol self):
        return 'Symbol(%s)' % self.name



# Add.__new__
cpdef Basic Add(args):
    args = [sympify(x) for x in args]
    return _Add_canonicalize(args)


# @staticmethod
cdef Basic _Add_canonicalize(args):
    use_glib = 0
    if use_glib:
        from csympy import HashTable
        d = HashTable()
    else:
        d = {}

    cdef Basic a
    cdef Basic b
    cdef _Integer num = Integer(0)

    for a in args:
        if a.type == INTEGER:
            num += a
        elif a.type == ADD:
            for b in a.args:
                if b.type == INTEGER:
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
        return _Add(args)


cdef class _Add(Basic):
    cdef object  _args_set  # XXX object -> frozenset

    def __cinit__(_Add self, args):
        self.type   = ADD
        self._args  = tuple(args)



    def freeze_args(self):
        #print "add is freezing"
        if self._args_set is None:
            self._args_set = frozenset(self.args)
        #print "done"

    cdef int _equal(_Add self, Basic o):
        cdef _Add other = <_Add>o
        self .freeze_args()
        other.freeze_args()

        return self._args_set == other._args_set


    def __str__(Basic self):
        cdef Basic a = self.args[0]
        s = str(a)
        if a.type == ADD:
            s = "(%s)" % str(s)
        for a in self.args[1:]:
            s = "%s + %s" % (s, str(a))
            if a.type == ADD:
                s = "(%s)" % s
        return s

    cdef int _hash(self):
        # XXX: it is surprising, but this is *not* faster:
        #self.freeze_args()
        #h = hash(self._args_set)

        # this is faster:
        a = list(self.args[:])
        a.sort(key=hash)
        return hash_seq(a)

    def expand(self):
        r = Integer(0)
        for term in self.args:
            r += term.expand()
        return r

cpdef Basic Mul(args):
    args = [sympify(x) for x in args]
    return _Mul_canonicalize(args)


cdef Basic _Mul_canonicalize(args):
    use_glib = 0
    if use_glib:
        from csympy import HashTable
        d = HashTable()
    else:
        d = {}

    cdef Basic a
    cdef Basic b
    cdef _Integer num = Integer(1)

    for a in args:
        if a.type == INTEGER:
            num *= a
        elif a.type == MUL:
            for b in a.args:
                if b.type == INTEGER:
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
        return _Mul(args)



# @staticmethod
cdef Basic _Mul_expand_two(Basic a, Basic b):
    """
    Both a and b are assumed to be expanded.
    """
    cdef Basic r

    if a.type == ADD and b.type == ADD:
        r = Integer(0)
        for x in a.args:
            for y in b.args:
                r += x*y
        return r
    if a.type == ADD:
        r = Integer(0)
        for x in a.args:
            r += x*b
        return r
    if b.type == ADD:
        r = Integer(0)
        for y in b.args:
            r += a*y
        return r
    return a*b

cdef class _Mul(Basic):
    cdef object _args_set   # XXX object -> frozenset

    def __cinit__(self, args):
        self.type = MUL
        self._args= tuple(args)
        self._args_set = None


    cdef int _hash(self):
        # in contrast to Add, here it is faster:
        self.freeze_args()
        return hash(self._args_set)
        # this is slower:
        #a = list(self.args[:])
        #a.sort(key=hash)
        #h = hash_seq(a)
        #return h

    def freeze_args(self):
        #print "mul is freezing"
        if self._args_set is None:
            self._args_set = frozenset(self.args)
        #print "done"


    cdef int _equal(_Mul self, Basic o):
        cdef _Mul other = <_Mul>o
        self .freeze_args()
        other.freeze_args()
        return self._args_set == other._args_set


    cpdef as_coeff_rest(self):
        cdef Basic a = self.args[0]

        if a.type == INTEGER:
            return self.as_two_terms()
        return (Integer(1), self)

    def as_two_terms(self):
        return (self.args[0], Mul(self.args[1:]))


    def __str__(self):
        cdef Basic a = self.args[0]
        s = str(a)
        if a.type in [ADD, MUL]:
            s = "(%s)" % str(s)
        for a in self.args[1:]:
            if a.type in [ADD, MUL]:
                s = "%s * (%s)" % (s, str(a))
            else:
                s = "%s*%s" % (s, str(a))
        return s


    def expand(self):
        a, b = self.as_two_terms()
        r = _Mul_expand_two(a, b)
        if r == self:
            a = a.expand()
            b = b.expand()
            return _Mul_expand_two(a, b)
        else:
            return r.expand()

# Pow.__new__
cpdef Basic Pow(args):
    args = [sympify(x) for x in args]
    return _Pow_canonicalize(args)

# @staticmethod
cdef Basic _Pow_canonicalize(args):
    cdef Basic base
    cdef Basic exp
    base, exp = args

    cdef _Integer b = <_Integer>base
    cdef _Integer e = <_Integer>exp

    if base.type == INTEGER:
        if b.i == 0:
            return Integer(0)
        if b.i == 1:
            return Integer(1)
    if exp.type == INTEGER:
        if e.i == 0:
            return Integer(1)
        if e.i == 1:
            return base
    if base.type == POW:
        return Pow((base.args[0], base.args[1]*exp))
    return _Pow(args)



cdef class _Pow(Basic):

    def __cinit__(self, args):
        self.type = POW
        self._args= tuple(args)

    def __str__(_Pow self):
        cdef Basic b = self.args[0]
        cdef Basic e = self.args[1]
        s = str(b)
        if b.type == ADD:
            s = "(%s)" % s

        if e.type == ADD:
            s = "%s^(%s)" % (s, str(e))
        else:
            s = "%s^%s" % (s, str(e))
        return s

    # XXX struct 2
    def as_base_exp(_Pow self):
        return self.args

    cpdef Basic expand(_Pow self):
        cdef Basic  _base = self.args[0]
        cdef Basic  _exp  = self.args[1]

        # XXX please careful here - use it only after appropriate check
        cdef _Add     base = <_Add>_base
        cdef _Integer exp  = <_Integer>_exp

        if _base.type == ADD and _exp.type == INTEGER:
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
                    t = _Mul(t)
                r.append(t)
            r = _Add(r)
            #print "done"
            return r
        return self

cpdef Basic sympify(x):
    if isinstance(x, int):
        return Integer(x)
    return x

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
