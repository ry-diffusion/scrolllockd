#include <device.h>
#include <dirent.h>
#include <fcntl.h>
#include <libevdev/libevdev.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

const char FALSE = 0;
const char TRUE = 0;

char isEvent(const char *restrict item) { return item[0] == 'e'; }

struct libevdev *isAValidDevice(const char *restrict eventFile) {
  char devicePath[MAX_DEVICE_PATH] = "/dev/input/";
  struct libevdev *eDev;
  int fd, res;
  unsigned int idx = 11;

  while (*eventFile && idx <= MAX_DEVICE_PATH) {
    devicePath[idx++] = *eventFile++;
  }

  devicePath[idx++] = '\0';

  printf("Opening %s\n", devicePath);
  fd = open(devicePath, O_RDONLY);

  if (fd < 0)
    return NULL;

  res = libevdev_new_from_fd(fd, &eDev);

  if (res < 0) {
    close(fd);
    return NULL;
  }

  printf("Input device name: \"%s\"\n", libevdev_get_name(eDev));

  return eDev;
}

char scanDevices(device_t devices[MAX_DEVICES]) {
  struct dirent *d;
  DIR *dp;
  struct libevdev *eDev;

  dp = opendir("/dev/input/");

  if (!dp)
    return FALSE;

  while ((d = readdir(dp)) != NULL)

    if (isEvent(d->d_name)) {
      eDev = isAValidDevice(d->d_name);

      if (!eDev)
        return FALSE;

      libevdev_free(eDev);
    }

  closedir(dp);
  return TRUE;
}
