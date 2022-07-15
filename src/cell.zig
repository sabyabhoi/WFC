const std = @import("std");
const ArrayList = std.ArrayList;
const DIR = @import("./globals.zig").DIR;

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
