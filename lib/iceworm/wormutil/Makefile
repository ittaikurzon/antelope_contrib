LIB= libwormutil.a
DLIB=$(LIB:.a=$(DSUFFIX)) 

MAN3= libwormutil.3

INCLUDE=chron3.h \
	kom.h \
	mem_circ_queue.h \
	parse_trig.h \
	site.h \
	swap.h \
	tlay.h \
	earthworm.h \
	earthworm_defs.h \
	earthworm_simple_funcs.h \
	earthworm_complex_funcs.h \
	platform.h


cflags=	-D_SPARC -D_SOLARIS -D_LOGITMT

include $(ANTELOPEMAKE)
		
OBJS= 	chron3.o \
	getutil.o \
	kom.o \
	logit.o \
	site.o \
	tlay.o \
	mnbrak.o \
	brent.o \
	swap.o \
	socket_ew_common.o \
	mem_circ_queue.o

$(LIB) : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(LORDER) $(OBJS) $(TSORT)
	$(RANLIB) $@

$(DLIB) : $(OBJS)
	$(DLD) $(DLDFLAGS) $(LDLIBS) -o $(DLIB) $(LORDER) $(OBJS) $(TSORT)
