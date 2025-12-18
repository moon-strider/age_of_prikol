const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");

pub const Base = struct {
    x: f32,
    hp: f32,
    max_hp: f32,
    is_player: bool,

    pub fn init(is_player: bool) Base {
        return .{
            .x = if (is_player) config.PLAYER_BASE_X else config.ENEMY_BASE_X,
            .hp = config.BASE_HP,
            .max_hp = config.BASE_HP,
            .is_player = is_player,
        };
    }

    pub fn draw(self: Base, camera_x: f32) void {
        const screen_x = self.x - camera_x;
        if (screen_x < -config.BASE_WIDTH or screen_x > config.SCREEN_WIDTH + config.BASE_WIDTH) return;

        const ix: i32 = @intFromFloat(screen_x);
        const iy: i32 = @intFromFloat(config.BASE_Y);
        const iw: i32 = @intFromFloat(config.BASE_WIDTH);
        const ih: i32 = @intFromFloat(config.BASE_HEIGHT);

        const base_color: rl.Color = if (self.is_player) .{ .r = 70, .g = 100, .b = 160, .a = 255 } else .{ .r = 160, .g = 70, .b = 70, .a = 255 };
        const roof_color: rl.Color = if (self.is_player) .{ .r = 90, .g = 120, .b = 180, .a = 255 } else .{ .r = 180, .g = 90, .b = 90, .a = 255 };

        rl.drawRectangle(ix, iy + 40, iw, ih - 40, base_color);
        rl.drawTriangle(.{ .x = screen_x - 10, .y = config.BASE_Y + 40 }, .{ .x = screen_x + config.BASE_WIDTH / 2, .y = config.BASE_Y - 20 }, .{ .x = screen_x + config.BASE_WIDTH + 10, .y = config.BASE_Y + 40 }, roof_color);

        rl.drawRectangle(ix + 20, iy + 80, 30, 50, .{ .r = 50, .g = 40, .b = 30, .a = 255 });
        rl.drawRectangle(ix + 70, iy + 60, 25, 25, .{ .r = 150, .g = 200, .b = 250, .a = 200 });
        rl.drawRectangle(ix + 105, iy + 60, 25, 25, .{ .r = 150, .g = 200, .b = 250, .a = 200 });

        const flag_pole_x = screen_x + config.BASE_WIDTH / 2;
        const flag_top_y = config.BASE_Y - 60;
        rl.drawLineEx(.{ .x = flag_pole_x, .y = config.BASE_Y + 40 }, .{ .x = flag_pole_x, .y = flag_top_y }, 4, .{ .r = 80, .g = 60, .b = 40, .a = 255 });

        const flag_color: rl.Color = if (self.is_player) .{ .r = 100, .g = 150, .b = 255, .a = 255 } else .{ .r = 255, .g = 100, .b = 100, .a = 255 };
        if (self.is_player) {
            rl.drawTriangle(
                .{ .x = flag_pole_x, .y = flag_top_y },
                .{ .x = flag_pole_x, .y = flag_top_y + 25 },
                .{ .x = flag_pole_x + 35, .y = flag_top_y + 12 },
                flag_color,
            );
        } else {
            rl.drawTriangle(
                .{ .x = flag_pole_x, .y = flag_top_y },
                .{ .x = flag_pole_x - 35, .y = flag_top_y + 12 },
                .{ .x = flag_pole_x, .y = flag_top_y + 25 },
                flag_color,
            );
        }

        drawHealthBar(screen_x, flag_top_y - 30, config.BASE_WIDTH, self.hp, self.max_hp);
        drawHpText(screen_x, flag_top_y - 55, self.hp, self.max_hp);
    }
};

fn drawHealthBar(x: f32, y: f32, w: f32, hp: f32, max_hp: f32) void {
    const bar_height: f32 = 12;
    const hp_ratio = @max(0, hp / max_hp);
    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(w), @intFromFloat(bar_height), .{ .r = 40, .g = 40, .b = 40, .a = 255 });

    const hp_color: rl.Color = if (hp_ratio > 0.5) .{ .r = 80, .g = 180, .b = 80, .a = 255 } else if (hp_ratio > 0.25) .{ .r = 200, .g = 180, .b = 60, .a = 255 } else .{ .r = 200, .g = 60, .b = 60, .a = 255 };

    rl.drawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(w * hp_ratio), @intFromFloat(bar_height), hp_color);
    rl.drawRectangleLines(@intFromFloat(x), @intFromFloat(y), @intFromFloat(w), @intFromFloat(bar_height), .{ .r = 80, .g = 80, .b = 80, .a = 255 });
}

var hp_buf: [32]u8 = undefined;

fn drawHpText(x: f32, y: f32, hp: f32, max_hp: f32) void {
    const text = std.fmt.bufPrintZ(&hp_buf, "{d:.0}/{d:.0}", .{ @max(0, hp), max_hp }) catch "???";
    const text_width = rl.measureText(text, 16);
    rl.drawText(text, @as(i32, @intFromFloat(x + config.BASE_WIDTH / 2)) - @divTrunc(text_width, 2), @intFromFloat(y), 16, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
}
