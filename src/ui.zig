const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");

pub const BuildQueue = struct {
    queue: [config.MAX_BUILD_QUEUE]config.UnitType,
    count: usize,
    build_progress: f32,

    pub fn init() BuildQueue {
        return .{ .queue = undefined, .count = 0, .build_progress = 0 };
    }

    pub fn add(self: *BuildQueue, unit_type: config.UnitType) bool {
        if (self.count >= config.MAX_BUILD_QUEUE) return false;
        self.queue[self.count] = unit_type;
        self.count += 1;
        return true;
    }

    pub fn update(self: *BuildQueue, dt: f32) ?config.UnitType {
        if (self.count == 0) return null;

        const current = self.queue[0];
        const build_time = config.UNIT_STATS[@intFromEnum(current)].build_time;
        self.build_progress += dt;

        if (self.build_progress >= build_time) {
            self.build_progress = 0;
            for (0..self.count - 1) |i| {
                self.queue[i] = self.queue[i + 1];
            }
            self.count -= 1;
            return current;
        }
        return null;
    }

    pub fn getCurrentProgress(self: *BuildQueue) f32 {
        if (self.count == 0) return 0;
        const current = self.queue[0];
        const build_time = config.UNIT_STATS[@intFromEnum(current)].build_time;
        return self.build_progress / build_time;
    }
};

pub const UIAction = union(enum) {
    buy_unit: config.UnitType,
    buy_tower: config.TowerTier,
    sell_tower: void,
};

