#include "cache.h"
#include <stdio.h>

bool loadCache(device_t devices[MAX_DEVICES], size_t foundDevices,
	       const char *path)
{
	FILE *fp = fopen(path, "r");
	bool enabled = false;

	if (!fp)
		return false;

	if (fread(&enabled, sizeof(bool), 1, fp) < sizeof(bool))
	{
		fclose(fp);
		return false;
	}

	for (size_t i = 0; i < foundDevices; ++i)
	{
		device_t *dev = &devices[i];
		dev->enabled = enabled;
	}

	fclose(fp);
	return true;
}

bool saveCache(device_t devices[MAX_DEVICES], size_t foundDevices,
	       const char *path)
{
	FILE *fp = fopen(path, "w");
	bool enabled = false;

	if (!fp)
		return false;

	for (size_t i = 0; i < foundDevices; ++i)
	{
		device_t *dev = &devices[i];
		enabled |= dev->enabled;
	}

	fwrite(&enabled, sizeof(bool), 1, fp);

	return true;
}
