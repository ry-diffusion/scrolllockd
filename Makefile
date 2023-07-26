PREFIX ?= /usr/local

install:
	zig build  -Doptimize=ReleaseFast install --prefix $(PREFIX)

systemd:
	mkdir -p $(PREFIX)/lib/systemd/system
	cp systemd/scrolllockd.service $(PREFIX)/lib/systemd/system

prepare:
	mkdir -p /var/lib/scrolllockd
	touch /var/lib/scrolllockd/led.state

