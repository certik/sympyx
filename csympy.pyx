cdef extern from "stdlib.h":
    ctypedef int size_t
    void *malloc (size_t size)

cdef extern from "Python.h":
    ctypedef void PyObject

cdef extern from "stdint.h":
    ctypedef long long int64_t
    ctypedef int64_t sympyint

cdef extern from "glib.h":
    ctypedef unsigned guint
    ctypedef void *gconstpointer
    ctypedef void *gpointer
    ctypedef int gboolean
    guint g_int_hash(gconstpointer v)
    guint g_str_hash(gconstpointer v)

    ctypedef struct GHashTable
    ctypedef struct GHashTableIter:
        pass
    #guint (*GHashFunc) (gconstpointer key)
    #gboolean (*GEqualFunc) (gconstpointer a, gconstpointer b)
    ctypedef void * GHashFunc
    ctypedef void * GEqualFunc

    GHashTable *g_hash_table_new(GHashFunc hash_func, GEqualFunc key_equal_func)
    void g_hash_table_insert(GHashTable *hash_table,
            gpointer key, gpointer value)
    void g_hash_table_destroy(GHashTable *hash_table)
    void g_hash_table_iter_init(GHashTableIter *iter, GHashTable *hash_table)
    gboolean g_hash_table_iter_next(GHashTableIter *iter,
            gpointer *key, gpointer *value)

def int_hash(int v):
    return g_int_hash(&v)

def str_hash(char *v):
    return g_str_hash(v)

cdef class HashTable:
    cdef GHashTable *thisptr

    def __init__(self):
        self.thisptr = g_hash_table_new(&g_int_hash, NULL)

    def __dealloc__(self):
        g_hash_table_destroy(self.thisptr)

    def insert(self, key, coeff):
        g_hash_table_insert(self.thisptr, <gpointer>key, <gpointer>coeff)

    def list(self):
        cdef GHashTableIter iter

        g_hash_table_iter_init (&iter, self.thisptr);
        cdef gpointer key, value

        a = []
        while g_hash_table_iter_next(&iter, &key, &value):
            a.append((<object>key, <object>value))
        return a
