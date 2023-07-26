pub const c =
    @cImport(@cInclude("libevdev-1.0/libevdev/libevdev.h"));

const std = @import("std");
const fs = std.fs;
const math = std.math;

pub const Device = struct {
    repr: ?*c.struct_libevdev,
    file: fs.File,

    pub fn open(path: []const u8) !Device {
        var repr: ?*c.struct_libevdev = null;

        const file = try fs.openFileAbsolute(path, .{
            .mode = fs.File.OpenMode.read_write,
            .lock_nonblocking = false,
        });

        const res = c.libevdev_new_from_fd(file.handle, &repr);

        if (res != 0) {
            const errno: u16 = @intCast(try math.absInt(res));
            return @errorFromInt(errno);
        }

        return Device{ .file = file, .repr = repr };
    }

    pub fn getNameZ(self: Device) [*:0]const u8 {
        const cString = c.libevdev_get_name(self.repr);
        const nameZ: [*:0]const u8 = cString;
        return nameZ;
    }

    pub fn poll(self: Device) ?c.input_event {
        var event: c.input_event = .{
            .time = .{
                .tv_sec = 0,
                .tv_usec = 0,
            },
            .type = 0,
            .code = 0,
            .value = 0,
        };

        if (c.libevdev_has_event_pending(self.repr) == 0) return null;

        const res = c.libevdev_next_event(self.repr, c.LIBEVDEV_READ_FLAG_NORMAL, &event);
        _ = res;

        // if ((res != c.LIBEVDEV_READ_STATUS_SUCCESS) or
        //     (res != c.LIBEVDEV_READ_STATUS_SYNC))
        // {
        //     return null;
        // }

        return event;
    }

    pub fn setLed(self: Device, code: u32, value: bool) !void {
        const c_value: u32 = switch (value) {
            true => c.LIBEVDEV_LED_ON,
            else => c.LIBEVDEV_LED_OFF,
        };

        const res = c.libevdev_kernel_set_led_value(self.repr, code, c_value);

        if (res != 0) {
            const errno: u16 = @intCast(try math.absInt(res));
            return @errorFromInt(errno);
        }
    }

    pub fn hasEventCode(self: Device, kind: u32, event: u32) bool {
        return c.libevdev_has_event_code(self.repr, kind, event) != 0;
    }

    pub fn close(self: Device) void {
        c.libevdev_free(self.repr);
        self.file.close();
    }
};
