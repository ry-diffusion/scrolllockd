const std = @import("std");
const stateMod = @import("state.zig");
const devices = @import("devices.zig");
const fmt = std.fmt;
const fs = std.fs;
const time = std.time;
const mem = std.mem;

const Device = devices.Device;
const State = stateMod.State;
const Devices = stateMod.Devices;
const DeviceEntry = stateMod.DeviceEntry;

const RESCAN_THRESHOULD: u8 = 32;
const TICK_DURATION: u64 = 25 * 1000 * 1000;
const STATE_FILE_PATH: []const u8 = "/var/db/scrolllockd/kbd.state";

fn mapDevices(deviceList: *Devices) !void {
    var entries = try fs.openDirAbsolute("/dev/input", .{ .iterate = true });
    defer entries.close();

    var buf = [_]u8{undefined} ** 256;
    var entryIterator = entries.iterate();

    while (try entryIterator.next()) |entry| {
        // HACK: because all events starts with letter `e`
        // and I don't know other thing with starts with 'e', so...

        if (entry.name[0] != 'e')
            continue;

        const deviceInputPath = try fmt.bufPrint(&buf, "/dev/input/{s}", .{entry.name});
        const device = try Device.open(deviceInputPath);

        if (device.hasEventCode(devices.c.EV_KEY, devices.c.KEY_SCROLLLOCK) and device.hasEventCode(devices.c.EV_LED, devices.c.LED_SCROLLL)) {
            const removedDevice = deviceList.fetchRemove(mem.span(device.getNameZ()));

            if (removedDevice) |deviceRef| {
                deviceRef.value.device.close();
            }

            try deviceList.put(mem.span(device.getNameZ()), .{
                .device = device,
                .enabled = false,
            });

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
        if (currentTick >= RESCAN_THRESHOULD) {
            try mapDevices(supportedDevices);
            try state.read(supportedDevices.*);
            currentTick = 0;
        }

        var supportedDeviceIterator = supportedDevices.*.valueIterator();

        while (supportedDeviceIterator.next()) |entry| {
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
    const ally = std.heap.c_allocator;
    const log = std.log.scoped(.scrolllockd);
    var state = State.open(STATE_FILE_PATH, ally);

    var supportedDevices = Devices.init(ally);
    defer supportedDevices.deinit();

    state.read(supportedDevices) catch |err| {
        log.err("unable to read state file {s}!", .{STATE_FILE_PATH});
        return err;
    };

    try handleDevices(&supportedDevices, state);
}
