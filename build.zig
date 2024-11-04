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
    const exe = b.addExecutable(.{
        // the name of your project
        .name = "oculus-2",
        // your main function
        .root_source_file = b.path("src/main.zig"),
        // references the ones you declared above
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const test_comp = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const websocket = b.createModule(.{
        .root_source_file = b.path("lib/websocket.zig/src/websocket.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const zig_tls_http = b.createModule(.{
        .root_source_file = b.path("lib/zig-tls12/src/entry.zig"),
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

    const zmpl = b.createModule(.{
        //.name = "zlib",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("lib/zmpl/src/zmpl.zig"),
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

    websocket.addImport("zlib", zlib_zig);
    websocket.addImport("tls12", zig_tls_http);

    // now install your own executable after it's built correctly

    exe.root_module.addImport("ws", websocket);
    exe.root_module.addImport("tls12", zig_tls_http);
    exe.root_module.addImport("zlib", zlib_zig);
    exe.root_module.addImport("zmpl", zmpl);

    // test
    test_comp.root_module.addImport("ws", websocket);
    test_comp.root_module.addImport("tls12", zig_tls_http);
    test_comp.root_module.addImport("zlib", zlib_zig);

    const run_test_comp = b.addRunArtifact(test_comp);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_comp.step);
    test_step.dependOn(&run_test_comp.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
