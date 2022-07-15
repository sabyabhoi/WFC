pub const WIDTH: u16 = 1024;
pub const HEIGHT: u16 = 1024;
pub const DIM: u16 = 16;
pub const SIDE: u16 = WIDTH/DIM;

pub const DIR = enum {
    UP, RIGHT, LEFT, DOWN, BLANK,

    /// Get connection of the direction in the following format:
    /// UP RIGHT, LEFT, DOWN
    pub fn sides() [5][4]bool {
        return [5][4]bool{
            [_]bool{true, true, true, false}, // UP
            [_]bool{true, true, false, true}, // RIGHT
            [_]bool{true, false, true, true}, // LEFT
            [_]bool{false, true, true, true}, // DOWN
            [_]bool{false, false, false, false}, // BLANK
        };
    }
};
