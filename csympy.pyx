cdef extern from "stdlib.h":
    ctypedef int size_t
    void *malloc (size_t size)

cdef extern from "stdint.h":
    ctypedef long long int64_t
    ctypedef int64_t sympyint

cdef extern from "glib.h":
    ctypedef unsigned guint
    ctypedef void *gconstpointer
    guint g_int_hash(gconstpointer v)
    guint g_str_hash(gconstpointer v)

def int_hash(int v):
    return g_int_hash(&v)

def str_hash(char *v):
    return g_str_hash(v)

cdef class Basic:

    def __str__(self):
        return self.thisptr.__str__(self.thisptr)

    def __repr__(self):
        return str(self)

    def __hash__(self):
        return self.thisptr.__hash__(self.thisptr)
