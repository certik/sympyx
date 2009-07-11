from sympy import x, y, Symbol
from test_extensibility import Constant

e = x + y
A = Constant("A", x)
    #print e
    #rint "-"*40
    #rint e + A
    #rint "-"*40
    #rint y+A + e
    #rint "-"*40
    #print x + y + A + x + y
    #rint x + A + x
    #rint A + y
    #rint A+x+y

    #f = e + A + x
    #print f
    #print f + y
    # assert C+x+y+x*y+2 == C+x+x*y
print A+x+y+x*y+2
    # assert C+x+2**x+y+2 == C+x+2**x
print A+x+2**x+y+2