pub const UI = struct {
    tower_menu_open: bool,
    sell_menu_open: bool,
    hovered_unit: ?config.UnitType,
    hovered_tower: ?config.TowerTier,
    tower_button_hovered: bool,
    sell_button_hovered: bool,

    pub fn init() UI {
        return .{
            .tower_menu_open = false,
            .sell_menu_open = false,
            .hovered_unit = null,
            .hovered_tower = null,
            .tower_button_hovered = false,
            .sell_button_hovered = false,
        };
    }

    pub fn update(self: *UI, gold: u32, player_tower_built: bool, camera_x: f32) ?UIAction {
        const mouse = rl.getMousePosition();
        self.hovered_unit = null;
        self.hovered_tower = null;
        self.tower_button_hovered = false;
        self.sell_button_hovered = false;

        for (0..4) |i| {
            const btn_x = config.UI_MARGIN + @as(f32, @floatFromInt(i)) * (config.UNIT_BUTTON_SIZE + config.UNIT_BUTTON_SPACING);
            const btn_y = config.UI_MARGIN + 80;

            if (isInRect(mouse.x, mouse.y, btn_x, btn_y, config.UNIT_BUTTON_SIZE, config.UNIT_BUTTON_SIZE)) {
                self.hovered_unit = @enumFromInt(i);
                if (rl.isMouseButtonPressed(.left)) {
                    const unit_type: config.UnitType = @enumFromInt(i);
                    const cost = config.UNIT_STATS[i].cost;
                    if (gold >= cost) {
                        return .{ .buy_unit = unit_type };
                    }
                }
            }
        }

        const tower_btn_world_x = config.PLAYER_BASE_X + config.BASE_WIDTH - config.TOWER_WIDTH - 10;
        const tower_btn_screen_x = tower_btn_world_x - camera_x;
        const tower_btn_y = config.TOWER_SLOT_Y;

        if (isInRect(mouse.x, mouse.y, tower_btn_screen_x, tower_btn_y, config.TOWER_WIDTH, config.TOWER_HEIGHT)) {
            self.tower_button_hovered = true;
            if (rl.isMouseButtonPressed(.left)) {
                if (player_tower_built) {
                    self.sell_menu_open = !self.sell_menu_open;
                    self.tower_menu_open = false;
                } else {
                    self.tower_menu_open = !self.tower_menu_open;
                    self.sell_menu_open = false;
                }
            }
        }

        if (self.sell_menu_open and player_tower_built) {
            const menu_x = tower_btn_screen_x + config.TOWER_WIDTH + 15;
            const menu_y = tower_btn_y - 20;
            const menu_w: f32 = 120;
            const menu_h: f32 = 90;

            const sell_btn_y = menu_y + 10;
            const sell_btn_h: f32 = 40;
            if (isInRect(mouse.x, mouse.y, menu_x + 10, sell_btn_y, menu_w - 20, sell_btn_h)) {
                self.sell_button_hovered = true;
                if (rl.isMouseButtonPressed(.left)) {
                    self.sell_menu_open = false;
                    return .{ .sell_tower = {} };
                }
            }

            const close_btn_y = sell_btn_y + sell_btn_h + 5;
            if (isInRect(mouse.x, mouse.y, menu_x + 10, close_btn_y, menu_w - 20, 30)) {
                if (rl.isMouseButtonPressed(.left)) {
                    self.sell_menu_open = false;
                }
            }

            if (rl.isMouseButtonPressed(.left) and !self.tower_button_hovered) {
                if (!isInRect(mouse.x, mouse.y, menu_x, menu_y, menu_w, menu_h)) {
                    self.sell_menu_open = false;
                }
            }
        }

        if (self.tower_menu_open and !player_tower_built) {
            const menu_x = tower_btn_screen_x + config.TOWER_WIDTH + 20;
            const menu_y = tower_btn_y - 220;

            const close_x = menu_x + 320;
            const close_y = menu_y + 10;
            if (isInRect(mouse.x, mouse.y, close_x, close_y, 40, 40)) {
                if (rl.isMouseButtonPressed(.left)) {
                    self.tower_menu_open = false;
                }
            }

            for (0..4) |i| {
                const item_y = menu_y + 60 + @as(f32, @floatFromInt(i)) * 100;
                if (isInRect(mouse.x, mouse.y, menu_x + 10, item_y, 330, 90)) {
                    self.hovered_tower = @enumFromInt(i);
                    if (rl.isMouseButtonPressed(.left)) {
                        const tier: config.TowerTier = @enumFromInt(i);
                        const cost = config.TOWER_STATS[i].cost;
                        if (gold >= cost) {
                            self.tower_menu_open = false;
                            return .{ .buy_tower = tier };
                        }
                    }
                }
            }
        }

        if (rl.isMouseButtonPressed(.left) and !self.tower_button_hovered and self.tower_menu_open) {
            const menu_x = tower_btn_screen_x + config.TOWER_WIDTH + 20;
            const menu_y = tower_btn_y - 220;
            if (!isInRect(mouse.x, mouse.y, menu_x - 10, menu_y - 10, 380, 480)) {
                self.tower_menu_open = false;
            }
        }

        return null;
    }

    pub fn draw(self: *UI, gold: u32, player_xp: u32, enemy_xp: u32, player_level: u32, enemy_level: u32, player_tower_built: bool, player_tower_tier: ?config.TowerTier, camera_x: f32, player_queue: *BuildQueue, enemy_queue: *BuildQueue) void {
        drawPlayerXpAndGold(player_xp, player_level, gold);
        drawEnemyXpBar(enemy_xp, enemy_level);
        self.drawUnitButtons(gold);
        self.drawTowerButton(camera_x, player_tower_built, player_tower_tier, gold);
        drawBuildQueue(player_queue, true);
        drawBuildQueue(enemy_queue, false);

        if (self.hovered_unit) |unit_type| {
            self.drawUnitTooltip(unit_type, gold);
        }

        if (self.hovered_tower) |tier| {
            self.drawTowerTooltip(tier, gold);
        }

        if (self.tower_button_hovered and !self.tower_menu_open and !self.sell_menu_open) {
            if (player_tower_built) {
                if (player_tower_tier) |tier| {
                    self.drawTowerStatsTooltip(tier, camera_x);
                }
            } else {
                drawSimpleTooltip("Build a tower", config.PLAYER_BASE_X + config.BASE_WIDTH - camera_x, config.TOWER_SLOT_Y - 50);
            }
        }

        if (self.sell_menu_open and player_tower_built) {
            self.drawSellMenu(camera_x, player_tower_tier);
        }
    }

    fn drawSellMenu(self: *UI, camera_x: f32, tower_tier: ?config.TowerTier) void {
        const tower_btn_world_x = config.PLAYER_BASE_X + config.BASE_WIDTH - config.TOWER_WIDTH - 10;
        const tower_btn_screen_x = tower_btn_world_x - camera_x;
        const tower_btn_y = config.TOWER_SLOT_Y;

        const menu_x = tower_btn_screen_x + config.TOWER_WIDTH + 15;
        const menu_y = tower_btn_y - 20;
        const menu_w: f32 = 120;
        const menu_h: f32 = 90;

        rl.drawRectangle(@intFromFloat(menu_x), @intFromFloat(menu_y), @intFromFloat(menu_w), @intFromFloat(menu_h), .{ .r = 30, .g = 30, .b = 40, .a = 240 });
        rl.drawRectangleLinesEx(.{ .x = menu_x, .y = menu_y, .width = menu_w, .height = menu_h }, 2, .{ .r = 100, .g = 120, .b = 160, .a = 255 });

        const sell_btn_y = menu_y + 10;
        const sell_btn_h: f32 = 40;
        const sell_bg: rl.Color = if (self.sell_button_hovered) .{ .r = 80, .g = 60, .b = 60, .a = 255 } else .{ .r = 60, .g = 45, .b = 45, .a = 255 };
        rl.drawRectangle(@intFromFloat(menu_x + 10), @intFromFloat(sell_btn_y), @intFromFloat(menu_w - 20), @intFromFloat(sell_btn_h), sell_bg);
        rl.drawRectangleLinesEx(.{ .x = menu_x + 10, .y = sell_btn_y, .width = menu_w - 20, .height = sell_btn_h }, 2, .{ .r = 200, .g = 100, .b = 100, .a = 255 });

        if (tower_tier) |tier| {
            const refund = config.TOWER_STATS[@intFromEnum(tier)].cost / 2;
            var buf: [16:0]u8 = undefined;
            const sell_text = std.fmt.bufPrintZ(&buf, "SELL ${d}", .{refund}) catch "SELL";
            rl.drawText(sell_text, @intFromFloat(menu_x + 15), @intFromFloat(sell_btn_y + 10), 20, .{ .r = 255, .g = 200, .b = 200, .a = 255 });
        }

        const close_btn_y = sell_btn_y + sell_btn_h + 5;
        rl.drawRectangle(@intFromFloat(menu_x + 10), @intFromFloat(close_btn_y), @intFromFloat(menu_w - 20), 30, .{ .r = 50, .g = 50, .b = 60, .a = 255 });
        rl.drawText("X", @intFromFloat(menu_x + 48), @intFromFloat(close_btn_y + 5), 20, .{ .r = 150, .g = 150, .b = 160, .a = 255 });
    }

    fn drawUnitButtons(self: *UI, gold: u32) void {
        const base_y = config.UI_MARGIN + 80;
        const unit_colors = [_]rl.Color{
            .{ .r = 70, .g = 130, .b = 220, .a = 255 },
            .{ .r = 100, .g = 200, .b = 100, .a = 255 },
            .{ .r = 200, .g = 100, .b = 200, .a = 255 },
            .{ .r = 180, .g = 150, .b = 100, .a = 255 },
        };
        const key_labels = [_][:0]const u8{ "1", "2", "3", "4" };

        for (0..4) |i| {
            const btn_x = config.UI_MARGIN + @as(f32, @floatFromInt(i)) * (config.UNIT_BUTTON_SIZE + config.UNIT_BUTTON_SPACING);
            const cost = config.UNIT_STATS[i].cost;
            const affordable = gold >= cost;
            const hovered = if (self.hovered_unit) |h| @intFromEnum(h) == i else false;

            var bg_color: rl.Color = if (affordable) .{ .r = 50, .g = 50, .b = 60, .a = 230 } else .{ .r = 40, .g = 40, .b = 45, .a = 200 };
            if (hovered and affordable) bg_color = .{ .r = 70, .g = 70, .b = 85, .a = 250 };

            rl.drawRectangle(@intFromFloat(btn_x), @intFromFloat(base_y), @intFromFloat(config.UNIT_BUTTON_SIZE), @intFromFloat(config.UNIT_BUTTON_SIZE), bg_color);
            rl.drawRectangleLinesEx(.{ .x = btn_x, .y = base_y, .width = config.UNIT_BUTTON_SIZE, .height = config.UNIT_BUTTON_SIZE }, 2, if (hovered) .{ .r = 255, .g = 255, .b = 255, .a = 255 } else unit_colors[i]);

            drawUnitIcon(btn_x + config.UNIT_BUTTON_SIZE / 2, base_y + 25, @enumFromInt(i), unit_colors[i], true, 1.0);

            rl.drawText(key_labels[i], @intFromFloat(btn_x + 5), @intFromFloat(base_y + 5), 24, .{ .r = 200, .g = 200, .b = 200, .a = 200 });

            var cost_buf: [8:0]u8 = undefined;
            const cost_text = std.fmt.bufPrintZ(&cost_buf, "${d}", .{cost}) catch "$?";
            const cost_color: rl.Color = if (affordable) .{ .r = 255, .g = 220, .b = 100, .a = 255 } else .{ .r = 150, .g = 100, .b = 100, .a = 255 };
            rl.drawText(cost_text, @intFromFloat(btn_x + 8), @intFromFloat(base_y + config.UNIT_BUTTON_SIZE - 26), 24, cost_color);
        }
    }

    fn drawTowerButton(self: *UI, camera_x: f32, built: bool, tier: ?config.TowerTier, gold: u32) void {
        const world_x = config.PLAYER_BASE_X + config.BASE_WIDTH - config.TOWER_WIDTH - 10;
        const screen_x = world_x - camera_x;
        const y = config.TOWER_SLOT_Y;

        if (screen_x < -config.TOWER_WIDTH or screen_x > config.SCREEN_WIDTH) return;

        if (!built) {
            const hovered = self.tower_button_hovered;
            const bg_color: rl.Color = if (hovered) .{ .r = 80, .g = 80, .b = 100, .a = 200 } else .{ .r = 60, .g = 60, .b = 80, .a = 180 };
            rl.drawRectangle(@intFromFloat(screen_x), @intFromFloat(y), @intFromFloat(config.TOWER_WIDTH), @intFromFloat(config.TOWER_HEIGHT), bg_color);
            rl.drawRectangleLinesEx(.{ .x = screen_x, .y = y, .width = config.TOWER_WIDTH, .height = config.TOWER_HEIGHT }, 2, .{ .r = 100, .g = 150, .b = 200, .a = 255 });
            rl.drawText("+", @intFromFloat(screen_x + 12), @intFromFloat(y + 15), 30, .{ .r = 150, .g = 200, .b = 255, .a = 255 });
        }

        if (self.tower_menu_open and !built) {
            self.drawTowerMenu(screen_x, y, gold);
        }

        _ = tier;
    }

    fn drawTowerMenu(self: *UI, btn_x: f32, btn_y: f32, gold: u32) void {
        const menu_x = btn_x + config.TOWER_WIDTH + 20;
        const menu_y = btn_y - 220;
        const menu_w: f32 = 360;
        const menu_h: f32 = 470;

        rl.drawRectangle(@intFromFloat(menu_x - 10), @intFromFloat(menu_y - 10), @intFromFloat(menu_w + 20), @intFromFloat(menu_h + 20), .{ .r = 30, .g = 30, .b = 40, .a = 240 });
        rl.drawRectangleLinesEx(.{ .x = menu_x - 10, .y = menu_y - 10, .width = menu_w + 20, .height = menu_h + 20 }, 3, .{ .r = 100, .g = 120, .b = 160, .a = 255 });

        const close_x = menu_x + menu_w - 30;
        const close_y = menu_y + 10;
        rl.drawText("X", @intFromFloat(close_x), @intFromFloat(close_y), 32, .{ .r = 200, .g = 100, .b = 100, .a = 255 });

        rl.drawText("SELECT TOWER", @intFromFloat(menu_x + 20), @intFromFloat(menu_y + 15), 28, .{ .r = 200, .g = 200, .b = 220, .a = 255 });

        const tier_names = [_][:0]const u8{ "Basic", "Advanced", "Elite", "Ultimate" };

        for (0..4) |i| {
            const item_y = menu_y + 60 + @as(f32, @floatFromInt(i)) * 100;
            const stats = config.TOWER_STATS[i];
            const affordable = gold >= stats.cost;
            const hovered = if (self.hovered_tower) |h| @intFromEnum(h) == i else false;

            var bg: rl.Color = if (affordable) .{ .r = 50, .g = 55, .b = 70, .a = 255 } else .{ .r = 40, .g = 40, .b = 50, .a = 255 };
            if (hovered and affordable) bg = .{ .r = 70, .g = 75, .b = 95, .a = 255 };

            rl.drawRectangle(@intFromFloat(menu_x + 10), @intFromFloat(item_y), 330, 90, bg);
            if (hovered) {
                rl.drawRectangleLinesEx(.{ .x = menu_x + 10, .y = item_y, .width = 330, .height = 90 }, 3, .{ .r = 200, .g = 200, .b = 255, .a = 255 });
            }

            rl.drawText(tier_names[i], @intFromFloat(menu_x + 25), @intFromFloat(item_y + 10), 28, .{ .r = 220, .g = 220, .b = 240, .a = 255 });

            var cost_buf: [16:0]u8 = undefined;
            const cost_text = std.fmt.bufPrintZ(&cost_buf, "${d}", .{stats.cost}) catch "$?";
            const cost_color: rl.Color = if (affordable) .{ .r = 255, .g = 220, .b = 100, .a = 255 } else .{ .r = 150, .g = 100, .b = 100, .a = 255 };
            rl.drawText(cost_text, @intFromFloat(menu_x + 240), @intFromFloat(item_y + 10), 28, cost_color);

            var dmg_buf: [16:0]u8 = undefined;
            const dmg_text = std.fmt.bufPrintZ(&dmg_buf, "DMG:{d:.0}", .{stats.damage}) catch "DMG:?";
            rl.drawText(dmg_text, @intFromFloat(menu_x + 25), @intFromFloat(item_y + 50), 24, .{ .r = 255, .g = 150, .b = 150, .a = 255 });

            var rate_buf: [16:0]u8 = undefined;
            const rate_text = std.fmt.bufPrintZ(&rate_buf, "SPD:{d:.1}s", .{stats.fire_rate}) catch "SPD:?";
            rl.drawText(rate_text, @intFromFloat(menu_x + 160), @intFromFloat(item_y + 50), 24, .{ .r = 150, .g = 200, .b = 255, .a = 255 });
        }
    }

    fn drawUnitTooltip(self: *UI, unit_type: config.UnitType, gold: u32) void {
        _ = self;
        const idx = @intFromEnum(unit_type);
        const stats = config.UNIT_STATS[idx];
        const names = [_][:0]const u8{ "Melee Fighter", "Ranged Archer", "Special Unit", "Heavy Tank" };
        const counters = [_][:0]const u8{ "Strong vs Ranged", "Strong vs Special", "Strong vs Tank", "Strong vs Melee" };

        const tooltip_x = config.UI_MARGIN + @as(f32, @floatFromInt(idx)) * (config.UNIT_BUTTON_SIZE + config.UNIT_BUTTON_SPACING);
        const tooltip_y = config.UI_MARGIN + 80 + config.UNIT_BUTTON_SIZE + 15;
        const tooltip_w: f32 = 380;
        const tooltip_h: f32 = 280;

        rl.drawRectangle(@intFromFloat(tooltip_x), @intFromFloat(tooltip_y), @intFromFloat(tooltip_w), @intFromFloat(tooltip_h), .{ .r = 30, .g = 30, .b = 40, .a = 240 });
        rl.drawRectangleLinesEx(.{ .x = tooltip_x, .y = tooltip_y, .width = tooltip_w, .height = tooltip_h }, 3, .{ .r = 100, .g = 120, .b = 160, .a = 255 });

        rl.drawText(names[idx], @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 15), 32, .{ .r = 255, .g = 255, .b = 255, .a = 255 });

        var hp_buf: [24:0]u8 = undefined;
        const hp_text = std.fmt.bufPrintZ(&hp_buf, "HP: {d:.0}", .{stats.hp}) catch "HP: ?";
        rl.drawText(hp_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 60), 28, .{ .r = 100, .g = 255, .b = 100, .a = 255 });

        var dmg_buf: [24:0]u8 = undefined;
        const dmg_text = std.fmt.bufPrintZ(&dmg_buf, "DMG: {d:.0}", .{stats.damage}) catch "DMG: ?";
        rl.drawText(dmg_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 100), 28, .{ .r = 255, .g = 150, .b = 150, .a = 255 });

        var spd_buf: [24:0]u8 = undefined;
        const spd_text = std.fmt.bufPrintZ(&spd_buf, "SPD: {d:.0}", .{stats.speed}) catch "SPD: ?";
        rl.drawText(spd_text, @intFromFloat(tooltip_x + 200), @intFromFloat(tooltip_y + 60), 28, .{ .r = 150, .g = 200, .b = 255, .a = 255 });

        var rng_buf: [24:0]u8 = undefined;
        const rng_text = std.fmt.bufPrintZ(&rng_buf, "RNG: {d:.0}", .{stats.range}) catch "RNG: ?";
        rl.drawText(rng_text, @intFromFloat(tooltip_x + 200), @intFromFloat(tooltip_y + 100), 28, .{ .r = 255, .g = 220, .b = 150, .a = 255 });

        rl.drawText(counters[idx], @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 150), 24, .{ .r = 255, .g = 200, .b = 100, .a = 255 });

        var build_buf: [24:0]u8 = undefined;
        const build_text = std.fmt.bufPrintZ(&build_buf, "Build: {d:.0}s", .{stats.build_time}) catch "Build: ?";
        rl.drawText(build_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 190), 24, .{ .r = 180, .g = 180, .b = 200, .a = 255 });

        var cost_buf: [24:0]u8 = undefined;
        const cost_text = std.fmt.bufPrintZ(&cost_buf, "Cost: ${d}", .{stats.cost}) catch "Cost: $?";
        const affordable = gold >= stats.cost;
        rl.drawText(cost_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 230), 28, if (affordable) .{ .r = 255, .g = 220, .b = 100, .a = 255 } else .{ .r = 200, .g = 100, .b = 100, .a = 255 });
    }

    fn drawTowerTooltip(self: *UI, tier: config.TowerTier, gold: u32) void {
        _ = self;
        const idx = @intFromEnum(tier);
        const stats = config.TOWER_STATS[idx];
        const names = [_][:0]const u8{ "Basic Tower", "Advanced Tower", "Elite Tower", "Ultimate Tower" };

        const mouse = rl.getMousePosition();
        const tooltip_x = mouse.x + 30;
        const tooltip_y = mouse.y;

        rl.drawRectangle(@intFromFloat(tooltip_x), @intFromFloat(tooltip_y), 340, 180, .{ .r = 30, .g = 30, .b = 40, .a = 240 });
        rl.drawRectangleLinesEx(.{ .x = tooltip_x, .y = tooltip_y, .width = 340, .height = 180 }, 3, .{ .r = 100, .g = 120, .b = 160, .a = 255 });

        rl.drawText(names[idx], @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 15), 28, .{ .r = 255, .g = 255, .b = 255, .a = 255 });

        var dmg_buf: [24:0]u8 = undefined;
        const dmg_text = std.fmt.bufPrintZ(&dmg_buf, "Damage: {d:.0}", .{stats.damage}) catch "Damage: ?";
        rl.drawText(dmg_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 60), 24, .{ .r = 255, .g = 150, .b = 150, .a = 255 });

        var rng_buf: [24:0]u8 = undefined;
        const rng_text = std.fmt.bufPrintZ(&rng_buf, "Range: {d:.0}", .{stats.range}) catch "Range: ?";
        rl.drawText(rng_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 100), 24, .{ .r = 255, .g = 220, .b = 150, .a = 255 });

        var rate_buf: [24:0]u8 = undefined;
        const rate_text = std.fmt.bufPrintZ(&rate_buf, "Fire Rate: {d:.1}s", .{stats.fire_rate}) catch "Fire Rate: ?";
        rl.drawText(rate_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 140), 24, .{ .r = 150, .g = 200, .b = 255, .a = 255 });

        _ = gold;
    }

    fn drawTowerStatsTooltip(self: *UI, tier: config.TowerTier, camera_x: f32) void {
        _ = self;
        const idx = @intFromEnum(tier);
        const stats = config.TOWER_STATS[idx];
        const names = [_][:0]const u8{ "Basic Tower", "Advanced Tower", "Elite Tower", "Ultimate Tower" };

        const world_x = config.PLAYER_BASE_X + config.BASE_WIDTH - config.TOWER_WIDTH - 10;
        const tooltip_x = world_x - camera_x + config.TOWER_WIDTH + 15;
        const tooltip_y = config.TOWER_SLOT_Y - 40;

        rl.drawRectangle(@intFromFloat(tooltip_x), @intFromFloat(tooltip_y), 300, 160, .{ .r = 30, .g = 30, .b = 40, .a = 240 });
        rl.drawRectangleLinesEx(.{ .x = tooltip_x, .y = tooltip_y, .width = 300, .height = 160 }, 3, .{ .r = 100, .g = 150, .b = 200, .a = 255 });

        rl.drawText(names[idx], @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 12), 24, .{ .r = 220, .g = 220, .b = 255, .a = 255 });

        var dmg_buf: [24:0]u8 = undefined;
        const dmg_text = std.fmt.bufPrintZ(&dmg_buf, "DMG: {d:.0}", .{stats.damage}) catch "DMG: ?";
        rl.drawText(dmg_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 50), 22, .{ .r = 255, .g = 150, .b = 150, .a = 255 });

        var rng_buf: [24:0]u8 = undefined;
        const rng_text = std.fmt.bufPrintZ(&rng_buf, "RNG: {d:.0}", .{stats.range}) catch "RNG: ?";
        rl.drawText(rng_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 85), 22, .{ .r = 255, .g = 220, .b = 150, .a = 255 });

        var rate_buf: [24:0]u8 = undefined;
        const rate_text = std.fmt.bufPrintZ(&rate_buf, "RATE: {d:.1}s", .{stats.fire_rate}) catch "RATE: ?";
        rl.drawText(rate_text, @intFromFloat(tooltip_x + 15), @intFromFloat(tooltip_y + 120), 22, .{ .r = 150, .g = 200, .b = 255, .a = 255 });
    }
};

