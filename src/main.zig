const std = @import("std");
const ArrayList = std.ArrayList;
const MultiArrayList = std.MultiArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");
const Grid = @import("./grid.zig").Grid;

pub fn getTiles(renderer: *c.SDL_Renderer, allocator: *const std.mem.Allocator) !ArrayList(*c.SDL_Texture) {
    var tiles = ArrayList(*c.SDL_Texture).init(allocator.*);
    for ([_][*c]const u8{ "assets/empty.png", "assets/up.png", "assets/down.png", "assets/left.png", "assets/right.png" }) |file| {
        var tile = c.IMG_LoadTexture(renderer, file) orelse {
            c.SDL_Log("Unable to load texture: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        try tiles.append(tile);
    }
    return tiles;
}

pub fn main() !void {
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    var window = c.SDL_CreateWindow("Sample Window", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, globals.WIDTH, globals.HEIGHT, 0) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    var renderer = c.SDL_CreateRenderer(window, 0, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const tiles = try getTiles(renderer, &allocator);
    defer tiles.deinit();

    var frame: usize = 0;
    mainloop: while (true) {
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => break :mainloop,
                else => {},
            }
        }
        _ = c.SDL_SetRenderDrawColor(renderer, 0x2a, 0xca, 0xea, 0xff);
        _ = c.SDL_RenderClear(renderer);

        var grid = try Grid.initialize(&allocator);
        defer grid.cells.deinit(allocator);

        try grid.draw(renderer, &tiles);

        c.SDL_RenderPresent(renderer);
        frame += 1;
    }
}
