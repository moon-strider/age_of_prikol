const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");

const CloudPuff = struct {
    offset_x: f32,
    offset_y: f32,
    radius: f32,
    brightness: f32,
};

const Cloud = struct {
    x: f32,
    y: f32,
    speed: f32,
    puffs: [8]CloudPuff,
    puff_count: usize,
    base_width: f32,
};

var clouds: [config.CLOUD_COUNT]Cloud = undefined;
var prng: std.Random.Xoshiro256 = undefined;

var light_source_x: f32 = config.WORLD_WIDTH * 0.5;
var light_target_x: f32 = config.WORLD_WIDTH * 0.5;

pub fn init() void {
    var seed_buf: [8]u8 = undefined;
    std.crypto.random.bytes(&seed_buf);
    prng = std.Random.Xoshiro256.init(@bitCast(seed_buf));

    const rand = prng.random();

    const go_right = rand.boolean();
    const offset = config.WORLD_WIDTH * 0.10;

    if (go_right) {
        light_source_x = config.WORLD_WIDTH * 0.5 + offset;
        light_target_x = config.WORLD_WIDTH * 0.5 - offset;
    } else {
        light_source_x = config.WORLD_WIDTH * 0.5 - offset;
        light_target_x = config.WORLD_WIDTH * 0.5 + offset;
    }

    for (&clouds) |*c| {
        const base_y = 70 + rand.float(f32) * 120;
        const puff_count: usize = 4 + @as(usize, @intFromFloat(rand.float(f32) * 4));

        c.* = .{
            .x = rand.float(f32) * config.WORLD_WIDTH,
            .y = base_y,
            .speed = config.CLOUD_MIN_SPEED + rand.float(f32) * (config.CLOUD_MAX_SPEED - config.CLOUD_MIN_SPEED),
            .puffs = undefined,
            .puff_count = puff_count,
            .base_width = 0,
        };

        var total_width: f32 = 0;
        for (0..puff_count) |i| {
            const r = 40 + rand.float(f32) * 55;
            c.puffs[i] = .{
                .offset_x = total_width + r * 0.5,
                .offset_y = (rand.float(f32) - 0.5) * 18,
                .radius = r,
                .brightness = 0.5 + rand.float(f32) * 0.5,
            };
            total_width += r * 1.0;
        }
        c.base_width = total_width;
    }
}

pub fn update(dt: f32) void {
    const rand = prng.random();
    for (&clouds) |*c| {
        c.x += c.speed * dt;
        if (c.x > config.WORLD_WIDTH + c.base_width) {
            c.x = -c.base_width;
            c.y = 70 + rand.float(f32) * 120;
        }
    }
}

pub fn setLightPosition(_: f32, _: f32) void {}

pub fn getLightSourceScreenX(camera_x: f32) f32 {
    return light_source_x - camera_x;
}

pub fn getLightTargetScreenX(camera_x: f32) f32 {
    return light_target_x - camera_x;
}

pub fn draw(camera_x: f32) void {
    drawSky();

    const parallax_factors = [_]f32{ 0.1, 0.3, 0.6 };
    const layer_colors = [_]rl.Color{
        .{ .r = 35, .g = 45, .b = 70, .a = 255 },
        .{ .r = 45, .g = 55, .b = 80, .a = 255 },
        .{ .r = 55, .g = 65, .b = 90, .a = 255 },
    };
    const layer_heights = [_]f32{ 320, 220, 140 };

    for (0..config.PARALLAX_LAYER_COUNT) |i| {
        const offset = camera_x * parallax_factors[i];
        const y = config.SCREEN_HEIGHT - layer_heights[i];
        drawMountainLayer(@intFromFloat(-offset), @intFromFloat(y), layer_colors[i], @intFromFloat(layer_heights[i]));
    }

    for (&clouds) |*c| {
        const parallax: f32 = 0.2;
        const screen_x = c.x - camera_x * parallax;
        if (screen_x > -c.base_width and screen_x < config.SCREEN_WIDTH + c.base_width) {
            drawCloud(c, screen_x, camera_x);
        }
    }

    drawGround(@intFromFloat(-camera_x));
}

fn drawSky() void {
    const sky_top = rl.Color{ .r = 12, .g = 18, .b = 42, .a = 255 };
    const sky_bottom = rl.Color{ .r = 55, .g = 75, .b = 115, .a = 255 };
    rl.drawRectangleGradientV(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT, sky_top, sky_bottom);
}

