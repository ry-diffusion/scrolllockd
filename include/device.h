#pragma once
#include <libevdev/libevdev.h>

#define MAX_DEVICES 128
#define MAX_DEVICE_PATH 280
typedef struct {
  const char *path;
} device_t;

char scanDevices(device_t devices[MAX_DEVICES]);
