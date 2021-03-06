import sympy_py
_mode = 'py'

import os
if os.getenv('SYMPY_PY', '').lower() in ['y', 'yes']:
    print 'I: forced to be pure python'

else:
    try:
        # XXX better not * ?
        print 'I: import sympy_pyx ...',
        from sympy_pyx import *

        # XXX figure out how to put this into sympy_pyx.pyx:
        BASIC   = 0
        SYMBOL  = 1
        ADD     = 2
        MUL     = 3
        POW     = 4
        INTEGER = 5

        from sympy_pyx import _Basic

        # Cython/Pyrex do not support __new__, so we have to define Basic here
        class Basic(_Basic):

            def __new__(cls, args):
                o = _Basic.__new__(cls)
                o._set_rawargs(tuple(args))
                return o


    except ImportError, e:
        print 'fail  (%s)' % e
        print 'W: can\'t import sympy_pyx -- will be pure python'

    else:
        print 'ok'
        _mode = 'pyx'


if _mode == 'pyx':
    from sympy_pyx import *
else:
    from sympy_py import *

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
            sym = Symbol(t)
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
        del frame



# for debugging
x = Symbol('x')
y = Symbol('y')
z = Symbol('z')
i = Integer(2)

x2= Symbol('x')


e = (x+y)**2


class sin(Basic):

    def __new__(cls, arg):
        if arg == 0:
            return Integer(0)
        else:
            obj = Basic.__new__(cls, (arg,))
            return obj

    def __repr__(self):
        return "sin(%s)" % self.args[0]

