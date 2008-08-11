BASIC   = 0
SYMBOL  = 1
ADD     = 2
MUL     = 3
POW     = 4
INTEGER = 5

def hash_seq(args):
    # make this more robust:
    m = 2
    for x in args:
        m = hash(m + 1001 ^ hash(x))
    return m

class Basic(object):

    def __new__(cls, type, args):
        obj = object.__new__(cls)
        obj.type = type
        obj._args = args
        return obj

    def __repr__(self):
        return str(self)

    def __hash__(self):
        return hash_seq(self.args)

    @property
    def args(self):
        return self._args

    def as_coeff_rest(self):
        return (Integer(1), self)

    def as_base_exp(self):
        return (self, Integer(1))

    def __add__(x, y):
        return Add((x, y))

    def __sub__(x, y):
        return Add((x, -y))

    def __mul__(x, y):
        return Mul((x, y))

    def __pow__(x, y):
        return Pow((x, y))

    def __neg__(x):
        return Mul((Integer(-1), x))


class Integer(Basic):

    def __new__(cls, i):
        obj = Basic.__new__(cls, INTEGER, [])
        obj.i = i
        return obj

    def __str__(self):
        return str(self.i)

    def __add__(self, o):
        if o.type == INTEGER:
            return Integer(self.i+o.i)
        return NotImplemented

    def __mul__(self, o):
        if o.type == INTEGER:
            return Integer(self.i*o.i)
        return NotImplemented


class Symbol(Basic):

    def __new__(cls, name):
        obj = Basic.__new__(cls, SYMBOL, [])
        obj.name = name
        return obj

    def __hash__(self):
        return hash(self.name)

    def __str__(self):
        return self.name


class Add(Basic):

    def __new__(cls, args, canonicalize=True):
        if canonicalize == False:
            obj = Basic.__new__(cls, ADD, args)
            return obj
        args = [sympify(x) for x in args]
        return Add.canonicalize(args)

    @classmethod
    def canonicalize(cls, args):
        d = {}
        #print args
        for a in args:
            if a.type == ADD:
                for b in a.args:
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
        print d
        args = []
        for a, b in d.iteritems():
            args.append(Mul((a, b)))

        return Add(args, False)

    def __str__(self):
        s = str(self.args[0])
        if self.args[0].type == ADD:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            s = "%s + %s" % (s, str(x))
            if x.type == ADD:
                s = "(%s)" % s
        return s

class Mul(Basic):

    def __new__(cls, args, canonicalize=True):
        if canonicalize == False:
            obj = Basic.__new__(cls, MUL, args)
            return obj
        args = [sympify(x) for x in args]
        return Mul.canonicalize(args)

    @classmethod
    def canonicalize(cls, args):
        d = {}
        num = Integer(1)
        for a in args:
            if a.type == INTEGER:
                num *= a
            elif a.type == MUL:
                for b in a.args:
                    coeff, key = b.as_base_exp()
                    if key in d:
                        d[key] += coeff
                    else:
                        d[key] = coeff
            else:
                coeff, key = a.as_base_exp()
                if key in d:
                    d[key] += coeff
                else:
                    d[key] = coeff
        if num.i == 0:
            return num
        args = []
        for a, b in d.iteritems():
            args.append(Pow((b, a)))
        if num.i != 1:
            args.insert(0, num)
        if len(args) == 1:
            return args[0]
        else:
            return Mul(args, False)

    def __hash__(self):
        a = self.args[:]
        a.sort(key=hash)
        return hash_seq(a)

    def __eq__(self, o):
        if o.type == MUL:
            a = self.args[:]
            a.sort(key=hash)
            b = o.args[:]
            b.sort(key=hash)
            return a == b
        else:
            return False


    def as_coeff_rest(self):
        if self.args[0].type == INTEGER:
            return (self.args[0], Mul(self.args[1:]))
        return (Integer(1), self)

    def __str__(self):
        s = str(self.args[0])
        if self.args[0].type == MUL:
            s = "(%s)" % str(s)
        for x in self.args[1:]:
            s = "%s*%s" % (s, str(x))
            if x.type == MUL:
                s = "(%s)" % s
        return s

class Pow(Basic):

    def __new__(cls, args, canonicalize=True):
        if canonicalize == False:
            obj = Basic.__new__(cls, MUL, args)
            return obj
        args = [sympify(x) for x in args]
        return Pow.canonicalize(args)

    @classmethod
    def canonicalize(cls, args):
        base, exp = args
        if exp.type == INTEGER:
            if exp.i == 0:
                return Integer(1)
            if exp.i == 1:
                return base
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

def sympify(x):
    if isinstance(x, int):
        return Integer(x)
    return x