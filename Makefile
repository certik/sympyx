all: csympy.so

CFLAGS=-g
#CFLAGS=-O3
PYVER=2.5

csympy.c: csympy.pyx
	cython --convert-range csympy.pyx

csympy.o: csympy.c
	gcc -fPIC $(CFLAGS) -I/usr/include/python$(PYVER) -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include/ -c -o csympy.o csympy.c

csympy.so: csympy.o
	gcc -shared csympy.o -o csympy.so -lglib-2.0

clean:
	rm -f csympy.so csympy.o csympy.c csympy_api.h
	rm -f *.pyc
