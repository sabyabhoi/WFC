const test_allocator = std.testing.allocator;
const std = @import("std");
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const c = @import("./c.zig");
const globals = @import("./globals.zig");
const DIR = globals.DIR;

fn intersection(a: *const ArrayList(DIR), b: *const ArrayList(DIR), allocator: *const std.mem.Allocator) !ArrayList(DIR) {
    var ans = ArrayList(DIR).init(allocator.*);
    for (a.items) |ia| {
        for(b.items) |ib| {
            if(ia == ib) try ans.append(ia);
        }
    }
    return ans;
}

pub const Cell = struct {
    collapsed: bool = false,
    options: ArrayList(DIR),
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
            var options = ArrayList(DIR).init(allocator.*);
            try options.appendSlice(&[_]DIR{DIR.BLANK, DIR.UP, DIR.RIGHT, DIR.LEFT, DIR.DOWN});
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

        if(cell.chosen == null) {
            var ix = self.prng.random().intRangeAtMost(usize, 0, cell.entropy() - 1);
            cell.chosen = cell.options.items[ix];

            const collapsedList = self.cells.items(.collapsed);
            if(index % globals.DIM > 0 and !collapsedList[index - 1]) {
                var leftCell = self.cells.get(index - 1);

                const ruleSet = try cell.getRules(DIR.LEFT, self.allocator);
                leftCell.options = try intersection(&leftCell.options, &ruleSet, self.allocator);

                self.cells.set(index - 1, leftCell);
            }
            if(index % globals.DIM < globals.DIM - 1 and !collapsedList[index + 1]) {
                var rightCell = self.cells.get(index + 1);

                const ruleSet = try cell.getRules(DIR.RIGHT, self.allocator);
                rightCell.options = try intersection(&rightCell.options, &ruleSet, self.allocator);

                self.cells.set(index + 1, rightCell);
            }
            if(index >= globals.DIM and !collapsedList[index - globals.DIM]) {
                var topCell = self.cells.get(index - globals.DIM);

                const ruleSet = try cell.getRules(DIR.UP, self.allocator);
                topCell.options = try intersection(&topCell.options, &ruleSet, self.allocator);

                self.cells.set(index - globals.DIM, topCell);
            }
            if(index <= collapsedList.len - 1 - globals.DIM and !collapsedList[index + globals.DIM]) {
                var bottomCell = self.cells.get(index + globals.DIM);

                const ruleSet = try cell.getRules(DIR.DOWN, self.allocator);
                bottomCell.options = try intersection(&bottomCell.options, &ruleSet, self.allocator);

                self.cells.set(index + globals.DIM, bottomCell);
            }
        }
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
                var box = c.SDL_Rect{ .x = i * globals.SIDE,
                                     .y = j * globals.SIDE,
                                     .w = globals.SIDE,
                                     .h = globals.SIDE };

                if (cell.collapsed) {
                    _ = c.SDL_RenderCopy(renderer,
                                         tiles.items[@enumToInt(cell.chosen orelse DIR.BLANK)],
                                         null, &box);
                } else {
                    _ = c.SDL_RenderCopy(renderer, tiles.items[@enumToInt(DIR.BLANK)], null, &box);
                    _ = c.SDL_RenderDrawRect(renderer, &box);
                }
            }
        }
    }
};
