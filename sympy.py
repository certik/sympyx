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

    except ImportError:
        print
        print 'W: can\'t import sympy_pyx -- will be pure python'
        xy_gather_line = xy_gather_line_py

    else:
        _mode = 'pyx'


if _mode == 'pyx':
    from sympy_pyx import *
else:
    from sympy_py import *
