#! /usr/bin/env python

from csympy import int_hash, str_hash

print int_hash(5)
print int_hash(6)
print int_hash(0)
print int_hash(1)
print int_hash(-1)

print

print str_hash("ano")
print str_hash("ne")
print str_hash("n")