fn drawPlayerXpAndGold(xp: u32, level: u32, gold: u32) void {
    const bar_width: f32 = 500;
    const bar_height: f32 = 40;
    const x: f32 = config.UI_MARGIN;
    const y: f32 = config.UI_MARGIN;

    var xp_for_next: u32 = 9999;
    if (level < config.MAX_LEVEL) {
        xp_for_next = config.XP_PER_LEVEL[level];
    }
    const ratio: f32 = if (level >= config.MAX_LEVEL) 1.0 else @as(f32, @floatFromInt(xp)) / @as(f32, @floatFromInt(xp_for_next));

    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(bar_width), @intFromFloat(bar_height), .{ .r = 40, .g = 40, .b = 50, .a = 220 });
    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(bar_width * @min(ratio, 1.0)), @intFromFloat(bar_height), .{ .r = 100, .g = 150, .b = 255, .a = 255 });
    rl.drawRectangleLinesEx(.{ .x = x, .y = y, .width = bar_width, .height = bar_height }, 3, .{ .r = 80, .g = 80, .b = 100, .a = 255 });

    var buf: [32:0]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "Lv.{d}", .{level + 1}) catch "Lv.?";
    rl.drawText(text, @intFromFloat(x + 12), @intFromFloat(y + 6), 28, .{ .r = 255, .g = 255, .b = 255, .a = 255 });

    var xp_buf: [32:0]u8 = undefined;
    const xp_text = if (level >= config.MAX_LEVEL)
        std.fmt.bufPrintZ(&xp_buf, "MAX", .{}) catch "MAX"
    else
        std.fmt.bufPrintZ(&xp_buf, "{d}/{d}", .{ xp, xp_for_next }) catch "?/?";
    const text_w = rl.measureText(xp_text, 24);
    rl.drawText(xp_text, @as(i32, @intFromFloat(x + bar_width)) - text_w - 12, @intFromFloat(y + 8), 24, .{ .r = 255, .g = 255, .b = 255, .a = 255 });

    const gold_x = x + bar_width + 20;
    var gold_buf: [16:0]u8 = undefined;
    const gold_text = std.fmt.bufPrintZ(&gold_buf, "$ {d}", .{gold}) catch "$ ???";
    rl.drawRectangle(@intFromFloat(gold_x), @intFromFloat(y), 160, @intFromFloat(bar_height), .{ .r = 40, .g = 40, .b = 50, .a = 220 });
    rl.drawText(gold_text, @intFromFloat(gold_x + 12), @intFromFloat(y + 6), 28, .{ .r = 255, .g = 220, .b = 100, .a = 255 });
}

