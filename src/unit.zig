const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const particles = @import("particles.zig");

pub const Unit = struct {
    x: f32,
    y: f32,
    hp: f32,
    max_hp: f32,
    unit_type: config.UnitType,
    is_player: bool,
    attack_timer: f32,
    active: bool,
    target_index: ?usize,

    pub fn init(unit_type: config.UnitType, is_player: bool, spawn_x: f32) Unit {
        const stats = config.UNIT_STATS[@intFromEnum(unit_type)];
        return .{
            .x = spawn_x,
            .y = config.GROUND_Y - stats.height,
            .hp = stats.hp,
            .max_hp = stats.hp,
            .unit_type = unit_type,
            .is_player = is_player,
            .attack_timer = 0,
            .active = true,
            .target_index = null,
        };
    }

    pub fn getStats(self: Unit) config.UnitStats {
        return config.UNIT_STATS[@intFromEnum(self.unit_type)];
    }

    pub fn getCenter(self: Unit) struct { x: f32, y: f32 } {
        const stats = self.getStats();
        return .{ .x = self.x + stats.width / 2, .y = self.y + stats.height / 2 };
    }

    pub fn getRight(self: Unit) f32 {
        return self.x + self.getStats().width;
    }

    pub fn getLeft(self: Unit) f32 {
        return self.x;
    }
};

