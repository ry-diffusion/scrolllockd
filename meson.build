project('scrolllockd', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])

dep_evdev = dependency('libevdev')

exe = executable('scrolllockd', [ 'src/main.c', 'src/device.c' ],
  dependencies : [ dep_evdev ],
  include_directories : [ 'include' ],
  install : true)

test('basic', exe)