fn drawEnemyXpBar(xp: u32, level: u32) void {
    const bar_width: f32 = 500;
    const bar_height: f32 = 40;
    const x: f32 = @as(f32, @floatFromInt(config.SCREEN_WIDTH)) - config.UI_MARGIN - bar_width;
    const y: f32 = config.UI_MARGIN;

    var xp_for_next: u32 = 9999;
    if (level < config.MAX_LEVEL) {
        xp_for_next = config.XP_PER_LEVEL[level];
    }
    const ratio: f32 = if (level >= config.MAX_LEVEL) 1.0 else @as(f32, @floatFromInt(xp)) / @as(f32, @floatFromInt(xp_for_next));

    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(bar_width), @intFromFloat(bar_height), .{ .r = 40, .g = 40, .b = 50, .a = 220 });
    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(bar_width * @min(ratio, 1.0)), @intFromFloat(bar_height), .{ .r = 255, .g = 100, .b = 100, .a = 255 });
    rl.drawRectangleLinesEx(.{ .x = x, .y = y, .width = bar_width, .height = bar_height }, 3, .{ .r = 80, .g = 80, .b = 100, .a = 255 });

    var buf: [32:0]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "Enemy Lv.{d}", .{level + 1}) catch "Enemy";
    rl.drawText(text, @intFromFloat(x + 12), @intFromFloat(y + 6), 28, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
}

