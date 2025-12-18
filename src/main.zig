const rl = @import("raylib");
const config = @import("config.zig");
const Game = @import("game.zig").Game;

pub fn main() anyerror!void {
    rl.initWindow(config.SCREEN_WIDTH, config.SCREEN_HEIGHT, "Age of War");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var game = Game.init();

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.escape)) break;

        const dt: f32 = rl.getFrameTime();
        game.update(dt);

        rl.beginDrawing();
        defer rl.endDrawing();
        game.draw();
    }
}
