const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");

const Particle = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    life: f32,
    max_life: f32,
    size: f32,
    color: rl.Color,
    particle_type: ParticleType,
    active: bool,
};

const ParticleType = enum { dust, hit, death, projectile };

const LaserBeam = struct {
    from_x: f32,
    from_y: f32,
    to_x: f32,
    to_y: f32,
    life: f32,
    max_life: f32,
    color: rl.Color,
    laser_type: LaserType,
    active: bool,
};

const LaserType = enum { straight, arc, sine, spiral, plasma };

const MAX_LASERS: usize = 32;

var particles: [config.MAX_PARTICLES]Particle = undefined;
var lasers: [MAX_LASERS]LaserBeam = undefined;
var prng: std.Random.Xoshiro256 = undefined;
var dust_timer: f32 = 0;
var game_time: f32 = 0;

pub fn init() void {
    var seed_buf: [8]u8 = undefined;
    std.crypto.random.bytes(&seed_buf);
    prng = std.Random.Xoshiro256.init(@bitCast(seed_buf));
    for (&particles) |*p| p.active = false;
    for (&lasers) |*l| l.active = false;
    game_time = 0;
}

pub fn spawnDust(x: f32, y: f32) void {
    dust_timer += 1;
    if (@mod(dust_timer, 8) != 0) return;

    for (&particles) |*p| {
        if (!p.active) {
            const rand = prng.random();
            p.* = .{
                .x = x + rand.float(f32) * 20 - 10,
                .y = y - 2,
                .vx = rand.float(f32) * 40 - 20,
                .vy = rand.float(f32) * -30 - 10,
                .life = 0.3 + rand.float(f32) * 0.2,
                .max_life = 0.5,
                .size = 3 + rand.float(f32) * 3,
                .color = .{ .r = 160, .g = 140, .b = 120, .a = 150 },
                .particle_type = .dust,
                .active = true,
            };
            return;
        }
    }
}

pub fn spawnHit(x: f32, y: f32, is_player_attack: bool) void {
    const rand = prng.random();
    const count: u32 = 6;
    var spawned: u32 = 0;

    for (&particles) |*p| {
        if (!p.active and spawned < count) {
            const angle = rand.float(f32) * std.math.pi * 2;
            const speed = 80 + rand.float(f32) * 120;
            p.* = .{
                .x = x,
                .y = y,
                .vx = @cos(angle) * speed,
                .vy = @sin(angle) * speed,
                .life = 0.2 + rand.float(f32) * 0.15,
                .max_life = 0.35,
                .size = 4 + rand.float(f32) * 4,
                .color = if (is_player_attack) .{ .r = 100, .g = 180, .b = 255, .a = 255 } else .{ .r = 255, .g = 120, .b = 80, .a = 255 },
                .particle_type = .hit,
                .active = true,
            };
            spawned += 1;
        }
    }
}

pub fn spawnDeath(x: f32, y: f32, is_player_unit: bool) void {
    const rand = prng.random();
    const count: u32 = 15;
    var spawned: u32 = 0;

    for (&particles) |*p| {
        if (!p.active and spawned < count) {
            const angle = rand.float(f32) * std.math.pi * 2;
            const speed = 50 + rand.float(f32) * 150;
            p.* = .{
                .x = x + rand.float(f32) * 20 - 10,
                .y = y + rand.float(f32) * 20 - 10,
                .vx = @cos(angle) * speed,
                .vy = @sin(angle) * speed - 50,
                .life = 0.4 + rand.float(f32) * 0.3,
                .max_life = 0.7,
                .size = 5 + rand.float(f32) * 8,
                .color = if (is_player_unit) .{ .r = 70, .g = 130, .b = 220, .a = 255 } else .{ .r = 200, .g = 80, .b = 80, .a = 255 },
                .particle_type = .death,
                .active = true,
            };
            spawned += 1;
        }
    }
}

pub fn spawnTowerLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, color: rl.Color, tier: u8) void {
    for (&lasers) |*l| {
        if (!l.active) {
            const laser_type: LaserType = switch (tier) {
                0 => .straight,
                1 => .sine,
                2 => .spiral,
                else => .plasma,
            };
            l.* = .{
                .from_x = from_x,
                .from_y = from_y,
                .to_x = to_x,
                .to_y = to_y,
                .life = 0.2,
                .max_life = 0.2,
                .color = color,
                .laser_type = laser_type,
                .active = true,
            };
            return;
        }
    }
}

