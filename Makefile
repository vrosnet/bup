OS:=$(shell uname | sed 's/[-_].*//')
CFLAGS=-Wall -g -O2 -Werror $(PYINCLUDE) -g
ifneq ($(OS),CYGWIN)
  CFLAGS += -fPIC
endif
SHARED=-shared
SOEXT:=.so

ifeq (${OS},Darwin)
  MACHINE:=$(shell arch)
  CFLAGS += -arch $(MACHINE)
  SHARED = -dynamiclib
endif
ifeq ($(OS),CYGWIN)
  LDFLAGS += -L/usr/bin
  EXT:=.exe
  SOEXT:=.dll
endif

default: all

all: bup-split bup-join bup-save bup-init bup-server bup-index bup-tick \
	bup-midx bup-fuse bup-ls bup-damage bup-fsck bup-margin bup-drecurse \
	bup-random \
	bup memtest _hashsplit$(SOEXT) \
	Documentation/all
	
%/all:
	$(MAKE) -C $* all
	
%/clean:
	$(MAKE) -C $* clean

_hashsplit$(SOEXT): _hashsplit.c csetup.py
	@rm -f $@
	python csetup.py build
	cp build/*/_hashsplit$(SOEXT) .
	
runtests: all runtests-python runtests-cmdline

runtests-python:
	./wvtest.py $(wildcard t/t*.py)
	
runtests-cmdline: all
	t/test.sh
	
stupid:
	PATH=/bin:/usr/bin $(MAKE) test
	
test: all
	./wvtestrun $(MAKE) runtests

%: %.o
	$(CC) $(CFLAGS) (LDFLAGS) -o $@ $^ $(LIBS)
	
bup: bup.py
	rm -f $@
	ln -s $< $@
	
bup-%: cmd-%.py
	rm -f $@
	ln -s $< $@
	
%: %.py
	rm -f $@
	ln -s $< $@
	
bup-%: cmd-%.sh
	rm -f $@
	ln -s $< $@
	
%.o: %.c
	gcc -c -o $@ $< $(CPPFLAGS) $(CFLAGS)

clean: Documentation/clean
	rm -f *.o *.so *.dll *.exe *~ .*~ *.pyc */*.pyc */*~ \
		bup bup-* randomgen memtest \
		out[12] out2[tc] tags[12] tags2[tc]
	rm -rf *.tmp build
