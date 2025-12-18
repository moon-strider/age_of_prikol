const rl = @import("raylib");
const config = @import("config.zig");

pub const Camera = struct {
    x: f32,
    hold_time_left: f32,
    hold_time_right: f32,

    pub fn init() Camera {
        return .{ .x = 0, .hold_time_left = 0, .hold_time_right = 0 };
    }

    pub fn update(self: *Camera, dt: f32) void {
        const left_held = rl.isKeyDown(.left) or rl.isKeyDown(.a);
        const right_held = rl.isKeyDown(.right) or rl.isKeyDown(.d);

        if (left_held) {
            self.hold_time_left += dt;
            self.hold_time_right = 0;
        } else {
            self.hold_time_left = 0;
        }

        if (right_held) {
            self.hold_time_right += dt;
            self.hold_time_left = 0;
        } else {
            self.hold_time_right = 0;
        }

        var speed = config.CAMERA_SPEED;
        if (self.hold_time_left > config.CAMERA_BOOST_TIME or self.hold_time_right > config.CAMERA_BOOST_TIME) {
            speed *= config.CAMERA_SPEED_BOOST;
        }

        if (left_held) {
            self.x -= speed * dt;
        }
        if (right_held) {
            self.x += speed * dt;
        }

        const max_x = config.WORLD_WIDTH - @as(f32, @floatFromInt(config.SCREEN_WIDTH));
        self.x = @max(0, @min(max_x, self.x));
    }

    pub fn worldToScreen(self: Camera, world_x: f32) f32 {
        return world_x - self.x;
    }

    pub fn screenToWorld(self: Camera, screen_x: f32) f32 {
        return screen_x + self.x;
    }
};
