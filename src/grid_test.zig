const std = @import("std");
const testing = std.testing;
//const test_allocator = std.testing.;

const Cell = @import("./grid.zig").Cell;
const Grid = @import("./grid.zig").Grid;
const DIR = @import("./globals.zig").DIR;

fn logRules(cell: *const Cell, look: DIR, rules: []const DIR) void {
    const otherSide = switch(look) {
        DIR.UP => DIR.DOWN,
        DIR.DOWN => DIR.UP,
        DIR.LEFT => DIR.RIGHT,
        DIR.RIGHT => DIR.LEFT,
        DIR.BLANK => unreachable,
    };

    std.debug.print("\nCell Type = {any}\n", .{cell.chosen.?});
    std.debug.print("Looking at = {any} or {}\n", .{look, @enumToInt(look)});
    std.debug.print("Side of other block = {any} or {}\n", .{otherSide, @enumToInt(otherSide)});
    std.debug.print("Options = {any}\n", .{rules});
}

test "UP Cell rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var options = std.ArrayList(DIR).init(allocator);

    const cell: Cell = Cell{.options = options, .chosen = DIR.UP};

    var rules = try cell.getRules(DIR.UP, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.RIGHT, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.RIGHT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.LEFT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.DOWN});

    rules = try cell.getRules(DIR.DOWN, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.DOWN, DIR.BLANK});
}

test "DOWN Cell rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var options = std.ArrayList(DIR).init(allocator);

    const cell: Cell = Cell{.options = options, .chosen = DIR.DOWN};

    var rules = try cell.getRules(DIR.UP, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.BLANK});

    rules = try cell.getRules(DIR.RIGHT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.LEFT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.DOWN});

    rules = try cell.getRules(DIR.DOWN, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.LEFT});
}

test "LEFT Cell rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var options = std.ArrayList(DIR).init(allocator);

    const cell: Cell = Cell{.options = options, .chosen = DIR.LEFT};

    var rules = try cell.getRules(DIR.UP, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.RIGHT, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.RIGHT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.RIGHT, DIR.BLANK});

    rules = try cell.getRules(DIR.LEFT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.DOWN});

    rules = try cell.getRules(DIR.DOWN, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.LEFT});
}

test "RIGHT Cell rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var options = std.ArrayList(DIR).init(allocator);

    const cell: Cell = Cell{.options = options, .chosen = DIR.RIGHT};

    var rules = try cell.getRules(DIR.UP, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.RIGHT, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.RIGHT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.LEFT, DIR.DOWN});

    rules = try cell.getRules(DIR.LEFT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.LEFT, DIR.BLANK});

    rules = try cell.getRules(DIR.DOWN, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.RIGHT, DIR.LEFT});
}

test "BLANK Cell rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var options = std.ArrayList(DIR).init(allocator);

    const cell: Cell = Cell{.options = options, .chosen = DIR.BLANK};

    var rules = try cell.getRules(DIR.UP, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.UP, DIR.BLANK});

    rules = try cell.getRules(DIR.RIGHT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.RIGHT, DIR.BLANK});

    rules = try cell.getRules(DIR.LEFT, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.LEFT, DIR.BLANK});

    rules = try cell.getRules(DIR.DOWN, &allocator);
    try testing.expectEqualSlices(DIR, rules.items, &[_]DIR{DIR.DOWN, DIR.BLANK});
}
