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

SRC = main.ec lecture.ec timetable.ec classinfo.ec status.ec
OBJ = $(SRC:.ec=.o)
PROG = register

all: $(PROG)

.ec.o:
	$(SQL) $(SQLFLAGS) $< 
	@chmod go-rwx main.c

$(PROG): $(OBJ)
	$(SQL) -o $@ $(OBJ)

clean:
	$(RM) -f *.o *~ core *.c $(OBJ) $(PROG)
