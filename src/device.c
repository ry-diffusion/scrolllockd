#include <device.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <libevdev/libevdev.h>
#include <linux/input.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define isEvent(item) item[0] == 'e'

struct libevdev *openDevice(const char *restrict eventFile)
{
	char devicePath[MAX_DEVICE_PATH] = "/dev/input/";
	struct libevdev *eDev;
	int fd, res;
	unsigned int idx = 11;

	while (*eventFile && idx <= MAX_DEVICE_PATH)
		devicePath[idx++] = *eventFile++;

	devicePath[idx++] = '\0';

	fd = open(devicePath, O_RDWR | O_NONBLOCK);

	if (fd < 0)
		return NULL;

	res = libevdev_new_from_fd(fd, &eDev);

	if (res < 0)
	{
		close(fd);
		return NULL;
	}

	if (!libevdev_has_event_code(eDev, EV_KEY, KEY_SCROLLLOCK))
	{
		libevdev_free(eDev);
		close(fd);
		return NULL;
	}

	return eDev;
}

char scanDevices(device_t devices[MAX_DEVICES],
		 unsigned int *restrict devicesFound)
{
	struct dirent *d;
	DIR *dp;
	struct libevdev *eDev;
	device_t dev;

	dp = opendir("/dev/input/");

	if (!dp)
		return false;

	while ((d = readdir(dp)) != NULL)
		if (isEvent(d->d_name))
		{
			eDev = openDevice(d->d_name);

			if (!eDev)
				continue;

			dev.eDev = eDev;
			dev.enabled = false;

			devices[(*devicesFound)++] = dev;
		}

	closedir(dp);
	return true;
}

void closeDevice(device_t *device)
{
	close(libevdev_get_fd(device->eDev));
	libevdev_free(device->eDev);
}

char handleDevice(device_t *device)
{
	struct input_event event;
	int res;

	if ((res = libevdev_kernel_set_led_value(
		 device->eDev, LED_SCROLLL,
		 device->enabled ? LIBEVDEV_LED_ON : LIBEVDEV_LED_OFF)) < 0)
		fprintf(stderr, "[[warning:setLed]] %s\n", strerror(-res));

	res = libevdev_next_event(device->eDev, LIBEVDEV_READ_FLAG_NORMAL,
				  &event);

	if (res == -EAGAIN)
		return true;

	if (res != LIBEVDEV_READ_STATUS_SUCCESS &&
	    res != LIBEVDEV_READ_STATUS_SYNC)
		return false;

	if (event.type == EV_KEY && event.value && event.code == KEY_SCROLLLOCK)
		device->enabled = !device->enabled;

	return true;
}
