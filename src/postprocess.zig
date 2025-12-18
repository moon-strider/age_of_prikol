const rl = @import("raylib");
const config = @import("config.zig");
const shaders_mod = @import("shaders.zig");
const background = @import("background.zig");

pub const PostProcess = struct {
    shaders: shaders_mod.Shaders,
    scene: rl.RenderTexture2D,
    godray_mask: rl.RenderTexture2D,
    chromatic_amount: f32,
    chromatic_timer: f32,

    pub fn init() PostProcess {
        const gr_w = @divTrunc(config.SCREEN_WIDTH, 4);
        const gr_h = @divTrunc(config.SCREEN_HEIGHT, 4);

        const mask = rl.loadRenderTexture(gr_w, gr_h) catch @panic("godray_mask");
        rl.setTextureWrap(mask.texture, .clamp);

        return .{
            .shaders = shaders_mod.Shaders.init(),
            .scene = rl.loadRenderTexture(config.SCREEN_WIDTH, config.SCREEN_HEIGHT) catch @panic("scene"),
            .godray_mask = mask,
            .chromatic_amount = 0,
            .chromatic_timer = 0,
        };
    }

    pub fn deinit(self: *PostProcess) void {
        self.shaders.deinit();
        rl.unloadRenderTexture(self.scene);
        rl.unloadRenderTexture(self.godray_mask);
    }

    pub fn update(self: *PostProcess, dt: f32) void {
        if (self.chromatic_timer > 0) {
            self.chromatic_timer -= dt;
            self.chromatic_amount = self.chromatic_timer * 0.015;
        } else {
            self.chromatic_amount = 0;
        }
    }

    pub fn triggerImpact(self: *PostProcess) void {
        self.chromatic_timer = 0.2;
    }

    pub fn beginSceneRender(self: *PostProcess) void {
        rl.beginTextureMode(self.scene);
        rl.clearBackground(rl.Color{ .r = 0, .g = 0, .b = 0, .a = 255 });
    }

    pub fn endSceneRender(_: *PostProcess) void {
        rl.endTextureMode();
    }

    pub fn renderGodrayMask(self: *PostProcess, camera_x: f32) void {
        const source_screen_x = background.getLightSourceScreenX(camera_x);

        rl.beginTextureMode(self.godray_mask);
        rl.clearBackground(rl.Color{ .r = 0, .g = 0, .b = 0, .a = 255 });

        const scale: f32 = 0.25;
        const sx: i32 = @intFromFloat(source_screen_x * scale);
        const sy: i32 = -70;

        rl.drawCircle(sx, sy, 200, rl.Color{ .r = 255, .g = 240, .b = 200, .a = 255 });
        rl.drawCircle(sx, sy, 120, rl.Color{ .r = 255, .g = 250, .b = 230, .a = 255 });

        rl.endTextureMode();
    }

    pub fn applyPostProcessing(self: *PostProcess, camera_x: f32) void {
        self.renderGodrayMask(camera_x);
    }

    pub fn drawFinal(self: *PostProcess, camera_x: f32) void {
        drawRenderTexture(self.scene);

        const source_screen_x = background.getLightSourceScreenX(camera_x);
        const screen_w: f32 = @floatFromInt(config.SCREEN_WIDTH);

        const light_norm_x = source_screen_x / screen_w;
        const light_norm_y: f32 = -0.26;

        self.shaders.setGodrayParams(light_norm_x, light_norm_y, 0.25, 0.97, 1.0);

        rl.beginBlendMode(rl.BlendMode.additive);
        rl.beginShaderMode(self.shaders.godrays);

        const src = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.godray_mask.texture.width),
            .height = @floatFromInt(self.godray_mask.texture.height),
        };
        const dst = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(config.SCREEN_WIDTH),
            .height = @floatFromInt(config.SCREEN_HEIGHT),
        };
        rl.drawTexturePro(self.godray_mask.texture, src, dst, .{ .x = 0, .y = 0 }, 0, rl.Color.white);

        rl.endShaderMode();
        rl.endBlendMode();
    }

    pub fn getLightPosition(_: *PostProcess, camera_x: f32) struct { x: f32, y: f32 } {
        return .{
            .x = background.getLightSourceScreenX(camera_x),
            .y = -50,
        };
    }
};

fn drawRenderTexture(rt: rl.RenderTexture2D) void {
    const src = rl.Rectangle{
        .x = 0,
        .y = @floatFromInt(rt.texture.height),
        .width = @floatFromInt(rt.texture.width),
        .height = @floatFromInt(-rt.texture.height),
    };
    const dst = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(config.SCREEN_WIDTH),
        .height = @floatFromInt(config.SCREEN_HEIGHT),
    };
    rl.drawTexturePro(rt.texture, src, dst, .{ .x = 0, .y = 0 }, 0, rl.Color.white);
}