fn drawCloud(cloud: *const Cloud, screen_x: f32, camera_x: f32) void {
    const light_screen_x = getLightSourceScreenX(camera_x);

    for (cloud.puffs[0..cloud.puff_count]) |puff| {
        const px = screen_x + puff.offset_x;
        const py = cloud.y + puff.offset_y;

        const dist_to_light = @abs(light_screen_x - px);
        const max_dist: f32 = 800;
        const light_factor = @max(0, 1.0 - dist_to_light / max_dist);

        const shadow_dir: f32 = if (light_screen_x > px) 1 else -1;
        drawCloudPuff(px + shadow_dir * 5, py + 4, puff.radius * 0.9, .{ .r = 40, .g = 45, .b = 65, .a = 100 });

        const base_b = 0.5 + puff.brightness * 0.3 + light_factor * 0.2;
        const r: u8 = @intFromFloat(@min(255, 135 + base_b * 105));
        const g: u8 = @intFromFloat(@min(255, 140 + base_b * 100));
        const b: u8 = @intFromFloat(@min(255, 160 + base_b * 80));
        drawCloudPuff(px, py, puff.radius, .{ .r = r, .g = g, .b = b, .a = 220 });

        if (light_factor > 0.3) {
            const rim_x = px - shadow_dir * puff.radius * 0.35;
            const rim_y = py - puff.radius * 0.2;
            const rim_alpha: u8 = @intFromFloat((light_factor - 0.3) * 200);
            drawCloudPuff(rim_x, rim_y, puff.radius * 0.45, .{ .r = 255, .g = 252, .b = 235, .a = rim_alpha });
        }

        if (light_factor > 0.2) {
            const scatter_alpha: u8 = @intFromFloat(light_factor * 30);
            rl.drawCircle(@intFromFloat(px), @intFromFloat(py), puff.radius * 1.5, .{ .r = 255, .g = 245, .b = 210, .a = scatter_alpha });
        }
    }
}

fn drawCloudPuff(cx: f32, cy: f32, radius: f32, color: rl.Color) void {
    rl.drawCircle(@intFromFloat(cx), @intFromFloat(cy), radius, color);
    rl.drawCircle(@intFromFloat(cx - radius * 0.32), @intFromFloat(cy - radius * 0.1), radius * 0.7, color);
    rl.drawCircle(@intFromFloat(cx + radius * 0.32), @intFromFloat(cy + radius * 0.07), radius * 0.65, color);
}

fn drawMountainLayer(offset: i32, y: i32, color: rl.Color, height: i32) void {
    const segment_width: i32 = 180;
    const num_segments: i32 = @as(i32, @intFromFloat(config.WORLD_WIDTH / @as(f32, @floatFromInt(segment_width)))) + 4;

    var i: i32 = -2;
    while (i < num_segments) : (i += 1) {
        const base_x = @mod(offset + i * segment_width, @as(i32, @intFromFloat(config.WORLD_WIDTH)) + segment_width * 4) - segment_width * 2;
        const peak_offset: i32 = @intCast((((@as(usize, @intCast(i + 100)) * 37) * 7) % 70));
        const peak_height = height + @divTrunc(peak_offset, 2);

        rl.drawTriangle(
            .{ .x = @floatFromInt(base_x), .y = @floatFromInt(y + height) },
            .{ .x = @floatFromInt(base_x + @divTrunc(segment_width, 2)), .y = @floatFromInt(y + height - peak_height) },
            .{ .x = @floatFromInt(base_x + segment_width), .y = @floatFromInt(y + height) },
            color,
        );
    }
}

fn drawGround(offset: i32) void {
    const ground_y: i32 = @intFromFloat(config.GROUND_Y);
    const ground_height: i32 = config.SCREEN_HEIGHT - ground_y;

    rl.drawRectangle(0, ground_y, config.SCREEN_WIDTH, ground_height, .{ .r = 70, .g = 60, .b = 50, .a = 255 });
    rl.drawRectangle(0, ground_y, config.SCREEN_WIDTH, 5, .{ .r = 95, .g = 85, .b = 70, .a = 255 });

    var gx: i32 = @mod(offset, 60);
    while (gx < config.SCREEN_WIDTH) : (gx += 60) {
        rl.drawRectangle(gx, ground_y + 12, 30, 3, .{ .r = 55, .g = 45, .b = 38, .a = 180 });
    }
}
