const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const fmt = std.fmt;

const Device = @import("devices.zig").Device;
pub const DeviceEntry = struct { device: Device, enabled: bool };
pub const Devices = std.StringHashMap(DeviceEntry);

pub const State = struct {
    path: []const u8,
    alloc: mem.Allocator,

    pub fn open(path: []const u8, alloc: mem.Allocator) State {
        return State{
            .path = path,
            .alloc = alloc,
        };
    }

    pub fn read(self: State, items: Devices) !void {
        const file = try fs.openFileAbsolute(self.path, .{
            .mode = fs.File.OpenMode.read_only,
        });

        defer file.close();

        const stat = try file.stat();
        var buffer = try self.alloc.alloc(u8, stat.size);
        defer self.alloc.free(buffer);

        _ = try file.read(buffer);
        var lines = mem.splitScalar(u8, buffer, '\n');

        while (lines.next()) |line| {
            var section = mem.splitScalar(u8, line, ':');

            const raw_enabled = section.next() orelse
                continue;

            const device_name = section.next() orelse
                continue;

            const enabled = raw_enabled[0] == '1';

            var it = items.iterator();

            while (it.next()) |entry| {
                if (mem.eql(u8, entry.key_ptr.*, device_name)) {
                    entry.value_ptr.*.enabled = enabled;
                }
            }
        }
    }

    pub fn write(self: State, items: Devices) !void {
        const file = try fs.openFileAbsolute(self.path, .{
            .mode = fs.File.OpenMode.write_only,
        });

        defer file.close();
        var it = items.iterator();

        while (it.next()) |entry| {
            const name = entry.key_ptr.*;
            const deviceEntry: DeviceEntry = entry.value_ptr.*;

            try fmt.format(file.writer(), "{}:{s}\n", .{
                @intFromBool(deviceEntry.enabled),
                name,
            });
        }
    }
};
