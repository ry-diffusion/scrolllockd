const std = @import("std");
const print = std.debug.print;
const devices = @import("devices.zig");
const Device = devices.Device;
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const gpa = std.heap.c_allocator;
const time = std.time;
const State = @import("state.zig").State;

pub fn findDevices() !std.AutoHashMap(Device, bool) {
    const entries = try fs.openIterableDirAbsolute("/dev/input", .{});
    var it = entries.iterate();
    var foundDevices = std.AutoHashMap(Device, bool).init(gpa);

    while (try it.next()) |entry| {
        if (entry.name[0] != 'e')
            continue;

        var buf = [_]u8{undefined} ** 256;
        const path = try fmt.bufPrint(&buf, "/dev/input/{s}", .{entry.name});
        const device = try Device.open(path);

        if (device.hasEventCode(devices.c.EV_KEY, devices.c.KEY_SCROLLLOCK) and device.hasEventCode(devices.c.EV_LED, devices.c.LED_SCROLLL)) {
            try foundDevices.put(device, false);
            continue;
        }

        device.close();
    }

    return foundDevices;
}

pub fn handleDevices(supportedDevices: std.AutoHashMap(Device, bool), state: State) !void {
    while (true) {
        var it = supportedDevices.iterator();

        while (it.next()) |entry| {
            const device: Device = entry.key_ptr.*;
            var enabled = entry.value_ptr;

            try device.setLed(devices.c.LED_SCROLLL, enabled.*);

            const event = device.poll() orelse {
                continue;
            };

            if (event.type == devices.c.EV_KEY and event.value == 1 and event.code == devices.c.KEY_SCROLLLOCK) {
                enabled.* = !enabled.*;
            }
        }

        try state.write(&supportedDevices);
        time.sleep(25 * 1000 * 1000);
    }
}

pub fn main() !void {
    var state = try State.open("/var/lib/scrolllockd/led.state", gpa);

    var supportedDevices = try findDevices();
    defer supportedDevices.deinit();

    try state.read(supportedDevices);

    var it = supportedDevices.keyIterator();

    while (it.next()) |device| {
        log.debug("Found device: {s}", .{device.getNameZ()});
    }

    try handleDevices(supportedDevices, state);

    it = supportedDevices.keyIterator();
    while (it.next()) |device| {
        device.close();
    }
}
