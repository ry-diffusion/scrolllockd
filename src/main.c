#include <device.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

device_t devices[MAX_DEVICES];
unsigned int devicesFound = 0;

void closeDevices(device_t devices[MAX_DEVICES], unsigned int devicesFound) {
  for (unsigned int idx = 0; idx < devicesFound; ++idx) {
    device_t dev = devices[idx];
    closeDevice(&dev);
  }
}

void onDrop(int signal) {
  (void)signal;
  closeDevices(devices, devicesFound);
  exit(0);
}

int main(void) {
  unsigned int idx = 0;
  if (!scanDevices(devices, &devicesFound)) {
    goto error;
  }

  signal(SIGTERM, onDrop);
  signal(SIGQUIT, onDrop);
  signal(SIGINT, onDrop);

  while (1) {
    for (idx = 0; idx < devicesFound; ++idx) {
      if (!handleDevice(&devices[idx])) {
        goto error;
      }
    }

    usleep(50 * 1000);
  }

  return 0;

error:
  fprintf(stderr, "Error: %s\n", strerror(errno));
  closeDevices(devices, devicesFound);
  return 1;
}