fn drawBuildQueue(queue: *BuildQueue, is_player: bool) void {
    const icon_size: f32 = 50;
    const active_size: f32 = 65;
    const spacing: f32 = 8;
    const y: f32 = @as(f32, @floatFromInt(config.SCREEN_HEIGHT)) - config.UI_MARGIN - active_size - 20;

    const base_x: f32 = if (is_player) config.UI_MARGIN else @as(f32, @floatFromInt(config.SCREEN_WIDTH)) - config.UI_MARGIN - active_size;

    if (queue.count == 0) return;

    const unit_colors = [_]rl.Color{
        .{ .r = 70, .g = 130, .b = 220, .a = 255 },
        .{ .r = 100, .g = 200, .b = 100, .a = 255 },
        .{ .r = 200, .g = 100, .b = 200, .a = 255 },
        .{ .r = 180, .g = 150, .b = 100, .a = 255 },
    };

    for (0..queue.count) |i| {
        const unit_type = queue.queue[i];
        const color = unit_colors[@intFromEnum(unit_type)];
        const is_building = (i == 0);

        const size = if (is_building) active_size else icon_size;
        var offset: f32 = 0;
        if (i > 0) {
            offset = active_size + spacing + @as(f32, @floatFromInt(i - 1)) * (icon_size + spacing);
        }

        const icon_x = if (is_player) base_x + offset else base_x - offset - (if (i > 0) icon_size - active_size else 0);
        const icon_y = y + (active_size - size) / 2;

        rl.drawRectangle(@intFromFloat(icon_x), @intFromFloat(icon_y), @intFromFloat(size), @intFromFloat(size), .{ .r = 30, .g = 30, .b = 40, .a = 220 });

        if (is_building) {
            const progress = queue.getCurrentProgress();
            const dimmed_color = rl.Color{ .r = color.r / 3, .g = color.g / 3, .b = color.b / 3, .a = 255 };
            drawUnitIcon(icon_x + size / 2, icon_y + size / 2 - 5, unit_type, dimmed_color, is_player, 0.8);

            drawClockFill(icon_x, icon_y, size, progress, color);
        } else {
            drawUnitIcon(icon_x + size / 2, icon_y + size / 2 - 3, unit_type, color, is_player, 0.6);
        }

        rl.drawRectangleLinesEx(.{ .x = icon_x, .y = icon_y, .width = size, .height = size }, 2, if (is_building) color else .{ .r = 80, .g = 80, .b = 100, .a = 200 });
    }
}

