#
# Makefile
#   - Use GNU Make (so gmake on solaris)
#   - start up CIAO before using as we need the ASCDS_INSTALL
#     environment set correctly
#   - make sure that the CIAO environment contains at least the
#     ciao-beta3-4.0-src-core.tar.gz file (cxcconfig.h) and
#     run ./configure --with-compile to generate config.h
#

DSOTS      = $(ASCDS_INSTALL)/ots

# Need to find cxcconfig.h and config.h, hence the complicated
# set of includes.
#
INCDIR     = -I$(ASCDS_INSTALL)/include -I$(DSOTS)/include \
		-I$(ASCDS_INSTALL)/src/include -I$(ASCDS_INSTALL)

RM         = rm -f

# Solaris (probably need to change the location of CC)
#C++        = /opt/SUNWspro_6.2/bin/CC
#C++FLAGS   = +w $(INCDIR)

# OS-X and Linux
C++        = g++
C++FLAGS   = $(INCDIR)

LINKCPP    =  $(C++) -L$(ASCDS_INSTALL)/lib 

XERCESLIB  = -L$(DSOTS)/lib -lxerces-c

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

