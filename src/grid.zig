const std = @import("std");
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");

const Cell = struct {
    collapsed: bool,
    options: [5]bool,

    pub fn default() Cell {
        return Cell{ .collapsed = false,
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

pub const Grid = struct {
    cells: MultiArrayList(Cell),

    pub fn initialize(allocator: *const std.mem.Allocator) !Grid {
        var cells = MultiArrayList(Cell){};

        var i: u16 = 0;
        while (i < globals.DIM * globals.DIM) : (i += 1) {
            try cells.append(allocator.*, Cell{ .collapsed = true,
                                              .options = [5]bool{ false, true, false, false, false } });
        }

        return Grid{.cells = cells};
    }
    
    pub fn draw(self: Grid, renderer: *c.SDL_Renderer,
                    tiles: *const ArrayList(*c.SDL_Texture)) !void {
        var i: u16 = 0;
        while (i < globals.DIM) : (i += 1) {
            var j: u16 = 0;
            while (j < globals.DIM) : (j += 1) {
                var cell = self.cells.get(i + j * globals.DIM);
                var box = c.SDL_Rect{ .x = j * globals.SIDE,
                                     .y = i * globals.SIDE,
                                     .w = globals.SIDE,
                                     .h = globals.SIDE };

                if (cell.collapsed) {
                    const index = cell.getFirstIndex();
                    _ = c.SDL_RenderCopy(renderer, tiles.items[index], null, &box);
                } else {
                    _ = c.SDL_RenderCopy(renderer, tiles.items[@enumToInt(globals.DIR.BLANK)], null, &box);
                }
            }
        }
    }
};


