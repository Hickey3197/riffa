TARGETS   = vec-accum vecadd-double vecadd-float
LIBS      = -lpthread -lriffa
CPPFLAGS  = -I../host
TOOL_SRCS = ../host/fpga-tools-riffa.c ../host/fpga-tools.c

all: $(TARGETS)

%: %-host.c $(TOOL_SRCS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(TOOL_SRCS) $< -o $@ $(LIBS)

clean:
	-rm -rf $(TARGETS) a.out *~

