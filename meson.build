project('scrolllockd', 'c',
  version : '23.03.02',
  default_options : ['warning_level=3', 'prefix=/usr/local'])

dep_evdev = dependency('libevdev')

exe = executable('scrolllockd', [ 'src/main.c', 'src/device.c', 'src/cache.c' ],
  dependencies : [ dep_evdev ],
  include_directories : [ 'include' ],
  install : true)

if get_option('enable_systemd')
  install_data('misc/scrolllockd.service', install_dir : get_option('prefix') / 'lib' / 'systemd' / 'system')
endif
