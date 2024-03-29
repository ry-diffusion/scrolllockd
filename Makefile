PREFIX ?= /usr/local
ZIG = zig

.PHONY: systemd prepare 

install:
	$(ZIG) build -Doptimize=ReleaseSmall install --prefix $(PREFIX)

systemd:
	mkdir -p $(PREFIX)/lib/systemd/system
	cp systemd/scrolllockd.service $(PREFIX)/lib/systemd/system

prepare:
	mkdir -p /var/db/scrolllockd
	touch /var/db/scrolllockd/kbd.state

