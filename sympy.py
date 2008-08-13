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

    except ImportError, e:
        print
        print '   %s' % e
        print 'W: can\'t import sympy_pyx -- will be pure python'

    else:
        print 'ok'
        _mode = 'pyx'


if _mode == 'pyx':
    from sympy_pyx import *
else:
    from sympy_py import *



# for debugging
x = Symbol('x')
y = Symbol('y')
i = Integer(2)

x2= Symbol('x')


e = (x+y)**2
