const std = @import("std");
const print = @import("std").debug.print;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const flags = std.fs.File.OpenFlags{};

    const file = std.fs.cwd().openFile(".buildr.json", flags) catch |err| {
        if (err == std.fs.File.OpenError.FileNotFound) {
            print("No .buildr.json file found in cwd.\n", .{});
        } else {
            print("Error on .buildr.json open: {?}.\n", .{err});
        }
        return;
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const reader = file.reader();
    const content = try reader.readAllAlloc(allocator, file_size);
    defer allocator.free(content);

    var args = std.process.args();
    // Consume args[0]: program name
    _ = args.skip();

    var entries = std.ArrayList([]const u8).init(allocator);
    defer entries.deinit();

    while (args.next()) |arg| {
        try entries.append(arg);
    }

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(content);
    defer tree.deinit();

    if (entries.items.len == 0) {
        var cmds = tree.root.Object.get("default") orelse {
            print("No default commands to execute.\n", .{});
            return;
        };

        for (cmds.Array.items) |cmd| {
            print("{s}\n", .{cmd.String});
        }

        return;
    }

    for (entries.items) |entry| {
        var cmds = tree.root.Object.get(entry) orelse {
            print("Cloud not find entry '{s}' in config.\n", .{entry});
            return;
        };

        for (cmds.Array.items) |cmd| {
            print("{s}\n", .{cmd.String});
        }
    }
}
