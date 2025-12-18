const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");

const Cloud = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    speed: f32,
    alpha: u8,
};

var clouds: [config.CLOUD_COUNT]Cloud = undefined;
var prng: std.Random.Xoshiro256 = undefined;

pub fn init() void {
    var seed_buf: [8]u8 = undefined;
    std.crypto.random.bytes(&seed_buf);
    prng = std.Random.Xoshiro256.init(@bitCast(seed_buf));

    const rand = prng.random();
    for (&clouds) |*c| {
        c.* = .{
            .x = rand.float(f32) * config.WORLD_WIDTH,
            .y = 50 + rand.float(f32) * 200,
            .width = 80 + rand.float(f32) * 120,
            .height = 30 + rand.float(f32) * 40,
            .speed = config.CLOUD_MIN_SPEED + rand.float(f32) * (config.CLOUD_MAX_SPEED - config.CLOUD_MIN_SPEED),
            .alpha = @intFromFloat(60 + rand.float(f32) * 60),
        };
    }
}

pub fn update(dt: f32) void {
    const rand = prng.random();
    for (&clouds) |*c| {
        c.x += c.speed * dt;
        if (c.x > config.WORLD_WIDTH + c.width) {
            c.x = -c.width;
            c.y = 50 + rand.float(f32) * 200;
        }
    }
}

pub fn draw(camera_x: f32) void {
    const sky_top = rl.Color{ .r = 40, .g = 60, .b = 100, .a = 255 };
    const sky_bottom = rl.Color{ .r = 80, .g = 100, .b = 140, .a = 255 };
    rl.drawRectangleGradientV(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT, sky_top, sky_bottom);

    const parallax_factors = [_]f32{ 0.1, 0.3, 0.6 };
    const layer_colors = [_]rl.Color{
        .{ .r = 50, .g = 60, .b = 80, .a = 255 },
        .{ .r = 60, .g = 70, .b = 90, .a = 255 },
        .{ .r = 70, .g = 80, .b = 100, .a = 255 },
    };
    const layer_heights = [_]f32{ 300, 200, 120 };

    for (0..config.PARALLAX_LAYER_COUNT) |i| {
        const offset = camera_x * parallax_factors[i];
        const y = config.SCREEN_HEIGHT - layer_heights[i];
        drawMountainLayer(@intFromFloat(-offset), @intFromFloat(y), layer_colors[i], @intFromFloat(layer_heights[i]), i);
    }

    for (clouds) |c| {
        const parallax = 0.2;
        const screen_x = c.x - camera_x * parallax;
        if (screen_x > -c.width and screen_x < config.SCREEN_WIDTH + c.width) {
            drawCloud(screen_x, c.y, c.width, c.height, c.alpha);
        }
    }

    const ground_offset = camera_x;
    drawGround(@intFromFloat(-ground_offset));
}

fn drawMountainLayer(offset: i32, y: i32, color: rl.Color, height: i32, layer: usize) void {
    const segment_width: i32 = 200;
    const num_segments: i32 = @as(i32, @intFromFloat(config.WORLD_WIDTH / @as(f32, @floatFromInt(segment_width)))) + 4;

    var i: i32 = -2;
    while (i < num_segments) : (i += 1) {
        const base_x = @mod(offset + i * segment_width, @as(i32, @intFromFloat(config.WORLD_WIDTH)) + segment_width * 4) - segment_width * 2;
        const peak_offset: i32 = @intCast((((@as(usize, @intCast(i + 100)) + layer * 37) * 7) % 60));
        const peak_height = height + @divTrunc(peak_offset, 2);

        rl.drawTriangle(.{ .x = @floatFromInt(base_x), .y = @floatFromInt(y + height) }, .{ .x = @floatFromInt(base_x + segment_width / 2), .y = @floatFromInt(y + height - peak_height) }, .{ .x = @floatFromInt(base_x + segment_width), .y = @floatFromInt(y + height) }, color);
    }
}

fn drawCloud(x: f32, y: f32, w: f32, h: f32, alpha: u8) void {
    const color = rl.Color{ .r = 220, .g = 230, .b = 245, .a = alpha };
    const cx = x + w / 2;

    rl.drawEllipse(@intFromFloat(cx), @intFromFloat(y + h / 2), w / 2, h / 2, color);
    rl.drawEllipse(@intFromFloat(cx - w / 4), @intFromFloat(y + h / 2 + 5), w / 3, h / 3, color);
    rl.drawEllipse(@intFromFloat(cx + w / 4), @intFromFloat(y + h / 2 + 3), w / 3, h / 2.5, color);
}

fn drawGround(offset: i32) void {
    const ground_y: i32 = @intFromFloat(config.GROUND_Y);
    const ground_height: i32 = config.SCREEN_HEIGHT - ground_y;

    rl.drawRectangle(0, ground_y, config.SCREEN_WIDTH, ground_height, .{ .r = 80, .g = 70, .b = 60, .a = 255 });
    rl.drawRectangle(0, ground_y, config.SCREEN_WIDTH, 5, .{ .r = 100, .g = 90, .b = 70, .a = 255 });

    var x: i32 = @mod(offset, 40);
    while (x < config.SCREEN_WIDTH) : (x += 40) {
        rl.drawRectangle(x, ground_y + 8, 20, 3, .{ .r = 70, .g = 60, .b = 50, .a = 255 });
    }
}
