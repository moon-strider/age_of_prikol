pub const SCREEN_WIDTH: i32 = 1920;
pub const SCREEN_HEIGHT: i32 = 1080;
pub const WORLD_WIDTH: f32 = SCREEN_WIDTH * 2;

pub const BASE_WIDTH: f32 = 150;
pub const BASE_HEIGHT: f32 = 200;
pub const BASE_HP: f32 = 1000;
pub const BASE_Y: f32 = SCREEN_HEIGHT - BASE_HEIGHT - 50;

pub const PLAYER_BASE_X: f32 = 50;
pub const ENEMY_BASE_X: f32 = WORLD_WIDTH - BASE_WIDTH - 50;

pub const UnitType = enum(u8) { melee, ranged, special, tank };

pub const UnitStats = struct {
    hp: f32,
    damage: f32,
    speed: f32,
    range: f32,
    attack_cooldown: f32,
    cost: u32,
    width: f32,
    height: f32,
    xp_value: u32,
    build_time: f32,
};

pub const UNIT_STATS = [4]UnitStats{
    .{ .hp = 50, .damage = 15, .speed = 80, .range = 40, .attack_cooldown = 0.8, .cost = 10, .width = 30, .height = 50, .xp_value = 10, .build_time = 2.0 },
    .{ .hp = 35, .damage = 12, .speed = 60, .range = 200, .attack_cooldown = 1.2, .cost = 15, .width = 25, .height = 45, .xp_value = 15, .build_time = 3.0 },
    .{ .hp = 40, .damage = 25, .speed = 70, .range = 80, .attack_cooldown = 1.5, .cost = 30, .width = 28, .height = 48, .xp_value = 30, .build_time = 7.0 },
    .{ .hp = 120, .damage = 8, .speed = 40, .range = 35, .attack_cooldown = 1.0, .cost = 50, .width = 40, .height = 60, .xp_value = 50, .build_time = 15.0 },
};

pub const MAX_BUILD_QUEUE: usize = 10;

pub const COUNTER_BONUS: f32 = 1.5;

pub fn getCounter(unit_type: UnitType) UnitType {
    return switch (unit_type) {
        .melee => .tank,
        .ranged => .melee,
        .special => .ranged,
        .tank => .special,
    };
}

pub fn getCounteredBy(unit_type: UnitType) UnitType {
    return switch (unit_type) {
        .melee => .ranged,
        .ranged => .special,
        .special => .tank,
        .tank => .melee,
    };
}

pub const TowerTier = enum(u8) { tier1, tier2, tier3, tier4 };

pub const TowerStats = struct {
    damage: f32,
    range: f32,
    fire_rate: f32,
    cost: u32,
};

pub const TOWER_STATS = [4]TowerStats{
    .{ .damage = 5, .range = 400, .fire_rate = 1.5, .cost = 50 },
    .{ .damage = 8, .range = 500, .fire_rate = 1.2, .cost = 100 },
    .{ .damage = 12, .range = 600, .fire_rate = 1.0, .cost = 180 },
    .{ .damage = 18, .range = 700, .fire_rate = 0.8, .cost = 300 },
};

pub const TOWER_SLOT_Y: f32 = BASE_Y - 30;
pub const TOWER_WIDTH: f32 = 40;
pub const TOWER_HEIGHT: f32 = 60;

pub const KILL_GOLD_MULTIPLIER: f32 = 1.5;
pub const PASSIVE_INCOME: f32 = 5.0;
pub const STARTING_GOLD: u32 = 20;

pub const XP_PER_LEVEL = [_]u32{ 100, 250, 500, 1000, 2000 };
pub const MAX_LEVEL: u32 = 5;

pub const AI_MIN_SPAWN_DELAY: f32 = 1.5;
pub const AI_MAX_SPAWN_DELAY: f32 = 3.0;
pub const AI_COUNTER_PROBABILITY: f32 = 0.65;

pub const MAX_UNITS: usize = 128;
pub const MAX_PROJECTILES: usize = 64;
pub const MAX_PARTICLES: usize = 256;
pub const MAX_DAMAGE_NUMBERS: usize = 32;

pub const GROUND_Y: f32 = SCREEN_HEIGHT - 50;

pub const PARALLAX_LAYER_COUNT: usize = 3;
pub const CLOUD_COUNT: usize = 12;
pub const CLOUD_MIN_SPEED: f32 = 5;
pub const CLOUD_MAX_SPEED: f32 = 20;

pub const UI_MARGIN: f32 = 20;
pub const UNIT_BUTTON_SIZE: f32 = 70;
pub const UNIT_BUTTON_SPACING: f32 = 10;

pub const TOOLTIP_WIDTH: f32 = 200;
pub const TOOLTIP_PADDING: f32 = 10;

pub const CAMERA_SPEED: f32 = 1200;
pub const CAMERA_SPEED_BOOST: f32 = 3.0;
pub const CAMERA_BOOST_TIME: f32 = 1.0;
pub const CAMERA_EDGE_MARGIN: f32 = 100;
