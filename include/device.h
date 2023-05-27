#pragma once
#include <libevdev/libevdev.h>

#define MAX_DEVICES 128
#define MAX_DEVICE_PATH 280

typedef struct {
  struct libevdev *eDev;
  char enabled;
} device_t;

char scanDevices(device_t devices[MAX_DEVICES], unsigned int *devicesFound);
void closeDevice(device_t *device);
char handleDevice(device_t *device);
