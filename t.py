#! /usr/bin/env python

from csympy import int_hash, str_hash, HashTable, Table

print int_hash(5)
print int_hash(6)
print int_hash(0)
print int_hash(1)
print int_hash(-1)

print

print str_hash("ano")
print str_hash("ne")
print str_hash("n")

print "hash"
h = HashTable()
h.insert(1, 2)
h.insert(3, 5)
h.insert(2, "ano")
print h.list()

print "hash"
h = HashTable()
h.insert(3, 5)
h.insert(2, "ano")
h.insert(1, 2)
print h.list()