pub fn spawnUnitAttackLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, color: rl.Color, is_arc: bool) void {
    for (&lasers) |*l| {
        if (!l.active) {
            l.* = .{
                .from_x = from_x,
                .from_y = from_y,
                .to_x = to_x,
                .to_y = to_y,
                .life = 0.2,
                .max_life = 0.2,
                .color = color,
                .laser_type = if (is_arc) .arc else .straight,
                .active = true,
            };
            return;
        }
    }
}

pub fn update(dt: f32) void {
    game_time += dt;

    for (&particles) |*p| {
        if (p.active) {
            p.x += p.vx * dt;
            p.y += p.vy * dt;

            if (p.particle_type != .dust) {
                p.vy += 200 * dt;
            } else {
                p.vy += 100 * dt;
            }

            p.life -= dt;
            if (p.life <= 0) p.active = false;
        }
    }

    for (&lasers) |*l| {
        if (l.active) {
            l.life -= dt;
            if (l.life <= 0) l.active = false;
        }
    }
}

pub fn draw(camera_x: f32) void {
    for (&particles) |*p| {
        if (p.active) {
            const screen_x = p.x - camera_x;
            if (screen_x < -50 or screen_x > config.SCREEN_WIDTH + 50) continue;

            const alpha_ratio = p.life / p.max_life;
            const alpha: u8 = @intFromFloat(@max(0, @min(255, alpha_ratio * @as(f32, @floatFromInt(p.color.a)))));
            const current_size = p.size * (0.5 + alpha_ratio * 0.5);

            const draw_color = rl.Color{ .r = p.color.r, .g = p.color.g, .b = p.color.b, .a = alpha };

            switch (p.particle_type) {
                .dust => rl.drawCircle(@intFromFloat(screen_x), @intFromFloat(p.y), current_size, draw_color),
                .hit => {
                    rl.drawCircle(@intFromFloat(screen_x), @intFromFloat(p.y), current_size, draw_color);
                    rl.drawCircle(@intFromFloat(screen_x), @intFromFloat(p.y), current_size * 0.5, .{ .r = 255, .g = 255, .b = 255, .a = alpha });
                },
                .death => {
                    rl.drawRectangle(@intFromFloat(screen_x - current_size / 2), @intFromFloat(p.y - current_size / 2), @intFromFloat(current_size), @intFromFloat(current_size), draw_color);
                },
                .projectile => {},
            }
        }
    }

    for (&lasers) |*l| {
        if (l.active) {
            const from_screen_x = l.from_x - camera_x;
            const to_screen_x = l.to_x - camera_x;

            const life_ratio = l.life / l.max_life;
            const thickness: f32 = 5.0 * life_ratio;
            const alpha: u8 = @intFromFloat(255 * life_ratio);
            const draw_color = rl.Color{ .r = l.color.r, .g = l.color.g, .b = l.color.b, .a = alpha };

            switch (l.laser_type) {
                .straight => drawStraightLaser(from_screen_x, l.from_y, to_screen_x, l.to_y, thickness, draw_color),
                .arc => drawArcLaser(from_screen_x, l.from_y, to_screen_x, l.to_y, thickness, draw_color),
                .sine => drawSineLaser(from_screen_x, l.from_y, to_screen_x, l.to_y, thickness, draw_color, life_ratio),
                .spiral => drawSpiralLaser(from_screen_x, l.from_y, to_screen_x, l.to_y, thickness, draw_color, life_ratio),
                .plasma => drawPlasmaLaser(from_screen_x, l.from_y, to_screen_x, l.to_y, thickness, draw_color, life_ratio),
            }
        }
    }
}

