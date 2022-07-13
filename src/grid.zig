const std = @import("std");
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");

const Cell = struct {
    collapsed: bool,
    options: [5]bool,
    width: i32,
    height: i32,

    pub fn default() Cell {
        return Cell{ .collapsed = false,
                    .width = globals.HEIGHT / globals.DIM,
                    .height = globals.WIDTH / globals.DIM,
                    .options = [5]bool{ true, true, true, true, true } };
    }

    pub fn entropy(self: Cell) u8 {
        var s = 0;
        for (self.options) |option| {
            if(option) { s += 1; }
        }
        return s;
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
    while (i < globals.DIM * globals.DIM) : (i += 1) {
        try grid.append(allocator.*, Cell{ .collapsed = true,
                                          .width = globals.HEIGHT / globals.DIM,
                                          .height = globals.WIDTH / globals.DIM,
                                          .options = [5]bool{ false, true, false, false, false } });
    }

    return grid;
}

pub fn drawGrid(renderer: *c.SDL_Renderer,
                grid: *const MultiArrayList(Cell),
                tiles: *const ArrayList(*c.SDL_Texture)) !void {
    var i: u16 = 0;
    while (i < globals.DIM) : (i += 1) {
        var j: u16 = 0;
        while (j < globals.DIM) : (j += 1) {
            var cell = grid.get(i + j * globals.DIM);
            var box = c.SDL_Rect{ .x = j * cell.width,
                                 .y = i * cell.width,
                                 .w = cell.height,
                                 .h = cell.height };

            if (cell.collapsed) {
                const index = cell.getFirstIndex();
                _ = c.SDL_RenderCopy(renderer, tiles.items[index], null, &box);
            } else {
                _ = c.SDL_RenderCopy(renderer, tiles.items[@enumToInt(globals.DIR.BLANK)], null, &box);
            }
        }
    }
}
