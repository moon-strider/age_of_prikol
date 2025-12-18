const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const particles = @import("particles.zig");
const unit_mod = @import("unit.zig");

pub const Tower = struct {
    tier: ?config.TowerTier,
    is_player: bool,
    fire_timer: f32,

    pub fn init(is_player: bool) Tower {
        return .{ .tier = null, .is_player = is_player, .fire_timer = 0 };
    }

    pub fn getX(self: Tower) f32 {
        return if (self.is_player)
            config.PLAYER_BASE_X + config.BASE_WIDTH - config.TOWER_WIDTH - 10
        else
            config.ENEMY_BASE_X + 10;
    }

    pub fn getStats(self: Tower) ?config.TowerStats {
        if (self.tier) |t| return config.TOWER_STATS[@intFromEnum(t)];
        return null;
    }

    pub fn build(self: *Tower, tier: config.TowerTier) void {
        self.tier = tier;
        self.fire_timer = 0;
    }

    pub fn update(self: *Tower, dt: f32, units: *unit_mod.UnitManager, player_gold: *u32, enemy_gold: *u32, player_xp: *u32, enemy_xp: *u32) void {
        if (self.tier == null) return;
        const stats = self.getStats().?;

        self.fire_timer = @max(0, self.fire_timer - dt);
        if (self.fire_timer > 0) return;

        const tower_x = self.getX() + config.TOWER_WIDTH / 2;
        const tower_y = config.TOWER_SLOT_Y + config.TOWER_HEIGHT / 2;

        var nearest: ?*unit_mod.Unit = null;
        var nearest_dist: f32 = std.math.floatMax(f32);

        for (units.units[0..units.count]) |*u| {
            if (!u.active or u.is_player == self.is_player) continue;
            const ux = u.x + u.getStats().width / 2;
            const dist = @abs(ux - tower_x);
            if (dist < stats.range and dist < nearest_dist) {
                nearest_dist = dist;
                nearest = u;
            }
        }

        if (nearest) |target| {
            const target_stats = target.getStats();
            const tx = target.x + target_stats.width / 2;
            const ty = target.y + target_stats.height / 2;

            target.hp -= stats.damage;
            self.fire_timer = stats.fire_rate;

            particles.spawnTowerLaser(tower_x, tower_y, tx, ty, self.getColor(), @intFromEnum(self.tier.?));
            particles.spawnHit(tx, ty, self.is_player);
            units.spawnDamageNumber(tx, ty - 10, @intFromFloat(stats.damage));

            if (target.hp <= 0) {
                target.active = false;
                const reward: u32 = @intFromFloat(@as(f32, @floatFromInt(target_stats.cost)) * config.KILL_GOLD_MULTIPLIER);
                if (self.is_player) {
                    player_gold.* += reward;
                    player_xp.* += target_stats.xp_value;
                    units.spawnRewardNumberAt(tx, ty, target_stats.xp_value, reward);
                } else {
                    enemy_gold.* += reward;
                    enemy_xp.* += target_stats.xp_value;
                }
                particles.spawnDeath(tx, ty, !target.is_player);
            }
        }
    }

    pub fn getColor(self: Tower) rl.Color {
        if (self.tier == null) return .{ .r = 100, .g = 100, .b = 100, .a = 255 };
        const tier_idx = @intFromEnum(self.tier.?);
        const intensity: u8 = @intCast(100 + tier_idx * 40);
        return if (self.is_player) .{ .r = 60, .g = intensity, .b = 160, .a = 255 } else .{ .r = intensity, .g = 60, .b = 60, .a = 255 };
    }

    pub fn draw(self: Tower, camera_x: f32, hovered: bool) void {
        if (self.tier == null) return;

        const screen_x = self.getX() - camera_x;
        if (screen_x < -config.TOWER_WIDTH or screen_x > config.SCREEN_WIDTH + config.TOWER_WIDTH) return;

        const ix: i32 = @intFromFloat(screen_x);
        const iy: i32 = @intFromFloat(config.TOWER_SLOT_Y);
        const iw: i32 = @intFromFloat(config.TOWER_WIDTH);
        const ih: i32 = @intFromFloat(config.TOWER_HEIGHT);

        const base_color = self.getColor();

        rl.drawRectangle(ix, iy + 20, iw, ih - 20, base_color);
        rl.drawRectangle(ix + 10, iy, 20, 25, .{ .r = 80, .g = 80, .b = 80, .a = 255 });

        if (hovered) {
            const stats = self.getStats().?;
            const range_alpha: u8 = 25;
            rl.drawCircle(@intFromFloat(screen_x + config.TOWER_WIDTH / 2), @intFromFloat(config.TOWER_SLOT_Y + config.TOWER_HEIGHT / 2), stats.range, .{ .r = 255, .g = 255, .b = 100, .a = range_alpha });
            rl.drawCircleLines(@intFromFloat(screen_x + config.TOWER_WIDTH / 2), @intFromFloat(config.TOWER_SLOT_Y + config.TOWER_HEIGHT / 2), stats.range, .{ .r = 255, .g = 255, .b = 100, .a = 80 });
        }
    }
};
