const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;

pub fn main() !void {
    const src = @embedFile("source.zag");

    var my_tokenizer = Tokenizer.init(src);
    while (true) {
        const token = my_tokenizer.next();
        std.debug.print("{}\n", .{token});
        if (token.tag == .eof) break;
    }
}
