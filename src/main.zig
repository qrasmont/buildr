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

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(content);
    defer tree.deinit();

    var tree_iter = tree.root.Object.iterator();
    while (tree_iter.next()) |entry| {
        print("{s}\n", .{entry.key_ptr.*});
        const cmds_items = entry.value_ptr.*.Array.items;

        for (cmds_items) |cmd| {
            print("{s}\n", .{cmd.String});
        }
    }
}
