DEF BASIC   = 0
DEF SYMBOL  = 1
DEF ADD     = 2
DEF MUL     = 3
DEF POW     = 4
DEF INTEGER = 5

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

    cdef int    type
    cdef tuple  _args

    cdef int    _hash


    def __cinit__(Basic self):
        self._hash = -1

    def __repr__(self):
        return str(self)

    def __hash__(Basic self):
        if self._hash == -1:
            self._hash = hash_seq(self.args)

        return self._hash

    @property
    def args(self):
        return self._args

    def as_coeff_rest(self):
        return (Integer(1), self)

    def as_base_exp(self):
        return (self, Integer(1))

    def expand(self):
        return self

    def __add__(Basic x, y):
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

    # XXX we should get rid of z
    def __pow__(x, y, z):
        return Pow((x, y))

    def __rpow__(x, y):
        return Pow((y, x))

    def __neg__(x):
        return Mul((Integer(-1), x))

    def __pos__(x):
        return x


    cdef int equal(Basic self, Basic o):
        if self.type != o.type:
            return 0

        return (self.args == o.args)



    def __richcmp__(Basic x, y, int op):
        y = sympify(y)

        # eq
        if op==2:
            return x.equal(y)

        # ne
        elif op==3:
            return not x.equal(y)


        else:
            return NotImplemented   # XXX ok?


cpdef Basic Integer(i):
    return _Integer(i)


cdef class _Integer(Basic):
    cdef readonly object i  # XXX object -> pyint ?

    def __cinit__(self, i):
        self.type = INTEGER
        self._args= ()
        self.i    = i

    def __hash__(_Integer self):
        # TODO we have to cache it
        return hash(self.i)


    cdef int _equal(_Integer self, _Integer o):
        return self.i == o.i

#   def __eq__(self, o):
#       o = sympify(o)
#       if o.type == INTEGER:
#           return self.i == o.i
#       else:
#           return False

    def __str__(self):
        return str(self.i)

    def __repr__(self):
        return 'Integer(%i)' % self.i

    def __add__(_Integer self, other):
        cdef Basic o = sympify(other)
        if o.type == INTEGER:
            return Integer(self.i+o.i)
        return Basic.__add__(self, o)

    def __mul__(_Integer self, other):
        cdef Basic o = sympify(other)
        if o.type == INTEGER:
            return Integer(self.i*o.i)
        return Basic.__mul__(self, o)


Symbol = Symbol__new__


# XXX Cython does not support __new__
cpdef Basic Symbol__new__(name):
    obj = _Symbol(name)
    return obj

cdef class _Symbol(Basic):
    cdef readonly object name    # XXX object -> string

    def __cinit__(self, name):
        self.type = SYMBOL
        self._args= tuple()
        self.name = name

    def __hash__(self):
        # TODO we have to cache it
        return hash(self.name)

    # TODO we have to hook it into .equal
    cdef int xequal(_Symbol self, _Symbol o):
        return self.name == o.name

#   def __eq__(self, o):
#       o = sympify(o)
#       if o.type == SYMBOL:
#           return self.name == o.name
#       return False

    def __str__(self):
        return self.name

    def __repr__(self):
        return 'Symbol(%s)' % self.name



# Add.__new__
cpdef Basic Add(args, canonicalize=True):
    if canonicalize == False:
        return _Add(args)
    else:
        args = [sympify(x) for x in args]
        return _Add.canonicalize(args)



cdef class _Add(Basic):
    cdef object  _args_set  # XXX object -> frozenset

    def __cinit__(_Add self, tuple args):
        self.type   = ADD
        self._args  = args


    @classmethod
    def canonicalize(cls, args):
        use_glib = 0
        if use_glib:
            from csympy import HashTable
            d = HashTable()
        else:
            d = {}

        cdef Basic a
        cdef Basic num = Integer(0)
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
            return Add(args, False)

    def freeze_args(self):
        #print "add is freezing"
        if self._args_set is None:
            self._args_set = frozenset(self.args)
        #print "done"

    cdef int _equal(_Add self, _Add o):
        # TODO ensure o is _Add too
        self.freeze_args()
        o   .freeze_args()

        return self._args_set == o._args_set

