#include <device.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

void closeDevices(device_t devices[MAX_DEVICES], unsigned int devicesFound) {
  for (unsigned int idx = 0; idx < devicesFound; ++idx) {
    device_t dev = devices[idx];
    closeDevice(&dev);
  }
}

int main(void) {
  device_t devices[MAX_DEVICES];
  unsigned int devicesFound = 0;

  if (!scanDevices(devices, &devicesFound)) {
    fprintf(stderr,
            "Error: Unable to scan devices. Are you root?\n Reason: %s\n",
            strerror(errno));

    goto error;
  }

  closeDevices(devices, devicesFound);
  return 0;

error:
  closeDevices(devices, devicesFound);
  return 1;
}
