const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const Game = @import("game.zig").Game;
const PostProcess = @import("postprocess.zig").PostProcess;

pub fn main() anyerror!void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true });
    rl.initWindow(config.SCREEN_WIDTH, config.SCREEN_HEIGHT, "Age of War");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var postprocess = PostProcess.init();
    defer postprocess.deinit();

    var game = Game.init(&postprocess);

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.escape)) break;

        const dt: f32 = rl.getFrameTime();
        postprocess.update(dt);
        game.update(dt);

        const camera_x = game.camera.x;

        postprocess.beginSceneRender();
        game.drawWorld();
        postprocess.endSceneRender();

        postprocess.applyPostProcessing(camera_x);

        rl.beginDrawing();
        defer rl.endDrawing();

        postprocess.drawFinal(camera_x);

        game.drawUI();

        if (game.state != .playing) {
            game.drawEndScreen();
        }

        drawFPS();
    }
}

fn drawFPS() void {
    const fps = rl.getFPS();
    var buf: [16:0]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "FPS: {d}", .{fps}) catch "FPS: ?";
    rl.drawText(text, config.SCREEN_WIDTH - 100, config.SCREEN_HEIGHT - 30, 20, .{ .r = 200, .g = 200, .b = 200, .a = 150 });
}
