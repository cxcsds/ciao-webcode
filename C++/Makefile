#
# Makefile
#

# can we getthis set from env var?
ASCDS_INSTALL = /proj/ciaox

RM         = rm -f

C++        = /opt/SUNWspro_6.2/bin/CC
C++FLAGS   = +w -I$(ASCDS_INSTALL)/include -I$(ASCDS_INSTALL)/src/include

LINKCPP    =  $(C++) -L$(ASCDS_INSTALL)/lib 

DSOTS      = $(ASCDS_INSTALL)/ots

XERCES     = $(DSOTS)/xerces-c-src1_7_0
XERCESLIB  = -L$(XERCES)/lib -lxerces-c1_7_0

LIBHELP    = -lASCHelp $(XERCESLIB)
LIBGEN     = -lASCGen++ -lascgen

SRCS = list_seealso.cc
OBJS = $(SRCS:.cc=.o) 

COMPILE_CC = $(C++) $(C++FLAGS)

.cc.o:
	$(COMPILE_CC) -o $@ -c $<

help:
	@echo "Makefile targets:"
	@echo "  list_seealso"
	@echo " "

list_seealso:	Makefile $(OBJS)
	$(LINKCPP) -o $@ $@.o $(LIBHELP) $(LIBGEN)

