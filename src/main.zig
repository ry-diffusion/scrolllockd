const std = @import("std");
const stateMod = @import("state.zig");
const devices = @import("devices.zig");
const gpa = std.heap.c_allocator;
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const time = std.time;
const mem = std.mem;

const Device = devices.Device;
const State = stateMod.State;
const Devices = stateMod.Devices;
const DeviceEntry = stateMod.DeviceEntry;

const TICK_RESCAN_SERVICES: u8 = 32;
const TICK_DURATION: u64 = 25 * 1000 * 1000;

fn mapDevices(refDevices: *Devices) !void {
    var entries = try fs.openIterableDirAbsolute("/dev/input", .{});
    defer entries.close();

    var buf = [_]u8{undefined} ** 256;
    var it = entries.iterate();

    while (try it.next()) |entry| {
        if (entry.name[0] != 'e')
            continue;

        const path = try fmt.bufPrint(&buf, "/dev/input/{s}", .{entry.name});
        const device = try Device.open(path);

        if (device.hasEventCode(devices.c.EV_KEY, devices.c.KEY_SCROLLLOCK) and device.hasEventCode(devices.c.EV_LED, devices.c.LED_SCROLLL)) {
            const item = refDevices.fetchRemove(mem.span(device.getNameZ()));

            if (item != null) {
                item.?.value.device.close();
            }

            try refDevices.put(mem.span(device.getNameZ()), .{ .device = device, .enabled = false });

            continue;
        }

        device.close();
    }
}

pub fn closeDevices(supportedDevices: *Devices) !void {
    var it = supportedDevices.keyIterator();
    while (it.next()) |device| {
        device.close();
    }
}

pub fn handleDevices(supportedDevices: *Devices, state: State) !void {
    var currentTick: u8 = 0;

    while (true) {
        if (currentTick >= TICK_RESCAN_SERVICES) {
            try mapDevices(supportedDevices);
            try state.read(supportedDevices.*);
            currentTick = 0;
        }

        var it = supportedDevices.*.valueIterator();

        while (it.next()) |entry| {
            const device: Device = entry.*.device;
            const wasEnabled: bool = entry.*.enabled;

            device.setLed(devices.c.LED_SCROLLL, wasEnabled) catch continue;

            const event = device.poll() orelse
                continue;

            if (event.type == devices.c.EV_KEY and event.value == 1 and event.code == devices.c.KEY_SCROLLLOCK) {
                entry.*.enabled = !wasEnabled;
            }
        }

        try state.write(supportedDevices.*);
        time.sleep(TICK_DURATION);
        currentTick += 1;
    }
}

pub fn main() !void {
    var state = try State.open("/var/lib/scrolllockd/led.state", gpa);
    var supportedDevices = Devices.init(gpa);
    defer supportedDevices.deinit();

    try state.read(supportedDevices);

    try handleDevices(&supportedDevices, state);
}
