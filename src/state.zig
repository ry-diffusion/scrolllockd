const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Device = @import("devices.zig").Device;
const fmt = std.fmt;

pub const State = struct {
    path: []const u8,
    alloc: mem.Allocator,

    pub fn open(path: []const u8, alloc: mem.Allocator) !State {
        return State{
            .path = path,
            .alloc = alloc,
        };
    }

    pub fn read(self: State, items: std.AutoHashMap(Device, bool)) !void {
        const file = try fs.openFileAbsolute(self.path, .{
            .mode = fs.File.OpenMode.read_only,
        });
        defer file.close();

        const stat = try file.stat();
        var buffer = try self.alloc.alloc(u8, stat.size);
        _ = try file.read(buffer);
        var lines = mem.splitScalar(u8, buffer, '\n');

        while (lines.next()) |line| {
            var section = mem.splitScalar(u8, line, ':');

            const raw_enabled = section.next() orelse {
                continue;
            };

            const device_name = section.next() orelse {
                continue;
            };

            const enabled = switch (raw_enabled[0]) {
                't' => true,
                else => false,
            };

            var it = items.iterator();

            while (it.next()) |entry| {
                const device: Device = entry.key_ptr.*;
                const name: []const u8 = mem.span(device.getNameZ());

                if (mem.eql(u8, name, device_name)) {
                    entry.value_ptr.* = enabled;
                }
            }
        }
    }

    pub fn write(self: State, items: *const std.AutoHashMap(Device, bool)) !void {
        var it = items.iterator();
        const file = try fs.openFileAbsolute(self.path, .{
            .mode = fs.File.OpenMode.write_only,
        });
        defer file.close();

        while (it.next()) |entry| {
            const name: [*:0]const u8 = (entry.key_ptr.*).getNameZ();
            const value: bool = entry.value_ptr.*;

            try fmt.format(file.writer(), "{}:{s}\n", .{ value, name });
        }
    }
};
