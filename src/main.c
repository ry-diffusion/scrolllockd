#include <device.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

int main(void) {
  device_t devices[MAX_DEVICES];

  if (!scanDevices(devices)) {
    fprintf(stderr,
            "Error: Unable to scan devices. Are you root?\n Reason: %s\n",
            strerror(errno));

    goto error;
  }

  return 0;

error:
  return 1;
}
