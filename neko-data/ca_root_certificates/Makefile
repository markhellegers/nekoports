all:
	mkdir -p certs
	awk -f Makefile_files/split_certificates.awk cacert.pem

install:
	mkdir -p $(DESTDIR)/usr/nekoware/certs
	cp certs/*.pem $(DESTDIR)/usr/nekoware/certs
