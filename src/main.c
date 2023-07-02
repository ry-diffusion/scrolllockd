#include "cache.h"
#include <device.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

device_t devices[MAX_DEVICES];
unsigned int devicesFound = 0;
const char *path = "/var/lib/scrollockd.state";

void closeDevices(device_t devices[MAX_DEVICES], unsigned int devicesFound)
{
	saveCache(devices, devicesFound, path);
	for (unsigned int idx = 0; idx < devicesFound; ++idx)
		closeDevice(&devices[idx]);
}

void onDrop(int signal)
{
	(void)signal;
	closeDevices(devices, devicesFound);
	exit(0);
}

int main(void)
{
	unsigned int idx = 0;

	if (!scanDevices(devices, &devicesFound))
		goto error;

	signal(SIGTERM, onDrop);
	signal(SIGQUIT, onDrop);
	signal(SIGINT, onDrop);

	if (!loadCache(devices, devicesFound, path))
	{
		perror("[[error:loadCache]]");
	}

	if (!devicesFound)
	{
		fprintf(stderr, "[[error:scanDevices]] Unable to find any "
				"device. Are you root?\n");
		return 1;
	}

	while (1)
	{
		for (idx = 0; idx < devicesFound; ++idx)
			if (!handleDevice(&devices[idx]))
				goto error;

		usleep(50 * 1000);
	}

	return 0;

error:
	fprintf(stderr, "Error: %s\n", strerror(errno));
	closeDevices(devices, devicesFound);
	return 1;
}
