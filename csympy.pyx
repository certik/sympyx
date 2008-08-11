cdef extern from "stdlib.h":
    ctypedef int size_t
    void *malloc (size_t size)

cdef extern from "stdint.h":
    ctypedef long long int64_t
    ctypedef int64_t sympyint

cdef extern from "glib.h":
    ctypedef unsigned guint

cdef class Basic:

    def __str__(self):
        return self.thisptr.__str__(self.thisptr)

    def __repr__(self):
        return str(self)

    def __hash__(self):
        return self.thisptr.__hash__(self.thisptr)
