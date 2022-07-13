const std = @import("std");
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");

pub const Cell = struct {
    collapsed: bool = false,
    options: [5]bool = [5]bool{true, true, true, true, true},

    pub fn entropy(self: Cell) u16 {
        var s: u16 = 0;
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
    allocator: *const std.mem.Allocator,
    prng: std.rand.Xoshiro256,

    pub fn create(allocator: *const std.mem.Allocator) !Grid {
        var cells = MultiArrayList(Cell){};

        var i: u16 = 0;
        while (i < globals.DIM * globals.DIM) : (i += 1) {
            try cells.append(allocator.*, Cell{ .collapsed = false,
                                              .options = [5]bool{ false, true, false, false, false } });
        }

        return Grid{.cells = cells, .allocator = allocator,
                    .prng = std.rand.DefaultPrng.init(blk: {
                        var seed: u64 = 4;
                        try std.os.getrandom(std.mem.asBytes(&seed));
                        break :blk seed;
            })};
    }

    fn getMinEntropy(self: *Grid) !ArrayList(u32) {
        // TODO: Use iterators instead of this.
        var minEntropy: u16 = 6;
        var minEntropyList = ArrayList(u32).init(self.allocator.*);

        var i: u32 = 0;
        while(i < self.cells.len) : (i += 1) {
            var cell = self.cells.get(i);
            if(!cell.collapsed and cell.entropy() < minEntropy) {
                minEntropy = cell.entropy();
            }
        }

        i = 0;
        while(i < self.cells.len) : (i += 1) {
            var cell = self.cells.get(i);
            if(!cell.collapsed and cell.entropy() == minEntropy) {
                try minEntropyList.append(i);
            }
        }
        std.debug.print("{any} ", .{minEntropyList.items});
        return minEntropyList;
    }

    pub fn collapse(self: *Grid) !void {
        var minEntropyList = try self.getMinEntropy();
        defer minEntropyList.deinit();
        
        var index = minEntropyList.items.len + 1;
        switch(minEntropyList.items.len) {
            0 => {return;},
            1 => {index = minEntropyList.items[0];},
            else => {
                index = self.prng.random().intRangeAtMost(usize, 0, minEntropyList.items.len - 1);
                index = minEntropyList.items[index];
            },
        }

        var cell = self.cells.get(index);
        cell.collapsed = true;
        self.cells.set(index, cell);
    }

    pub fn draw(self: *Grid,
                renderer: *c.SDL_Renderer,
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