fn drawClockFill(x: f32, y: f32, size: f32, progress: f32, color: rl.Color) void {
    const cx = x + size / 2;
    const cy = y + size / 2;
    const radius = size / 2 - 2;

    const segments: i32 = 36;
    const filled_segments: i32 = @intFromFloat(progress * @as(f32, @floatFromInt(segments)));

    var i: i32 = 0;
    while (i < filled_segments) : (i += 1) {
        const start_angle = -90.0 + @as(f32, @floatFromInt(i)) * (360.0 / @as(f32, @floatFromInt(segments)));
        const end_angle = start_angle + (360.0 / @as(f32, @floatFromInt(segments)));
        rl.drawCircleSector(.{ .x = cx, .y = cy }, radius, start_angle, end_angle, 1, .{ .r = color.r, .g = color.g, .b = color.b, .a = 150 });
    }
}

fn drawSimpleTooltip(text: [:0]const u8, x: f32, y: f32) void {
    const padding: f32 = 16;
    const text_w: f32 = @floatFromInt(rl.measureText(text, 28));
    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(text_w + padding * 2), 50, .{ .r = 30, .g = 30, .b = 40, .a = 230 });
    rl.drawText(text, @intFromFloat(x + padding), @intFromFloat(y + 10), 28, .{ .r = 200, .g = 200, .b = 220, .a = 255 });
}