fn drawStraightLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, thickness: f32, color: rl.Color) void {
    rl.drawLineEx(.{ .x = from_x, .y = from_y }, .{ .x = to_x, .y = to_y }, thickness, color);
    if (thickness > 2) {
        rl.drawLineEx(.{ .x = from_x, .y = from_y }, .{ .x = to_x, .y = to_y }, thickness * 0.4, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
    }
}

fn drawArcLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, thickness: f32, color: rl.Color) void {
    const segments: usize = 12;
    const dx = to_x - from_x;
    const dist = @abs(dx);
    const arc_height = @min(dist * 0.3, 80);

    var prev_x = from_x;
    var prev_y = from_y;

    for (1..segments + 1) |i| {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
        const curr_x = from_x + dx * t;
        const base_y = from_y + (to_y - from_y) * t;
        const arc_offset = @sin(t * std.math.pi) * arc_height;
        const curr_y = base_y - arc_offset;

        rl.drawLineEx(.{ .x = prev_x, .y = prev_y }, .{ .x = curr_x, .y = curr_y }, thickness, color);

        prev_x = curr_x;
        prev_y = curr_y;
    }

    if (thickness > 2) {
        prev_x = from_x;
        prev_y = from_y;
        const inner_color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = color.a };

        for (1..segments + 1) |i| {
            const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
            const curr_x = from_x + dx * t;
            const base_y = from_y + (to_y - from_y) * t;
            const arc_offset = @sin(t * std.math.pi) * arc_height;
            const curr_y = base_y - arc_offset;

            rl.drawLineEx(.{ .x = prev_x, .y = prev_y }, .{ .x = curr_x, .y = curr_y }, thickness * 0.4, inner_color);

            prev_x = curr_x;
            prev_y = curr_y;
        }
    }
}

fn drawSineLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, thickness: f32, color: rl.Color, life_ratio: f32) void {
    const segments: usize = 20;
    const dx = to_x - from_x;
    const dy = to_y - from_y;
    const dist = @sqrt(dx * dx + dy * dy);
    const nx = -dy / dist;
    const ny = dx / dist;
    const wave_amp: f32 = 15 * life_ratio;
    const wave_freq: f32 = 6;

    var prev_x = from_x;
    var prev_y = from_y;

    for (1..segments + 1) |i| {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
        const base_x = from_x + dx * t;
        const base_y = from_y + dy * t;
        const wave = @sin(t * std.math.pi * wave_freq + game_time * 20) * wave_amp;
        const curr_x = base_x + nx * wave;
        const curr_y = base_y + ny * wave;

        rl.drawLineEx(.{ .x = prev_x, .y = prev_y }, .{ .x = curr_x, .y = curr_y }, thickness, color);

        prev_x = curr_x;
        prev_y = curr_y;
    }

    if (thickness > 2) {
        prev_x = from_x;
        prev_y = from_y;
        for (1..segments + 1) |i| {
            const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
            const base_x = from_x + dx * t;
            const base_y = from_y + dy * t;
            const wave = @sin(t * std.math.pi * wave_freq + game_time * 20) * wave_amp;
            const curr_x = base_x + nx * wave;
            const curr_y = base_y + ny * wave;
            rl.drawLineEx(.{ .x = prev_x, .y = prev_y }, .{ .x = curr_x, .y = curr_y }, thickness * 0.4, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
            prev_x = curr_x;
            prev_y = curr_y;
        }
    }
}

fn drawSpiralLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, thickness: f32, color: rl.Color, life_ratio: f32) void {
    const segments: usize = 24;
    const dx = to_x - from_x;
    const dy = to_y - from_y;
    const dist = @sqrt(dx * dx + dy * dy);
    const nx = -dy / dist;
    const ny = dx / dist;
    const spiral_amp: f32 = 20 * life_ratio;
    const rotations: f32 = 4;

    var prev_x = from_x;
    var prev_y = from_y;

    for (1..segments + 1) |i| {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
        const base_x = from_x + dx * t;
        const base_y = from_y + dy * t;
        const angle = t * std.math.pi * 2 * rotations + game_time * 15;
        const radius = spiral_amp * t * (1 - t) * 4;
        const offset_x = @cos(angle) * radius * nx - @sin(angle) * radius * (dx / dist);
        const offset_y = @cos(angle) * radius * ny - @sin(angle) * radius * (dy / dist);
        const curr_x = base_x + offset_x;
        const curr_y = base_y + offset_y;

        rl.drawLineEx(.{ .x = prev_x, .y = prev_y }, .{ .x = curr_x, .y = curr_y }, thickness, color);

        prev_x = curr_x;
        prev_y = curr_y;
    }

    drawStraightLaser(from_x, from_y, to_x, to_y, thickness * 0.5, .{ .r = 255, .g = 255, .b = 255, .a = @intFromFloat(@as(f32, @floatFromInt(color.a)) * 0.5) });
}

