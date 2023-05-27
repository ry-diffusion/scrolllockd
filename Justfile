BUILD_DIR := "build"

setup:
  meson setup {{BUILD_DIR}}

build:
  meson compile -C {{BUILD_DIR}}


install: build
  ninja install -C {{BUILD_DIR}}

uninstall:
  ninja uninstall -C {{BUILD_DIR}}