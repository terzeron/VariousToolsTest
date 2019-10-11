CFLAGS+= -c -Wall
LDFLAGS+= -lpcap
RM=rm -f

EXE= arp_proxy
SRCS= alias.c
OBJS= $(SRCS:.c=.o)

.c.o:
	$(CC) $< $(CFLAGS)
all: $(EXE)
$(EXE): $(OBJS)
	$(CC) -o $(EXE) $(OBJS) $(LDFLAGS)
clean:
	$(RM) *.c~ $(OBJS) $(EXE)
