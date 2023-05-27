project('scrolllockd', 'c',
  version : '0.1',
  default_options : ['warning_level=3', 'prefix=/usr/local'])

dep_evdev = dependency('libevdev')

exe = executable('scrolllockd', [ 'src/main.c', 'src/device.c' ],
  dependencies : [ dep_evdev ],
  include_directories : [ 'include' ],
  install : true)

install_data('misc/scrolllockd.service', install_dir : get_option('prefix') / 'lib' / 'systemd' / 'system')
