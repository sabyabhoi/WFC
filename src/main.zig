const std = @import("std");
const ArrayList = std.ArrayList;
const MultiArrayList = std.MultiArrayList;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_surface.h");
});

const WIDTH: u16 = 512;
const HEIGHT: u16 = 512;
const DIM: u16 = 2;

const DIR = enum { BLANK, UP, DOWN, LEFT, RIGHT };

const Cell = struct {
    collapsed: bool,
    options: [5]bool,
    width: i32,
    height: i32,

    pub fn default() Cell {
        return Cell{ .collapsed = false, .width = HEIGHT / DIM, .height = WIDTH / DIM, .options = [5]bool{ true, true, true, true, true } };
    }

    pub fn getFirstIndex(self: Cell) usize {
        var i: u16 = 0;
        while (i < 5) : (i += 1) {
            if (self.options[i]) {
                break;
            }
        }
        return i;
    }
};

pub fn initializeGrid(allocator: *const std.mem.Allocator) !MultiArrayList(Cell) {
    var grid = MultiArrayList(Cell){};

    var i: u16 = 0;
    while (i < DIM * DIM) : (i += 1) {
        try grid.append(allocator.*, Cell{ .collapsed = true, .width = HEIGHT / DIM, .height = WIDTH / DIM, .options = [5]bool{ false, true, false, false, false } });
    }

    return grid;
}

pub fn drawTiles(renderer: *c.SDL_Renderer, tiles: *const ArrayList(*c.SDL_Texture), allocator: *const std.mem.Allocator) !void {
    var grid = try initializeGrid(allocator);
    defer grid.deinit(allocator.*);

    var i: u16 = 0;
    while (i < DIM) : (i += 1) {
        var j: u16 = 0;
        while (j < DIM) : (j += 1) {
            var cell = grid.get(i + j * DIM);
            var box = c.SDL_Rect{ .x = j * cell.width, .y = i * cell.width, .w = cell.height, .h = cell.height };
            if (cell.collapsed) {
                const index = cell.getFirstIndex();
                if (index >= 5) {
                    c.SDL_Log("No options available");
                    return error.SDLInitializationError;
                }
                _ = c.SDL_RenderCopy(renderer, tiles.items[index], null, &box);
            }
        }
    }
}

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

    var window = c.SDL_CreateWindow("Sample Window", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, 0) orelse {
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

        try drawTiles(renderer, &tiles, &allocator);

        c.SDL_RenderPresent(renderer);
        frame += 1;
    }
}
