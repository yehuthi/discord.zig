const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // these are boiler plate code until you know what you are doing
    // and you need to add additional options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    // this is your own program
    const dzig = b.addModule("discord.zig", .{
        .root_source_file = b.path("src/discord.zig"),
        .link_libc = true,
    });

    const websocket = b.dependency("websocket", .{
        .target = target,
        .optimize = optimize,
    });

    const zig_tls = b.dependency("zig-tls", .{
        .target = target,
        .optimize = optimize,
    });

    const zlib_zig = b.createModule(.{
        //.name = "zlib",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("zlib.zig"),
        .link_libc = true,
    });

    const zmpl = b.dependency("zmpl", .{
        .target = target,
        .optimize = optimize,
    });

    const deque = b.dependency("zig-deque", .{
        .target = target,
        .optimize = optimize,
    });

    const marin = b.addExecutable(.{
        .name = "marin",
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const srcs = &.{
        "lib/zlib/adler32.c",
        "lib/zlib/compress.c",
        "lib/zlib/crc32.c",
        "lib/zlib/deflate.c",
        "lib/zlib/gzclose.c",
        "lib/zlib/gzlib.c",
        "lib/zlib/gzread.c",
        "lib/zlib/gzwrite.c",
        "lib/zlib/inflate.c",
        "lib/zlib/infback.c",
        "lib/zlib/inftrees.c",
        "lib/zlib/inffast.c",
        "lib/zlib/trees.c",
        "lib/zlib/uncompr.c",
        "lib/zlib/zutil.c",
    };

    //const mode = b.standardReleaseOptions();

    zlib_zig.addCSourceFiles(.{ .files = srcs, .flags = &.{"-std=c89"} });
    zlib_zig.addIncludePath(b.path("lib/zlib/"));

    // now install your own executable after it's built correctly

    dzig.addImport("ws", websocket.module("websocket"));
    dzig.addImport("tls12", zig_tls.module("zig-tls12"));
    dzig.addImport("zlib", zlib_zig);
    dzig.addImport("zmpl", zmpl.module("zmpl"));
    dzig.addImport("deque", deque.module("zig-deque"));

    marin.root_module.addImport("discord.zig", dzig);
    marin.root_module.addImport("ws", websocket.module("websocket"));
    marin.root_module.addImport("tls12", zig_tls.module("zig-tls12"));
    marin.root_module.addImport("zlib", zlib_zig);
    marin.root_module.addImport("zmpl", zmpl.module("zmpl"));
    marin.root_module.addImport("deque", deque.module("zig-deque"));

    // test
    const run_cmd = b.addRunArtifact(marin);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