#   def __eq__(self, o):
#       o = sympify(o)
#       if o.type == ADD:
#           self.freeze_args()
#           o.freeze_args()
#           return self._args_set == o._args_set
#       else:
#           return False


    def __str__(self):
        s = str(self.args[0])
        if self.args[0].type == ADD:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            s = "%s + %s" % (s, str(x))
            if x.type == ADD:
                s = "(%s)" % s
        return s

    def __hash__(self):
        if self.mhash is None:
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


# Mul.__new__
cpdef Basic Mul(args, canonicalize=True):
    if canonicalize == False:
        return _Mul(tuple(args))

    args = [sympify(x) for x in args]
    return _Mul.canonicalize(args)


cdef class _Mul(Basic):
    cdef object _args_set   # XXX object -> frozenset

    def __cinit__(self, args):
        self.type = MUL
        self._args= args
        self._args_set = None


    @classmethod
    def canonicalize(cls, args):
        use_glib = 0
        if use_glib:
            from csympy import HashTable
            d = HashTable()
        else:
            d = {}

        cdef Basic num = Integer(1)
        cdef Basic a

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
            return Mul(args, False)

    def __hash__(self):
        if self.mhash is None:
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

#   def __eq__(self, o):
#       o = sympify(o)
#       if o.type == MUL:
#           self.freeze_args()
#           o.freeze_args()
#           return self._args_set == o._args_set
#       else:
#           return False


    cdef int _equal(_Mul self, _Mul o):
        # XXX ensure o is Mul
        # XXX compare len first
        self.freeze_args()
        o   .freeze_args()
        return self._args_set == o._args_set


    def as_coeff_rest(self):
        if self.args[0].type == INTEGER:
            return self.as_two_terms()
        return (Integer(1), self)

    def as_two_terms(self):
        return (self.args[0], Mul(self.args[1:]))


    def __str__(_Mul self):
        s = str(self.args[0])

        cdef Basic x = self.args[0]

        if x.type in [ADD, MUL]:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            if x.type in [ADD, MUL]:
                s = "%s * (%s)" % (s, str(x))
            else:
                s = "%s*%s" % (s, str(x))
        return s

    @classmethod
    def expand_two(self, a, b):
        """
        Both a and b are assumed to be expanded.
        """
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

    def expand(self):
        a, b = self.as_two_terms()
        r = _Mul.expand_two(a, b)
        if r == self:
            a = a.expand()
            b = b.expand()
            return _Mul.expand_two(a, b)
        else:
            return r.expand()


cpdef Basic Pow(args, canonicalize=True):
    if canonicalize == False:
        return _Pow(tuple(args))

    args = [sympify(x) for x in args]
    return _Pow.canonicalize(args)

cdef class _Pow(Basic):

    def __cinit__(self, args):
        self.type = POW
        self._args= args


    @classmethod
    def canonicalize(cls, args):
        cdef Basic base
        cdef Basic exp
        base, exp = args
        if base.type == INTEGER:
            if base.i == 0:
                return Integer(0)
            if base.i == 1:
                return Integer(1)
        if exp.type == INTEGER:
            if exp.i == 0:
                return Integer(1)
            if exp.i == 1:
                return base
        if base.type == POW:
            return Pow((base.args[0], base.args[1]*exp))
        return Pow(args, False)

    def __str__(self):
        s = str(self.args[0])
        if self.args[0].type == ADD:
            s = "(%s)" % s
        if self.args[1].type == ADD:
            s = "%s^(%s)" % (s, str(self.args[1]))
        else:
            s = "%s^%s" % (s, str(self.args[1]))
        return s

    def as_base_exp(self):
        return self.args

    def expand(self):
        base, exp = self.args
        if base.type == ADD and exp.type == INTEGER:
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
