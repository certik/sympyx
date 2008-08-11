cdef extern from "stdlib.h":
    ctypedef int size_t
    void *malloc (size_t size)

cdef extern from "Python.h":
    ctypedef void PyObject
    void Py_INCREF(PyObject *x)
    void Py_DECREF(PyObject *x)

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
    gpointer g_hash_table_lookup(GHashTable *hash_table, gconstpointer key)
    guint g_hash_table_size(GHashTable *hash_table)
    void g_hash_table_destroy(GHashTable *hash_table)
    void g_hash_table_iter_init(GHashTableIter *iter, GHashTable *hash_table)
    gboolean g_hash_table_iter_next(GHashTableIter *iter,
            gpointer *key, gpointer *value)

def int_hash(int v):
    return g_int_hash(&v)

def str_hash(char *v):
    return g_str_hash(v)

cdef class Table:
    cdef GHashTable *thisptr

    def __init__(self):
        self.thisptr = g_hash_table_new(NULL, NULL)

    def __dealloc__(self):
        g_hash_table_destroy(self.thisptr)

    def __setitem__(self, x, y):
        self.insert(x, y)

    def __getitem__(self, x):
        return self.get(x)

    def __contains__(self, x):
        try:
            self.get(x)
        except KeyError:
            return False
        return True

    def __len__(self):
        return g_hash_table_size(self.thisptr)

    def insert(self, key, coeff):
        g_hash_table_insert(self.thisptr, <gpointer>key, <gpointer>coeff)
        # Without the following it sometimes segfaults, but maybe the INCREF
        # should be put at some other place:
        Py_INCREF(<PyObject *>key)
        Py_INCREF(<PyObject *>coeff)

    def get(self, key):
        cdef gpointer value
        value = g_hash_table_lookup(self.thisptr, <gconstpointer>key)
        if value == NULL:
            raise KeyError(key)
        return <object>value

    def iteritems(self):
        cdef GHashTableIter iter

        g_hash_table_iter_init (&iter, self.thisptr);
        cdef gpointer key, value

        a = []
        while g_hash_table_iter_next(&iter, &key, &value):
            a.append((<object>key, <object>value))
        return a

cdef guint my_hash(gconstpointer v):
    o= <object>v
    return hash(o)

cdef gboolean my_equal(gconstpointer a, gconstpointer b):
    o1 = <object>a
    o2 = <object>b
    return o1 == o2


cdef class HashTable(Table):

    def __init__(self):
        self.thisptr = g_hash_table_new(&my_hash, &my_equal)
