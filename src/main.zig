const std = @import("std");
const rl = @import("raylib");
const rlg = @import("raygui");

var board = std.mem.zeroes([2][3][3]u8);

var selection: u2 = 0;
var turn: u1 = 0;

fn drawBoard() void { //landscape view render for now.
    const renderheight = rl.getRenderHeight();
    const renderwidth = rl.getRenderWidth();
    const slotsize = @min(@divFloor(renderheight, 3), @divFloor(renderwidth, 6));
    const padding = @divFloor(slotsize, 40);
    rl.clearBackground(rl.Color.black);
    for (0.., board) |player, boardHalf| {
        const xorigin = @divTrunc(@as(i32, @intCast(player)) * rl.getRenderWidth(), 2);
        if (player == turn) {
            rl.drawRectangle(xorigin, slotsize * selection, slotsize * 3, slotsize, rl.Color.green);
        }
        for (0.., boardHalf) |y, column| {
            for (0.., column) |x, slot| {
                const X = @as(i32, @intCast(x));
                const Y = @as(i32, @intCast(y));
                const slotxCenterAlign = xorigin + (if (player == 0) slotsize * (2 - X) else slotsize * X);
                if (slot != 0) {
                    // zig fmt: off
                    rl.drawRectangle(
                        slotxCenterAlign + padding,
                        (Y * slotsize)   + padding,
                        slotsize         - (padding * 2),
                        slotsize         - (padding * 2),
                        rl.Color.white);
                    const crappycentering = @divTrunc(slotsize, 2);
                    const asciislot = [_:0]u8{slot + 48};
                    rl.drawText(
                        &asciislot, 
                        slotxCenterAlign + crappycentering, 
                        (Y * slotsize) + crappycentering, 
                        16, 
                        rl.Color.black);
                    // zig fmt: on
                }
            }
        }
    }
}
fn insertDie(row: u8) bool {
    for (0..3, board[turn][row]) |idx, slot| {
        if (slot == 0) {
            board[turn][row][idx] = 1;
            return true;
        }
    }
    return false;
}
///handles collapsing down the game board after a die is placed in a row.
///when you place a die that matches dice on the other side of the game board, those dice get removed from play and those slots freed.
fn collapseRow(row: u2) void {
    const r1 = board[turn][row];
    const r2 = board[turn +% 1][row];
    for (0..3, r1) |_, target| {
        for (0..3, r2) |idx, slot| {
            if (slot == target) {
                board[turn +% 1][row][idx] = 0;
            }
        }
    }
}

pub fn main() !void {
    const refreshrate = 30;
    const windowheight = 720;
    const windowwidth = 1280;
    const testvalue: i8 = 256;
    _ = testvalue; // autofix
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true });
    rl.initWindow(windowwidth, windowheight, "knucklebones");
    defer rl.closeWindow();
    rl.setTargetFPS(refreshrate);
    while (!rl.windowShouldClose()) {
        while (true) {
            const key = @intFromEnum(rl.getKeyPressed());
            if (key == 0) break;
            switch (key) {
                @intFromEnum(rl.KeyboardKey.key_down) => {
                    selection = (selection + 1) % 3;
                },
                @intFromEnum(rl.KeyboardKey.key_up) => {
                    selection = (selection -% 1);
                    if (selection == 3) selection -= 1;
                },
                @intFromEnum(rl.KeyboardKey.key_enter) => {
                    _ = insertDie(selection);
                    collapseRow(selection);
                    turn +%= 1;
                },
                else => {},
            }
        }
        rl.beginDrawing();
        defer rl.endDrawing();
        drawBoard();
    }
}
