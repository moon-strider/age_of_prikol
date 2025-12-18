const rl = @import("raylib");
const config = @import("config.zig");

pub const ShaderType = enum {
    bloom_extract,
    blur_horizontal,
    blur_vertical,
    bloom_combine,
    godrays,
    clouds,
    atmosphere,
    vignette,
    chromatic,
    dissolve,
};

pub const Shaders = struct {
    bloom_extract: rl.Shader,
    blur_horizontal: rl.Shader,
    blur_vertical: rl.Shader,
    bloom_combine: rl.Shader,
    godrays: rl.Shader,
    clouds: rl.Shader,
    atmosphere: rl.Shader,
    vignette: rl.Shader,
    chromatic: rl.Shader,
    dissolve: rl.Shader,

    bloom_threshold_loc: c_int,
    blur_resolution_loc_h: c_int,
    blur_resolution_loc_v: c_int,
    bloom_intensity_loc: c_int,
    bloom_texture_loc: c_int,

    godrays_light_pos_loc: c_int,
    godrays_exposure_loc: c_int,
    godrays_decay_loc: c_int,
    godrays_density_loc: c_int,
    godrays_weight_loc: c_int,
    godrays_samples_loc: c_int,
    godrays_time_loc: c_int,

    clouds_time_loc: c_int,
    clouds_resolution_loc: c_int,
    clouds_light_pos_loc: c_int,
    clouds_light_intensity_loc: c_int,

    atmosphere_time_loc: c_int,
    atmosphere_light_pos_loc: c_int,
    atmosphere_fog_density_loc: c_int,
    atmosphere_fog_color_loc: c_int,
    atmosphere_light_color_loc: c_int,
    atmosphere_light_intensity_loc: c_int,

    vignette_intensity_loc: c_int,
    vignette_smoothness_loc: c_int,

    chromatic_amount_loc: c_int,
    chromatic_center_loc: c_int,

    dissolve_amount_loc: c_int,
    dissolve_edge_color_loc: c_int,
    dissolve_edge_width_loc: c_int,

    pub fn init() Shaders {
        const vs_path = "shaders/default.vs";

        var shaders: Shaders = undefined;

        shaders.bloom_extract = rl.loadShader(vs_path, "shaders/bloom_extract.fs") catch @panic("Failed to load bloom_extract shader");
        shaders.blur_horizontal = rl.loadShader(vs_path, "shaders/blur_horizontal.fs") catch @panic("Failed to load blur_horizontal shader");
        shaders.blur_vertical = rl.loadShader(vs_path, "shaders/blur_vertical.fs") catch @panic("Failed to load blur_vertical shader");
        shaders.bloom_combine = rl.loadShader(vs_path, "shaders/bloom_combine.fs") catch @panic("Failed to load bloom_combine shader");
        shaders.godrays = rl.loadShader(vs_path, "shaders/godrays.fs") catch @panic("Failed to load godrays shader");
        shaders.clouds = rl.loadShader(vs_path, "shaders/clouds.fs") catch @panic("Failed to load clouds shader");
        shaders.atmosphere = rl.loadShader(vs_path, "shaders/atmosphere.fs") catch @panic("Failed to load atmosphere shader");
        shaders.vignette = rl.loadShader(vs_path, "shaders/vignette.fs") catch @panic("Failed to load vignette shader");
        shaders.chromatic = rl.loadShader(vs_path, "shaders/chromatic.fs") catch @panic("Failed to load chromatic shader");
        shaders.dissolve = rl.loadShader(vs_path, "shaders/dissolve.fs") catch @panic("Failed to load dissolve shader");

        shaders.bloom_threshold_loc = rl.getShaderLocation(shaders.bloom_extract, "threshold");
        shaders.blur_resolution_loc_h = rl.getShaderLocation(shaders.blur_horizontal, "resolution");
        shaders.blur_resolution_loc_v = rl.getShaderLocation(shaders.blur_vertical, "resolution");
        shaders.bloom_intensity_loc = rl.getShaderLocation(shaders.bloom_combine, "bloomIntensity");
        shaders.bloom_texture_loc = rl.getShaderLocation(shaders.bloom_combine, "bloomTexture");

        shaders.godrays_light_pos_loc = rl.getShaderLocation(shaders.godrays, "lightPos");
        shaders.godrays_exposure_loc = rl.getShaderLocation(shaders.godrays, "exposure");
        shaders.godrays_decay_loc = rl.getShaderLocation(shaders.godrays, "decay");
        shaders.godrays_density_loc = rl.getShaderLocation(shaders.godrays, "density");
        shaders.godrays_weight_loc = rl.getShaderLocation(shaders.godrays, "weight");
        shaders.godrays_samples_loc = rl.getShaderLocation(shaders.godrays, "numSamples");
        shaders.godrays_time_loc = rl.getShaderLocation(shaders.godrays, "time");

        shaders.clouds_time_loc = rl.getShaderLocation(shaders.clouds, "time");
        shaders.clouds_resolution_loc = rl.getShaderLocation(shaders.clouds, "resolution");
        shaders.clouds_light_pos_loc = rl.getShaderLocation(shaders.clouds, "lightPos");
        shaders.clouds_light_intensity_loc = rl.getShaderLocation(shaders.clouds, "lightIntensity");

        shaders.atmosphere_time_loc = rl.getShaderLocation(shaders.atmosphere, "time");
        shaders.atmosphere_light_pos_loc = rl.getShaderLocation(shaders.atmosphere, "lightPos");
        shaders.atmosphere_fog_density_loc = rl.getShaderLocation(shaders.atmosphere, "fogDensity");
        shaders.atmosphere_fog_color_loc = rl.getShaderLocation(shaders.atmosphere, "fogColor");
        shaders.atmosphere_light_color_loc = rl.getShaderLocation(shaders.atmosphere, "lightColor");
        shaders.atmosphere_light_intensity_loc = rl.getShaderLocation(shaders.atmosphere, "lightIntensity");

        shaders.vignette_intensity_loc = rl.getShaderLocation(shaders.vignette, "intensity");
        shaders.vignette_smoothness_loc = rl.getShaderLocation(shaders.vignette, "smoothness");

        shaders.chromatic_amount_loc = rl.getShaderLocation(shaders.chromatic, "amount");
        shaders.chromatic_center_loc = rl.getShaderLocation(shaders.chromatic, "center");

        shaders.dissolve_amount_loc = rl.getShaderLocation(shaders.dissolve, "dissolveAmount");
        shaders.dissolve_edge_color_loc = rl.getShaderLocation(shaders.dissolve, "edgeColor");
        shaders.dissolve_edge_width_loc = rl.getShaderLocation(shaders.dissolve, "edgeWidth");

        return shaders;
    }

    pub fn deinit(self: *Shaders) void {
        rl.unloadShader(self.bloom_extract);
        rl.unloadShader(self.blur_horizontal);
        rl.unloadShader(self.blur_vertical);
        rl.unloadShader(self.bloom_combine);
        rl.unloadShader(self.godrays);
        rl.unloadShader(self.clouds);
        rl.unloadShader(self.atmosphere);
        rl.unloadShader(self.vignette);
        rl.unloadShader(self.chromatic);
        rl.unloadShader(self.dissolve);
    }

    pub fn setBloomThreshold(self: *Shaders, threshold: f32) void {
        rl.setShaderValue(self.bloom_extract, self.bloom_threshold_loc, &threshold, .float);
    }

    pub fn setBlurResolution(self: *Shaders) void {
        const resolution = [2]f32{ @floatFromInt(config.SCREEN_WIDTH), @floatFromInt(config.SCREEN_HEIGHT) };
        rl.setShaderValue(self.blur_horizontal, self.blur_resolution_loc_h, &resolution, .vec2);
        rl.setShaderValue(self.blur_vertical, self.blur_resolution_loc_v, &resolution, .vec2);
    }

    pub fn setBlurResolutionHalf(self: *Shaders) void {
        const resolution = [2]f32{ @floatFromInt(@divTrunc(config.SCREEN_WIDTH, 2)), @floatFromInt(@divTrunc(config.SCREEN_HEIGHT, 2)) };
        rl.setShaderValue(self.blur_horizontal, self.blur_resolution_loc_h, &resolution, .vec2);
        rl.setShaderValue(self.blur_vertical, self.blur_resolution_loc_v, &resolution, .vec2);
    }

    pub fn setBloomIntensity(self: *Shaders, intensity: f32, bloom_tex_slot: c_int) void {
        rl.setShaderValue(self.bloom_combine, self.bloom_intensity_loc, &intensity, .float);
        rl.setShaderValue(self.bloom_combine, self.bloom_texture_loc, &bloom_tex_slot, .int);
    }

    pub fn setGodrayParams(self: *Shaders, light_x: f32, light_y: f32, exposure: f32, decay: f32, density: f32) void {
        const light_pos = [2]f32{ light_x, light_y };
        rl.setShaderValue(self.godrays, self.godrays_light_pos_loc, &light_pos, .vec2);
        rl.setShaderValue(self.godrays, self.godrays_exposure_loc, &exposure, .float);
        rl.setShaderValue(self.godrays, self.godrays_decay_loc, &decay, .float);
        rl.setShaderValue(self.godrays, self.godrays_density_loc, &density, .float);
    }

    pub fn setCloudsParams(self: *Shaders, time_val: f32, light_x: f32, light_y: f32, intensity: f32) void {
        const resolution = [2]f32{ @floatFromInt(config.SCREEN_WIDTH), @floatFromInt(config.SCREEN_HEIGHT) };
        const light_pos = [2]f32{ light_x, light_y };

        rl.setShaderValue(self.clouds, self.clouds_time_loc, &time_val, .float);
        rl.setShaderValue(self.clouds, self.clouds_resolution_loc, &resolution, .vec2);
        rl.setShaderValue(self.clouds, self.clouds_light_pos_loc, &light_pos, .vec2);
        rl.setShaderValue(self.clouds, self.clouds_light_intensity_loc, &intensity, .float);
    }

    pub fn setAtmosphereParams(self: *Shaders, time_val: f32, light_x: f32, light_y: f32, intensity: f32) void {
        const light_pos = [2]f32{ light_x, light_y };
        const fog_density: f32 = 1.5;
        const fog_color = [3]f32{ 0.4, 0.5, 0.7 };
        const light_color = [3]f32{ 1.0, 0.9, 0.7 };

        rl.setShaderValue(self.atmosphere, self.atmosphere_time_loc, &time_val, .float);
        rl.setShaderValue(self.atmosphere, self.atmosphere_light_pos_loc, &light_pos, .vec2);
        rl.setShaderValue(self.atmosphere, self.atmosphere_fog_density_loc, &fog_density, .float);
        rl.setShaderValue(self.atmosphere, self.atmosphere_fog_color_loc, &fog_color, .vec3);
        rl.setShaderValue(self.atmosphere, self.atmosphere_light_color_loc, &light_color, .vec3);
        rl.setShaderValue(self.atmosphere, self.atmosphere_light_intensity_loc, &intensity, .float);
    }

    pub fn setVignetteParams(self: *Shaders, intensity: f32, smoothness: f32) void {
        rl.setShaderValue(self.vignette, self.vignette_intensity_loc, &intensity, .float);
        rl.setShaderValue(self.vignette, self.vignette_smoothness_loc, &smoothness, .float);
    }

    pub fn setChromaticParams(self: *Shaders, amount: f32, center_x: f32, center_y: f32) void {
        const center = [2]f32{ center_x, center_y };
        rl.setShaderValue(self.chromatic, self.chromatic_amount_loc, &amount, .float);
        rl.setShaderValue(self.chromatic, self.chromatic_center_loc, &center, .vec2);
    }

    pub fn setDissolveParams(self: *Shaders, amount: f32, edge_r: f32, edge_g: f32, edge_b: f32) void {
        const edge_color = [3]f32{ edge_r, edge_g, edge_b };
        const edge_width: f32 = 0.05;
        rl.setShaderValue(self.dissolve, self.dissolve_amount_loc, &amount, .float);
        rl.setShaderValue(self.dissolve, self.dissolve_edge_color_loc, &edge_color, .vec3);
        rl.setShaderValue(self.dissolve, self.dissolve_edge_width_loc, &edge_width, .float);
    }
};
