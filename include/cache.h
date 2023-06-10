#pragma once
#include "device.h"
#include "stdbool.h"

bool loadCache(device_t devices[MAX_DEVICES], size_t foundDevices,
	       const char *path);

bool saveCache(device_t devices[MAX_DEVICES], size_t foundDevices,
	       const char *path);
