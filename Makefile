

PYTHON	:= python
CYTHON	:= cython --convert-range
CC	:= gcc
CFLAGS	:= \
    	$(shell $(PYTHON)-config --includes)	\
    	$(shell pkg-config glib-2.0 --cflags)

LIBS	:= -lglib-2.0

CFLAGS	+= -g -O0	# -O3


all	: csympy.so sympy_pyx.so




# rules
%.c	: %.pyx
	$(CYTHON) $<

%.o	: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<


%.so	: %.o
	$(CC) $(LDFLAGS) -shared $+ -o $@ $(LIBS)

# keep those *.o and *.so files
.SECONDARY:

clean:
	rm -f *.so *.pyd *.o csympy.c csympy_api.h
	rm -f *.pyc

