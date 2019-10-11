.SUFFIXES:
.SUFFIXES: .ec .c .o

SQL = esql
RM = rm
AR = ar

SQLFLAGS = -g -c
CCFLAGS =
WARNINGFLAGS = 
HDR = -I. -I/usr/include -I/extra/informix/incl/esql
LIB = 

INCFLAGS = $(HDR)
LIBFLAGS = $(LIB)

SRC = st_main.ec st_add.ec
OBJ = $(SRC:.ec=.o)
PROG = stock

all: $(PROG)

.ec.o:
	$(SQL) $(SQLFLAGS) $< 

$(PROG): $(OBJ)
	$(SQL) -o $@ $(OBJ)

clean:
	$(RM) -f *.o *~ core $(SRC:.ec=.c) $(OBJ) $(PROG)
