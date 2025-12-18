const std = @import("std");
const config = @import("config.zig");
const ui_mod = @import("ui.zig");

pub const AI = struct {
    gold: u32,
    xp: u32,
    level: u32,
    spawn_timer: f32,
    income_timer: f32,
    build_queue: ui_mod.BuildQueue,
    prng: std.Random.Xoshiro256,

    pub fn init() AI {
        var seed_buf: [8]u8 = undefined;
        std.crypto.random.bytes(&seed_buf);
        return .{
            .gold = config.STARTING_GOLD,
            .xp = 0,
            .level = 0,
            .spawn_timer = 2.0,
            .income_timer = 0,
            .build_queue = ui_mod.BuildQueue.init(),
            .prng = std.Random.Xoshiro256.init(@bitCast(seed_buf)),
        };
    }

    pub fn update(self: *AI, dt: f32) void {
        self.updateLevel();

        self.income_timer += dt;
        if (self.income_timer >= 1.0) {
            self.income_timer -= 1.0;
            self.gold += @intFromFloat(config.PASSIVE_INCOME);
        }

        self.spawn_timer -= dt;
        if (self.spawn_timer <= 0) {
            self.tryQueueUnit();
            const rand = self.prng.random();
            self.spawn_timer = config.AI_MIN_SPAWN_DELAY + rand.float(f32) * (config.AI_MAX_SPAWN_DELAY - config.AI_MIN_SPAWN_DELAY);
        }
    }

    fn updateLevel(self: *AI) void {
        while (self.level < config.MAX_LEVEL) {
            const xp_needed = config.XP_PER_LEVEL[self.level];
            if (self.xp >= xp_needed) {
                self.xp -= xp_needed;
                self.level += 1;
            } else break;
        }
    }

    fn tryQueueUnit(self: *AI) void {
        if (self.build_queue.count >= config.MAX_BUILD_QUEUE) return;

        const unit_type = self.chooseUnitType();
        const cost = config.UNIT_STATS[@intFromEnum(unit_type)].cost;

        if (self.gold >= cost) {
            if (self.build_queue.add(unit_type)) {
                self.gold -= cost;
            }
        } else {
            for (0..4) |i| {
                const fallback_cost = config.UNIT_STATS[i].cost;
                if (self.gold >= fallback_cost) {
                    if (self.build_queue.add(@enumFromInt(i))) {
                        self.gold -= fallback_cost;
                    }
                    return;
                }
            }
        }
    }

    fn chooseUnitType(self: *AI) config.UnitType {
        const rand = self.prng.random();
        return @enumFromInt(rand.intRangeAtMost(u8, 0, 3));
    }

    pub fn addGold(self: *AI, amount: u32) void {
        self.gold += amount;
    }

    pub fn addXp(self: *AI, amount: u32) void {
        self.xp += amount;
    }
};
