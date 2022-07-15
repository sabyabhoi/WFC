const test_allocator = std.testing.allocator;
const std = @import("std");
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");
const DIR = globals.DIR;

pub const Cell = struct {
    collapsed: bool = false,
    options: ArrayList(u32),
    chosen: ?DIR = null,

    pub fn entropy(self: *Cell) usize {
        return self.options.items.len;
    }

    pub fn getRules(self: *const Cell, look: DIR, allocator: *const std.mem.Allocator) !ArrayList(DIR) {
        if(look == DIR.BLANK) unreachable;
        var rules = ArrayList(DIR).init(allocator.*);
        const sides = DIR.sides();
        const otherSide = switch(look) {
            DIR.UP => DIR.DOWN,
            DIR.DOWN => DIR.UP,
            DIR.LEFT => DIR.RIGHT,
            DIR.RIGHT => DIR.LEFT,
            DIR.BLANK => unreachable,
        };

        var j: usize = 0;
        while(j < 5) : (j += 1) {
            if(sides[@enumToInt(self.chosen.?)][@enumToInt(look)] == sides[j][@enumToInt(otherSide)])
                try rules.append(@intToEnum(DIR, j));
        }

        return rules;
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
            var options = ArrayList(u32).init(allocator.*);
            try options.appendSlice(&[_]u32{0, 1, 2, 3, 4});
            try cells.append(allocator.*, Cell{ .collapsed = false,
                                               .options = options});
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
        var minEntropy: usize = std.math.maxInt(u32);
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
        if(cell.collapsed) return;
        cell.collapsed = true;

        if(cell.chosen == null)
            cell.chosen = @intToEnum(DIR, self.prng.random().intRangeAtMost(usize, 0, cell.entropy() - 1));

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
                    _ = try cell.getRules(DIR.LEFT, self.allocator);
                    _ = c.SDL_RenderCopy(renderer,
                                         tiles.items[cell.options.items[@enumToInt(cell.chosen orelse DIR.BLANK)]],
                                         null, &box);
                } else {
                    _ = c.SDL_RenderCopy(renderer, tiles.items[@enumToInt(DIR.BLANK)], null, &box);
                }
            }
        }
    }
};
