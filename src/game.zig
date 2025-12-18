const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const unit_mod = @import("unit.zig");
const base_mod = @import("base.zig");
const tower_mod = @import("tower.zig");
const ai_mod = @import("ai.zig");
const camera_mod = @import("camera.zig");
const ui_mod = @import("ui.zig");
const background = @import("background.zig");
const particles = @import("particles.zig");

pub const GameState = enum { playing, victory, defeat };

pub const Game = struct {
    state: GameState,
    player_gold: u32,
    player_xp: u32,
    player_level: u32,
    income_timer: f32,
    player_base: base_mod.Base,
    enemy_base: base_mod.Base,
    player_tower: tower_mod.Tower,
    enemy_tower: tower_mod.Tower,
    units: unit_mod.UnitManager,
    ai: ai_mod.AI,
    camera: camera_mod.Camera,
    ui: ui_mod.UI,
    player_build_queue: ui_mod.BuildQueue,

    pub fn init() Game {
        particles.init();
        background.init();

        return .{
            .state = .playing,
            .player_gold = config.STARTING_GOLD,
            .player_xp = 0,
            .player_level = 0,
            .income_timer = 0,
            .player_base = base_mod.Base.init(true),
            .enemy_base = base_mod.Base.init(false),
            .player_tower = tower_mod.Tower.init(true),
            .enemy_tower = tower_mod.Tower.init(false),
            .units = unit_mod.UnitManager.init(),
            .ai = ai_mod.AI.init(),
            .camera = camera_mod.Camera.init(),
            .ui = ui_mod.UI.init(),
            .player_build_queue = ui_mod.BuildQueue.init(),
        };
    }

    pub fn update(self: *Game, dt: f32) void {
        if (self.state != .playing) {
            if (rl.isKeyPressed(.r)) {
                self.* = Game.init();
            }
            return;
        }

        self.camera.update(dt);
        background.update(dt);
        particles.update(dt);

        self.income_timer += dt;
        if (self.income_timer >= 1.0) {
            self.income_timer -= 1.0;
            self.player_gold += @intFromFloat(config.PASSIVE_INCOME);
        }

        self.handleInput();

        if (self.player_build_queue.update(dt)) |unit_type| {
            _ = self.units.spawn(unit_type, true);
        }

        if (self.ai.build_queue.update(dt)) |unit_type| {
            _ = self.units.spawn(unit_type, false);
        }

        var player_base_hp = self.player_base.hp;
        var enemy_base_hp = self.enemy_base.hp;
        var player_gold = self.player_gold;
        var enemy_gold = self.ai.gold;
        var player_xp = self.player_xp;
        var enemy_xp = self.ai.xp;

        self.units.update(dt, &player_base_hp, &enemy_base_hp, &player_gold, &enemy_gold, &player_xp, &enemy_xp);

        self.player_base.hp = player_base_hp;
        self.enemy_base.hp = enemy_base_hp;
        self.player_gold = player_gold;
        self.ai.gold = enemy_gold;
        self.player_xp = player_xp;
        self.ai.xp = enemy_xp;

        self.player_tower.update(dt, &self.units, &self.player_gold, &self.ai.gold, &self.player_xp, &self.ai.xp);
        self.enemy_tower.update(dt, &self.units, &self.player_gold, &self.ai.gold, &self.player_xp, &self.ai.xp);

        self.ai.update(dt);

        self.updateLevel();

        if (self.player_base.hp <= 0) {
            self.state = .defeat;
        } else if (self.enemy_base.hp <= 0) {
            self.state = .victory;
        }
    }

    fn handleInput(self: *Game) void {
        if (rl.isKeyPressed(.one)) self.tryBuyUnit(.melee);
        if (rl.isKeyPressed(.two)) self.tryBuyUnit(.ranged);
        if (rl.isKeyPressed(.three)) self.tryBuyUnit(.special);
        if (rl.isKeyPressed(.four)) self.tryBuyUnit(.tank);

        const player_tower_built = self.player_tower.tier != null;
        if (self.ui.update(self.player_gold, player_tower_built, self.camera.x)) |action| {
            switch (action) {
                .buy_unit => |unit_type| self.tryBuyUnit(unit_type),
                .buy_tower => |tier| self.tryBuyTower(tier),
                .sell_tower => self.sellTower(),
            }
        }
    }

    fn sellTower(self: *Game) void {
        if (self.player_tower.tier) |tier| {
            const refund = config.TOWER_STATS[@intFromEnum(tier)].cost / 2;
            self.player_gold += refund;
            self.player_tower.tier = null;
        }
    }

    fn tryBuyUnit(self: *Game, unit_type: config.UnitType) void {
        const cost = config.UNIT_STATS[@intFromEnum(unit_type)].cost;
        if (self.player_gold >= cost) {
            if (self.player_build_queue.add(unit_type)) {
                self.player_gold -= cost;
            }
        }
    }

    fn tryBuyTower(self: *Game, tier: config.TowerTier) void {
        if (self.player_tower.tier != null) return;
        const cost = config.TOWER_STATS[@intFromEnum(tier)].cost;
        if (self.player_gold >= cost) {
            self.player_tower.build(tier);
            self.player_gold -= cost;
        }
    }

    fn updateLevel(self: *Game) void {
        while (self.player_level < config.MAX_LEVEL) {
            const xp_needed = config.XP_PER_LEVEL[self.player_level];
            if (self.player_xp >= xp_needed) {
                self.player_xp -= xp_needed;
                self.player_level += 1;
            } else break;
        }
    }

    pub fn draw(self: *Game) void {
        background.draw(self.camera.x);

        self.player_base.draw(self.camera.x);
        self.enemy_base.draw(self.camera.x);

        self.player_tower.draw(self.camera.x, self.ui.tower_button_hovered);
        self.enemy_tower.draw(self.camera.x, false);

        self.units.draw(self.camera.x);
        particles.draw(self.camera.x);

        self.ui.draw(
            self.player_gold,
            self.player_xp,
            self.ai.xp,
            self.player_level,
            self.ai.level,
            self.player_tower.tier != null,
            self.player_tower.tier,
            self.camera.x,
            &self.player_build_queue,
            &self.ai.build_queue,
        );

        self.drawCameraIndicator();

        if (self.state != .playing) {
            self.drawEndScreen();
        }
    }

    fn drawCameraIndicator(self: *Game) void {
        const indicator_y: f32 = @as(f32, @floatFromInt(config.SCREEN_HEIGHT)) - 30;
        const indicator_width: f32 = 200;
        const indicator_x: f32 = (@as(f32, @floatFromInt(config.SCREEN_WIDTH)) - indicator_width) / 2;

        rl.drawRectangle(@intFromFloat(indicator_x), @intFromFloat(indicator_y), @intFromFloat(indicator_width), 10, .{ .r = 40, .g = 40, .b = 50, .a = 200 });

        const max_scroll = config.WORLD_WIDTH - @as(f32, @floatFromInt(config.SCREEN_WIDTH));
        const scroll_ratio = self.camera.x / max_scroll;
        const viewport_width = indicator_width * (@as(f32, @floatFromInt(config.SCREEN_WIDTH)) / config.WORLD_WIDTH);
        const viewport_x = indicator_x + scroll_ratio * (indicator_width - viewport_width);

        rl.drawRectangle(@intFromFloat(viewport_x), @intFromFloat(indicator_y), @intFromFloat(viewport_width), 10, .{ .r = 150, .g = 150, .b = 200, .a = 255 });

        const player_marker = indicator_x + (config.PLAYER_BASE_X / config.WORLD_WIDTH) * indicator_width;
        rl.drawCircle(@intFromFloat(player_marker), @intFromFloat(indicator_y + 5), 4, .{ .r = 100, .g = 150, .b = 255, .a = 255 });

        const enemy_marker = indicator_x + (config.ENEMY_BASE_X / config.WORLD_WIDTH) * indicator_width;
        rl.drawCircle(@intFromFloat(enemy_marker), @intFromFloat(indicator_y + 5), 4, .{ .r = 255, .g = 100, .b = 100, .a = 255 });

        rl.drawText("<A/D>", @intFromFloat(indicator_x - 50), @intFromFloat(indicator_y - 2), 12, .{ .r = 150, .g = 150, .b = 170, .a = 200 });
    }

    fn drawEndScreen(self: *Game) void {
        rl.drawRectangle(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT, .{ .r = 0, .g = 0, .b = 0, .a = 180 });

        const text: [:0]const u8 = if (self.state == .victory) "VICTORY!" else "DEFEAT";
        const color: rl.Color = if (self.state == .victory) .{ .r = 100, .g = 255, .b = 100, .a = 255 } else .{ .r = 255, .g = 100, .b = 100, .a = 255 };
        const text_width = rl.measureText(text, 60);
        rl.drawText(text, @divTrunc(config.SCREEN_WIDTH - text_width, 2), @divTrunc(config.SCREEN_HEIGHT, 2) - 50, 60, color);

        const restart_text: [:0]const u8 = "Press R to restart";
        const restart_width = rl.measureText(restart_text, 24);
        rl.drawText(restart_text, @divTrunc(config.SCREEN_WIDTH - restart_width, 2), @divTrunc(config.SCREEN_HEIGHT, 2) + 30, 24, .{ .r = 200, .g = 200, .b = 200, .a = 255 });
    }
};
