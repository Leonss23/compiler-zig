const std = @import("std");

pub const TokenList = std.MultiArrayList(Token);

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        eof,
        invalid,
        keyword_return,
        keyword_const,
        keyword_var,
        number_literal,
        equal,
        semicolon,
        slash,
        identifier,
        line_comment,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "const", .keyword_const },
        .{ "var", .keyword_var },
        .{ "return", .keyword_return },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub const State = enum {
        start,
        identifier,
        slash,
        line_comment_start,
        doc_comment_start,
        int,
        equal,
    };

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return Tokenizer{
            .buffer = buffer,
            .index = 0,
        };
    }

    pub fn next(self: *Tokenizer) Token {
        var state = State.start;

        var result = Token{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        while (true) : (self.index += 1) {
            const c = self.buffer[self.index];
            // std.debug.print("{}: {c}\n", .{ self.index, c });

            switch (state) {
                .start => switch (c) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            result.tag = .invalid;
                            result.loc.start = self.index;
                            self.index += 1;
                            result.loc.end = self.index;
                            return result;
                        }
                        break;
                    },
                    ' ', '\n', '\t', '\r' => result.loc.start = self.index + 1,
                    'a'...'z', 'A'...'Z', '_' => {
                        result.tag = .identifier;
                        state = .identifier;
                    },
                    '0'...'9' => state = .int,
                    '/' => state = .slash,
                    ';' => result.tag = .semicolon,
                    '=' => state = .equal,
                    else => @panic("unhandled token."),
                },
                .int => {},
                .slash => switch (c) {
                    '/' => {
                        state = .line_comment_start;
                    },
                    else => {
                        result.tag = .slash;
                        break;
                    },
                },
                .line_comment_start => switch (c) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            result.tag = .invalid;
                            self.index += 1;
                        }
                        break;
                    },
                    '/' => state = .doc_comment_start,
                    '\n' => {
                        result.tag = .line_comment;
                        break;
                    },
                    else => {},
                },
                .doc_comment_start => @panic("todo"),
                .equal => @panic("todo"),
                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => {
                        if (Token.getKeyword(self.buffer[result.loc.start..self.index])) |tag| {
                            result.tag = tag;
                        }
                        break;
                    },
                },
            }
        }

        result.loc.end = self.index;
        return result;
    }
};