pub const UnitManager = struct {
    units: [config.MAX_UNITS]Unit,
    count: usize,
    damage_numbers: [config.MAX_DAMAGE_NUMBERS]DamageNumber,
    reward_numbers: [config.MAX_DAMAGE_NUMBERS]RewardNumber,

    const DamageNumber = struct {
        x: f32,
        y: f32,
        value: i32,
        timer: f32,
        active: bool,
    };

    const RewardNumber = struct {
        x: f32,
        y: f32,
        xp: u32,
        gold: u32,
        timer: f32,
        active: bool,
    };

    pub fn init() UnitManager {
        var manager = UnitManager{
            .units = undefined,
            .count = 0,
            .damage_numbers = undefined,
            .reward_numbers = undefined,
        };
        for (&manager.damage_numbers) |*dn| dn.active = false;
        for (&manager.reward_numbers) |*rn| rn.active = false;
        return manager;
    }

    pub fn spawn(self: *UnitManager, unit_type: config.UnitType, is_player: bool) bool {
        if (self.count >= config.MAX_UNITS) return false;
        const spawn_x = if (is_player)
            config.PLAYER_BASE_X + config.BASE_WIDTH + 10
        else
            config.ENEMY_BASE_X - 40;
        self.units[self.count] = Unit.init(unit_type, is_player, spawn_x);
        self.count += 1;
        return true;
    }

    pub fn update(self: *UnitManager, dt: f32, player_base_hp: *f32, enemy_base_hp: *f32, player_gold: *u32, enemy_gold: *u32, player_xp: *u32, enemy_xp: *u32) void {
        for (self.units[0..self.count]) |*unit| {
            if (!unit.active) continue;
            unit.attack_timer = @max(0, unit.attack_timer - dt);

            const stats = unit.getStats();
            var blocked_by_enemy = false;
            var blocked_by_ally = false;
            var nearest_enemy: ?*Unit = null;
            var nearest_dist: f32 = std.math.floatMax(f32);

            for (self.units[0..self.count]) |*other| {
                if (!other.active) continue;

                if (other.is_player != unit.is_player) {
                    const dist = @abs(other.x - unit.x);
                    if (dist < nearest_dist) {
                        nearest_dist = dist;
                        nearest_enemy = other;
                    }
                    if (dist < stats.range + 20) blocked_by_enemy = true;
                } else if (other != unit) {
                    const other_stats = other.getStats();
                    if (unit.is_player) {
                        if (other.x > unit.x and other.x - unit.getRight() < 5) {
                            blocked_by_ally = true;
                        }
                    } else {
                        if (other.x < unit.x and unit.getLeft() - other.getRight() < 5) {
                            blocked_by_ally = true;
                        }
                    }
                    _ = other_stats;
                }
            }

            const base_dist = if (unit.is_player)
                config.ENEMY_BASE_X - unit.x
            else
                unit.x - (config.PLAYER_BASE_X + config.BASE_WIDTH);

            if (base_dist < stats.range and nearest_enemy == null) blocked_by_enemy = true;

            if (!blocked_by_enemy and !blocked_by_ally) {
                const dir: f32 = if (unit.is_player) 1 else -1;
                unit.x += stats.speed * dir * dt;
                particles.spawnDust(unit.x + stats.width / 2, config.GROUND_Y);
            }

            if (unit.attack_timer <= 0) {
                if (nearest_enemy != null and nearest_dist < stats.range + 20) {
                    self.attackUnit(unit, nearest_enemy.?, player_gold, enemy_gold, player_xp, enemy_xp);
                } else if (base_dist < stats.range) {
                    self.attackBase(unit, player_base_hp, enemy_base_hp);
                }
            }
        }

        self.updateDamageNumbers(dt);
        self.removeDeadUnits();
    }

    fn attackUnit(self: *UnitManager, attacker: *Unit, target: *Unit, player_gold: *u32, enemy_gold: *u32, player_xp: *u32, enemy_xp: *u32) void {
        const stats = attacker.getStats();
        var damage = stats.damage;

        if (config.getCounter(target.unit_type) == attacker.unit_type) {
            damage *= config.COUNTER_BONUS;
        }

        target.hp -= damage;
        attacker.attack_timer = stats.attack_cooldown;

        const target_stats = target.getStats();
        self.spawnDamageNumber(target.x + target_stats.width / 2, target.y, @intFromFloat(damage));
        particles.spawnHit(target.x + target_stats.width / 2, target.y + target_stats.height / 2, attacker.is_player);

        const attacker_cx = attacker.x + stats.width / 2;
        const attacker_cy = attacker.y + stats.height / 2;
        const target_cx = target.x + target_stats.width / 2;
        const target_cy = target.y + target_stats.height / 2;
        const unit_color = getUnitColor(attacker.unit_type);

        switch (attacker.unit_type) {
            .ranged, .special => particles.spawnUnitAttackLaser(attacker_cx, attacker_cy - 10, target_cx, target_cy, unit_color, true),
            .melee, .tank => particles.spawnUnitAttackLaser(attacker_cx, attacker_cy, target_cx, target_cy, unit_color, false),
        }

        if (target.hp <= 0) {
            target.active = false;
            const reward: u32 = @intFromFloat(@as(f32, @floatFromInt(target_stats.cost)) * config.KILL_GOLD_MULTIPLIER);
            if (attacker.is_player) {
                player_gold.* += reward;
                player_xp.* += target_stats.xp_value;
                self.spawnRewardNumber(target.x + target_stats.width / 2, target.y, target_stats.xp_value, reward);
            } else {
                enemy_gold.* += reward;
                enemy_xp.* += target_stats.xp_value;
            }
            particles.spawnDeath(target.x + target_stats.width / 2, target.y + target_stats.height / 2, !target.is_player);
        }
    }

    fn attackBase(self: *UnitManager, attacker: *Unit, player_base_hp: *f32, enemy_base_hp: *f32) void {
        const stats = attacker.getStats();
        const damage = stats.damage;

        const attacker_cx = attacker.x + stats.width / 2;
        const attacker_cy = attacker.y + stats.height / 2;
        const unit_color = getUnitColor(attacker.unit_type);
        const is_arc = (attacker.unit_type == .ranged or attacker.unit_type == .special);

        if (attacker.is_player) {
            const base_cx = config.ENEMY_BASE_X + config.BASE_WIDTH / 2;
            const base_cy = config.BASE_Y + config.BASE_HEIGHT / 2;
            enemy_base_hp.* -= damage;
            self.spawnDamageNumber(base_cx, config.BASE_Y, @intFromFloat(damage));
            particles.spawnHit(base_cx, base_cy, true);
            particles.spawnUnitAttackLaser(attacker_cx, attacker_cy - (if (is_arc) @as(f32, 10) else 0), base_cx, base_cy, unit_color, is_arc);
        } else {
            const base_cx = config.PLAYER_BASE_X + config.BASE_WIDTH / 2;
            const base_cy = config.BASE_Y + config.BASE_HEIGHT / 2;
            player_base_hp.* -= damage;
            self.spawnDamageNumber(base_cx, config.BASE_Y, @intFromFloat(damage));
            particles.spawnHit(base_cx, base_cy, false);
            particles.spawnUnitAttackLaser(attacker_cx, attacker_cy - (if (is_arc) @as(f32, 10) else 0), base_cx, base_cy, unit_color, is_arc);
        }
        attacker.attack_timer = stats.attack_cooldown;
    }

    pub fn spawnDamageNumber(self: *UnitManager, x: f32, y: f32, value: i32) void {
        for (&self.damage_numbers) |*dn| {
            if (!dn.active) {
                dn.* = .{ .x = x, .y = y, .value = value, .timer = 1.0, .active = true };
                return;
            }
        }
    }

    fn spawnRewardNumber(self: *UnitManager, x: f32, y: f32, xp: u32, gold: u32) void {
        for (&self.reward_numbers) |*rn| {
            if (!rn.active) {
                rn.* = .{ .x = x, .y = y, .xp = xp, .gold = gold, .timer = 1.5, .active = true };
                return;
            }
        }
    }

    pub fn spawnRewardNumberAt(self: *UnitManager, x: f32, y: f32, xp: u32, gold: u32) void {
        self.spawnRewardNumber(x, y, xp, gold);
    }

    fn updateDamageNumbers(self: *UnitManager, dt: f32) void {
        for (&self.damage_numbers) |*dn| {
            if (dn.active) {
                dn.y -= 40 * dt;
                dn.timer -= dt;
                if (dn.timer <= 0) dn.active = false;
            }
        }
        for (&self.reward_numbers) |*rn| {
            if (rn.active) {
                rn.y -= 30 * dt;
                rn.timer -= dt;
                if (rn.timer <= 0) rn.active = false;
            }
        }
    }

    fn removeDeadUnits(self: *UnitManager) void {
        var i: usize = 0;
        while (i < self.count) {
            if (!self.units[i].active) {
                self.units[i] = self.units[self.count - 1];
                self.count -= 1;
            } else {
                i += 1;
            }
        }
    }

    pub fn getComposition(self: *UnitManager, is_player: bool) [4]u32 {
        var comp = [4]u32{ 0, 0, 0, 0 };
        for (self.units[0..self.count]) |unit| {
            if (unit.active and unit.is_player == is_player) {
                comp[@intFromEnum(unit.unit_type)] += 1;
            }
        }
        return comp;
    }

    pub fn draw(self: *UnitManager, camera_x: f32) void {
        for (self.units[0..self.count]) |unit| {
            if (!unit.active) continue;
            const screen_x = unit.x - camera_x;
            if (screen_x < -100 or screen_x > config.SCREEN_WIDTH + 100) continue;

            const stats = unit.getStats();
            const base_color = getUnitColor(unit.unit_type);

            self.drawUnit(screen_x, unit.y, stats.width, stats.height, base_color, unit.unit_type, unit.is_player);
        }
    }

    pub fn drawHealthBars(self: *UnitManager, camera_x: f32) void {
        for (self.units[0..self.count]) |unit| {
            if (!unit.active) continue;
            const screen_x = unit.x - camera_x;
            if (screen_x < -100 or screen_x > config.SCREEN_WIDTH + 100) continue;

            const stats = unit.getStats();
            self.drawHealthBar(screen_x, unit.y - 10, stats.width, unit.hp, unit.max_hp);
        }

        for (self.damage_numbers) |dn| {
            if (dn.active) {
                const screen_x = dn.x - camera_x;
                const alpha: u8 = @intFromFloat(@max(0, @min(255, dn.timer * 255)));
                const text = std.fmt.bufPrintZ(&dmg_buf, "{d}", .{dn.value}) catch "-";
                rl.drawText(text, @intFromFloat(screen_x - 10), @intFromFloat(dn.y), 20, .{ .r = 255, .g = 100, .b = 100, .a = alpha });
            }
        }

        for (self.reward_numbers) |rn| {
            if (rn.active) {
                const screen_x = rn.x - camera_x;
                const alpha: u8 = @intFromFloat(@max(0, @min(255, rn.timer * 170)));

                const xp_text = std.fmt.bufPrintZ(&xp_buf, "+{d} XP", .{rn.xp}) catch "+XP";
                rl.drawText(xp_text, @intFromFloat(screen_x - 25), @intFromFloat(rn.y - 20), 18, .{ .r = 100, .g = 150, .b = 255, .a = alpha });

                const gold_text = std.fmt.bufPrintZ(&gold_buf, "+${d}", .{rn.gold}) catch "+$";
                rl.drawText(gold_text, @intFromFloat(screen_x - 20), @intFromFloat(rn.y), 18, .{ .r = 255, .g = 220, .b = 100, .a = alpha });
            }
        }
    }

    var dmg_buf: [16:0]u8 = undefined;
    var xp_buf: [16:0]u8 = undefined;
    var gold_buf: [16:0]u8 = undefined;

    fn drawUnit(_: *UnitManager, x: f32, y: f32, w: f32, h: f32, color: rl.Color, unit_type: config.UnitType, is_player: bool) void {
        const ix: i32 = @intFromFloat(x);
        const iy: i32 = @intFromFloat(y);
        const iw: i32 = @intFromFloat(w);
        const ih: i32 = @intFromFloat(h);

        const weapon_dir: f32 = if (is_player) 1 else -1;
        const weapon_length: f32 = 15;
        const weapon_y = y + h * 0.4;
        const weapon_start_x = x + w / 2;
        const weapon_end_x = weapon_start_x + weapon_dir * weapon_length;
        const weapon_color: rl.Color = .{ .r = 200, .g = 200, .b = 200, .a = 255 };

        switch (unit_type) {
            .melee => {
                rl.drawRectangle(ix, iy, iw, ih, color);
                rl.drawTriangle(.{ .x = x + w / 2, .y = y - 10 }, .{ .x = x, .y = y + 5 }, .{ .x = x + w, .y = y + 5 }, brighten(color, 30));
                rl.drawLineEx(.{ .x = weapon_start_x, .y = weapon_y }, .{ .x = weapon_end_x + weapon_dir * 10, .y = weapon_y - 5 }, 4, weapon_color);
            },
            .ranged => {
                rl.drawEllipse(ix + @divTrunc(iw, 2), iy + @divTrunc(ih, 2), w / 2, h / 2, color);
                rl.drawLineEx(.{ .x = weapon_start_x, .y = weapon_y }, .{ .x = weapon_end_x + weapon_dir * 5, .y = weapon_y }, 3, weapon_color);
                rl.drawCircle(@intFromFloat(weapon_end_x + weapon_dir * 8), @intFromFloat(weapon_y), 4, weapon_color);
            },
            .special => {
                const cx = x + w / 2;
                const cy = y + h / 2;
                rl.drawPoly(.{ .x = cx, .y = cy }, 6, h / 2, 0, color);
                rl.drawLineEx(.{ .x = weapon_start_x, .y = weapon_y + 5 }, .{ .x = weapon_end_x + weapon_dir * 8, .y = weapon_y + 5 }, 5, .{ .r = 180, .g = 100, .b = 220, .a = 255 });
            },
            .tank => {
                rl.drawRectangle(ix, iy + @divTrunc(ih, 3), iw, @divTrunc(ih * 2, 3), color);
                rl.drawRectangle(ix + @divTrunc(iw, 4), iy, @divTrunc(iw, 2), @divTrunc(ih, 2), brighten(color, -20));
                const barrel_y = y + h * 0.3;
                rl.drawLineEx(.{ .x = weapon_start_x, .y = barrel_y }, .{ .x = weapon_end_x + weapon_dir * 15, .y = barrel_y }, 6, .{ .r = 100, .g = 100, .b = 100, .a = 255 });
            },
        }
    }

    fn drawHealthBar(_: *UnitManager, x: f32, y: f32, w: f32, hp: f32, max_hp: f32) void {
        const bar_height: f32 = 6;
        const hp_ratio = @max(0, hp / max_hp);
        rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(w), @intFromFloat(bar_height), .{ .r = 60, .g = 60, .b = 60, .a = 255 });
        rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(w * hp_ratio), @intFromFloat(bar_height), .{ .r = 100, .g = 200, .b = 100, .a = 255 });
    }
};

fn getUnitColor(unit_type: config.UnitType) rl.Color {
    return switch (unit_type) {
        .melee => rl.Color{ .r = 70, .g = 130, .b = 220, .a = 255 },
        .ranged => rl.Color{ .r = 100, .g = 200, .b = 100, .a = 255 },
        .special => rl.Color{ .r = 200, .g = 100, .b = 200, .a = 255 },
        .tank => rl.Color{ .r = 180, .g = 150, .b = 100, .a = 255 },
    };
}

fn brighten(color: rl.Color, amount: i32) rl.Color {
    return .{
        .r = @intCast(@max(0, @min(255, @as(i32, color.r) + amount))),
        .g = @intCast(@max(0, @min(255, @as(i32, color.g) + amount))),
        .b = @intCast(@max(0, @min(255, @as(i32, color.b) + amount))),
        .a = color.a,
    };
}