pub fn drawUnitIcon(x: f32, y: f32, unit_type: config.UnitType, color: rl.Color, facing_right: bool, scale: f32) void {
    const ix: i32 = @intFromFloat(x);
    const iy: i32 = @intFromFloat(y);

    switch (unit_type) {
        .melee => {
            const w: i32 = @intFromFloat(16 * scale);
            const h: i32 = @intFromFloat(24 * scale);
            rl.drawRectangle(ix - @divTrunc(w, 2), iy - @divTrunc(h, 2), w, h, color);
        },
        .ranged => {
            rl.drawEllipse(ix, iy, 12 * scale, 15 * scale, color);
        },
        .special => {
            rl.drawPoly(.{ .x = x, .y = y }, 6, 14 * scale, 0, color);
        },
        .tank => {
            const w: i32 = @intFromFloat(20 * scale);
            const h: i32 = @intFromFloat(18 * scale);
            const h2: i32 = @intFromFloat(12 * scale);
            rl.drawRectangle(ix - @divTrunc(w, 2), iy - @divTrunc(h, 4), w, h, color);
            rl.drawRectangle(ix - @divTrunc(w, 4), iy - @divTrunc(h, 2) - h2 + @divTrunc(h, 4), @divTrunc(w, 2), h2, color);
        },
    }
    _ = facing_right;
}

fn isInRect(mx: f32, my: f32, x: f32, y: f32, w: f32, h: f32) bool {
    return mx >= x and mx <= x + w and my >= y and my <= y + h;
}