fn drawPlasmaLaser(from_x: f32, from_y: f32, to_x: f32, to_y: f32, thickness: f32, color: rl.Color, life_ratio: f32) void {
    const dx = to_x - from_x;
    const dy = to_y - from_y;
    const dist = @sqrt(dx * dx + dy * dy);
    const nx = -dy / dist;
    const ny = dx / dist;

    const segments: usize = 16;
    const jitter_amp: f32 = 25 * life_ratio;

    var points_x: [17]f32 = undefined;
    var points_y: [17]f32 = undefined;

    points_x[0] = from_x;
    points_y[0] = from_y;

    const time_seed: u32 = @intFromFloat(game_time * 60);
    for (1..segments) |i| {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segments));
        const base_x = from_x + dx * t;
        const base_y = from_y + dy * t;

        const hash = (time_seed +% @as(u32, @intCast(i)) *% 7919) % 1000;
        const rand_offset = (@as(f32, @floatFromInt(hash)) / 500.0 - 1.0) * jitter_amp;

        points_x[i] = base_x + nx * rand_offset;
        points_y[i] = base_y + ny * rand_offset;
    }
    points_x[segments] = to_x;
    points_y[segments] = to_y;

    for (0..segments) |i| {
        rl.drawLineEx(.{ .x = points_x[i], .y = points_y[i] }, .{ .x = points_x[i + 1], .y = points_y[i + 1] }, thickness * 1.5, color);
    }

    for (0..segments) |i| {
        rl.drawLineEx(.{ .x = points_x[i], .y = points_y[i] }, .{ .x = points_x[i + 1], .y = points_y[i + 1] }, thickness * 0.6, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
    }

    const branch_indices = [_]usize{ 4, 8, 12 };
    for (branch_indices) |bi| {
        if (bi < segments) {
            const branch_hash = (time_seed +% @as(u32, @intCast(bi)) *% 3571) % 1000;
            const branch_angle = (@as(f32, @floatFromInt(branch_hash)) / 500.0 - 1.0) * std.math.pi * 0.4;
            const branch_len = 40 * life_ratio;
            const branch_dir_x = dx / dist;
            const branch_dir_y = dy / dist;
            const rot_x = branch_dir_x * @cos(branch_angle) - branch_dir_y * @sin(branch_angle);
            const rot_y = branch_dir_x * @sin(branch_angle) + branch_dir_y * @cos(branch_angle);

            const bx = points_x[bi];
            const by = points_y[bi];
            const bend_hash = (time_seed +% @as(u32, @intCast(bi)) *% 1237) % 1000;
            const bend = (@as(f32, @floatFromInt(bend_hash)) / 500.0 - 1.0) * 15;

            const mid_bx = bx + rot_x * branch_len * 0.5 + nx * bend;
            const mid_by = by + rot_y * branch_len * 0.5 + ny * bend;
            const end_bx = bx + rot_x * branch_len;
            const end_by = by + rot_y * branch_len;

            rl.drawLineEx(.{ .x = bx, .y = by }, .{ .x = mid_bx, .y = mid_by }, thickness * 0.8, color);
            rl.drawLineEx(.{ .x = mid_bx, .y = mid_by }, .{ .x = end_bx, .y = end_by }, thickness * 0.5, color);

            rl.drawCircle(@intFromFloat(end_bx), @intFromFloat(end_by), 3 * life_ratio, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
        }
    }

    rl.drawCircle(@intFromFloat(from_x), @intFromFloat(from_y), 6 * life_ratio, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
    rl.drawCircle(@intFromFloat(to_x), @intFromFloat(to_y), 8 * life_ratio, color);
    rl.drawCircle(@intFromFloat(to_x), @intFromFloat(to_y), 4 * life_ratio, .{ .r = 255, .g = 255, .b = 255, .a = color.a });
}
