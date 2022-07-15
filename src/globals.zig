const std = @import("std");

pub const WIDTH: u16 = 1024;
pub const HEIGHT: u16 = 1024;
pub const DIM: u16 = 16;
pub const SIDE: u16 = WIDTH/DIM;

pub const DIR = enum {
    UP, RIGHT, DOWN, LEFT, BLANK,

    fn rotate(dir: [4]bool) [4]bool {
        var ans = dir;
        var i: u8 = 0;
        while(i < 4) : (i += 1) {
            ans[i] = dir[(3 + i) % 4];
        }
        return ans;
    }

    /// Get connection of the direction in the following format:
    /// UP, RIGHT, LEFT, DOWN
    pub fn sides() [5][4]bool {
        var ans: [5][4]bool = undefined;
        ans[0] = [_]bool{true, true, false, true}; // UP
        ans[1] = rotate(ans[0]); // RIGHT
        ans[2] = rotate(ans[1]); // DOWN
        ans[3] = rotate(ans[2]); // LEFT
        ans[4] = [_]bool{false} ** 4; // BLANK
        return ans;
    }
};
