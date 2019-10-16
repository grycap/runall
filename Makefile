PACKAGE=runall
BINARIES=runall scpall
ETC=src/etc/*.conf
COMMONFILES=LICENSE src/version README.md
BINDIR=.
SRCDIR=./src
BASHC=bashc
BASHCFLAGS=-cRC
BINDEST=/usr/local/bin

BINS = $(patsubst %,$(BINDIR)/%,$(BINARIES))

all:	$(BINS)
	echo $(MODE)

$(BINDIR)/%:	$(SRCDIR)/%.bashc | $(BINDIR)
	$(BASHC) $(BASHCFLAGS) -o $@ $^

$(BINDIR):
	mkdir -p $(BINDIR)

clean:	
	rm $(BINS)

install-etc: $(ETC)
	@mkdir -p $(DESTDIR)/etc
	@for f in $(wildcard $^); do echo install -m 755 $$f $(DESTDIR)/etc; install -m 755 $$f $(DESTDIR)/etc; done

install-bin: $(BINS)
	@mkdir -p $(DESTDIR)$(BINDEST)
	@for f in $(wildcard $^); do echo install -m 755 $$f $(DESTDIR)$(BINDEST); install -m 755 $$f $(DESTDIR)$(BINDEST); done

install-common: $(COMMONFILES)
	@mkdir -p $(DESTDIR)/usr/share/$(PACKAGE)
	@for f in $(wildcard $^); do echo install -m 644 $$f $(DESTDIR)/usr/share/$(PACKAGE); install -m 644 $$f $(DESTDIR)/usr/share/$(PACKAGE); done

__check:
	$(if $(value DESTDIR),, $(error DESTDIR is not set)) 

install: __check install-common install-etc install-bin
	
