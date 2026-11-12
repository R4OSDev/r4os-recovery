const r4os = @import("r4os");

const config_path = "C:\\R4OS\\CONFIG\\SERVICES.R4S";
const config_max: usize = 4096;
const endpoint_status_op: u16 = 1;
const endpoint_status_timeout_ms: u64 = 5000;
const endpoint_status_attempts: u32 = 3;

pub fn r4_app_main(r4_app: *r4os.App2) i32 {
    var sys = r4_app.system();
    const args = trim(zSlice(sys.argsRaw()));
    return run(&sys, args);
}

const Token = struct {
    token: []const u8,
    rest: []const u8,
};

const Action = enum(u8) {
    start,
    stop,
    restart,
    manual,
    auto,
    disable,
    remove,
};

const ConfigReport = struct {
    missing: bool = false,
    lines: u32 = 0,
    loaded: u32 = 0,
    duplicate: u32 = 0,
    invalid: u32 = 0,
    too_large: bool = false,
};

fn run(sys: *r4os.r4sys.Context, args: []const u8) i32 {
    if (!sys.hasFn("service_start")) {
        sys.println("SERVMAN: Service API unavailable.");
        return 1;
    }

    if (args.len == 0) {
        return printList(sys);
    }

    const first = takeToken(args) orelse {
        return printList(sys);
    };

    if (tokenEquals(first.token, "/?") or tokenEquals(first.token, "HELP")) {
        printUsage(sys);
        return 0;
    }
    if (tokenEquals(first.token, "LIST")) {
        return printList(sys);
    }
    if (tokenEquals(first.token, "LOAD")) return loadConfigCommand(sys, false);
    if (tokenEquals(first.token, "BOOT")) return bootCommand(sys);
    if (tokenEquals(first.token, "SAVE")) return saveConfigCommand(sys);
    if (tokenEquals(first.token, "CONFIG") or tokenEquals(first.token, "DUMP")) return dumpConfigCommand(sys);
    if (tokenEquals(first.token, "DIAG")) return printDiag(sys);
    if (tokenEquals(first.token, "SELFTEST")) return selfTest(sys);
    if (tokenEquals(first.token, "STATUS")) return commandStatus(sys, first.rest);
    if (tokenEquals(first.token, "START")) return commandOne(sys, first.rest, .start);
    if (tokenEquals(first.token, "STOP")) return commandOne(sys, first.rest, .stop);
    if (tokenEquals(first.token, "RESTART")) return commandOne(sys, first.rest, .restart);
    if (tokenEquals(first.token, "ENABLE") or tokenEquals(first.token, "MANUAL")) return commandOne(sys, first.rest, .manual);
    if (tokenEquals(first.token, "AUTO")) return commandOne(sys, first.rest, .auto);
    if (tokenEquals(first.token, "DISABLE")) return commandOne(sys, first.rest, .disable);
    if (tokenEquals(first.token, "REMOVE")) return commandOne(sys, first.rest, .remove);
    if (tokenEquals(first.token, "INSTALL")) return commandInstall(sys, first.rest);

    printUsage(sys);
    return 1;
}

fn printUsage(sys: *r4os.r4sys.Context) void {
    sys.println("SERVMAN - R4OS Service Manager");
    sys.println("Usage: SERVMAN [LIST|LOAD|BOOT|SAVE|CONFIG|DIAG|SELFTEST]");
    sys.println("       SERVMAN STATUS name");
    sys.println("       SERVMAN START|STOP|RESTART name");
    sys.println("       SERVMAN ENABLE|MANUAL|AUTO|DISABLE name");
    sys.println("       SERVMAN REMOVE name");
    sys.println("       SERVMAN INSTALL name path [/ARGS=x] [/AUTO|/DISABLED] [/DESC=x]");
}

fn printDiag(sys: *r4os.r4sys.Context) i32 {
    sys.println("SERVMAN Diagnose");
    sys.println("  Service-API: OK");
    sys.write("  Config: ");
    sys.println(config_path);

    var count: u32 = 0;
    var auto_count: u32 = 0;
    var manual_count: u32 = 0;
    var disabled_count: u32 = 0;
    var running_count: u32 = 0;
    var failed_count: u32 = 0;
    var endpoint_count: u64 = 0;
    var queue_used: u64 = 0;
    var queue_high: u64 = 0;
    var workers: u64 = 0;
    var max_workers: u64 = 0;
    var open_handles: u64 = 0;
    var busy_rejections: u64 = 0;
    var timeouts: u64 = 0;
    var cancellations: u64 = 0;
    var staging: [16]r4os.abi.ServiceDetail = undefined;
    const total = readDetails(sys, &staging) orelse return 1;
    for (staging[0..total]) |detail| {
        count += 1;
        switch (detail.info.start_mode) {
            r4os.abi.service_start_auto => auto_count += 1,
            r4os.abi.service_start_disabled => disabled_count += 1,
            else => manual_count += 1,
        }
        switch (detail.info.state) {
            r4os.abi.service_state_running, r4os.abi.service_state_starting => running_count += 1,
            r4os.abi.service_state_failed => failed_count += 1,
            else => {},
        }
        if ((detail.info.flags & r4os.abi.service_api_flag_endpoint) != 0) endpoint_count += 1;
        queue_used +%= detail.info.queue_used;
        queue_high +%= detail.info.queue_high_water;
        workers +%= detail.info.active_workers;
        if (detail.info.max_active_workers > max_workers) max_workers = detail.info.max_active_workers;
        open_handles +%= detail.info.open_handles;
        busy_rejections +%= detail.info.busy_rejections;
        timeouts +%= detail.info.timeouts;
        cancellations +%= detail.info.cancellations;
    }

    sys.write("  Registered services: ");
    writeUnsigned(sys, count);
    sys.println("");
    sys.write("  Auto: ");
    writeUnsigned(sys, auto_count);
    sys.write("  Manual: ");
    writeUnsigned(sys, manual_count);
    sys.write("  Disabled: ");
    writeUnsigned(sys, disabled_count);
    sys.println("");
    sys.write("  Running/Starting: ");
    writeUnsigned(sys, running_count);
    sys.write("  Failed: ");
    writeUnsigned(sys, failed_count);
    sys.println("");
    sys.write("  Endpoints: ");
    writeUnsigned(sys, endpoint_count);
    sys.write("  QueueUsed: ");
    writeUnsigned(sys, queue_used);
    sys.write("  QueueHigh: ");
    writeUnsigned(sys, queue_high);
    sys.println("");
    sys.write("  Workers: ");
    writeUnsigned(sys, workers);
    sys.write("  MaxWorkers: ");
    writeUnsigned(sys, max_workers);
    sys.write("  OpenHandles: ");
    writeUnsigned(sys, open_handles);
    sys.println("");
    sys.write("  Busy: ");
    writeUnsigned(sys, busy_rejections);
    sys.write("  Timeouts: ");
    writeUnsigned(sys, timeouts);
    sys.write("  Cancels: ");
    writeUnsigned(sys, cancellations);
    sys.println("");
    printConnectivityEndpointDiag(sys);
    return 0;
}

fn printConnectivityEndpointDiag(sys: *r4os.r4sys.Context) void {
    sys.println("  Connectivity endpoints:");
    printConnectivityEndpointLine(sys, "TCPSVC");
    printConnectivityEndpointLine(sys, "FTPSVC");
    printConnectivityEndpointLine(sys, "SSHD");
    printConnectivityEndpointLine(sys, "RDPSVC");
}

fn printConnectivityEndpointLine(sys: *r4os.r4sys.Context, name: [*:0]const u8) void {
    var detail: r4os.abi.ServiceDetail = .{};
    const rc = sys.serviceDetailByName(name, &detail);
    sys.write("    ");
    sys.write(zSlice(name));
    sys.write(": ");
    if (rc != r4os.abi.service_api_result_ok) {
        sys.write("state=");
        sys.write(resultName(rc));
        sys.write(" rc=");
        sys.printI32(rc);
        sys.println("");
        return;
    }
    const endpoint = (detail.info.flags & r4os.abi.service_api_flag_endpoint) != 0;
    const queued = (detail.info.flags & r4os.abi.service_api_flag_queue_backed) != 0;
    sys.write("state=");
    sys.write(serviceStateName(detail.info.state));
    sys.write(" endpoint=");
    sys.write(if (endpoint) "yes" else "no");
    sys.write(" queue=");
    sys.write(if (queued) "yes" else "no");
    sys.write(" q=");
    writeUnsigned(sys, detail.info.queue_used);
    sys.write("/");
    writeUnsigned(sys, detail.info.queue_depth);
    sys.write(" workers=");
    writeUnsigned(sys, detail.info.active_workers);
    sys.write("/");
    writeUnsigned(sys, detail.info.max_active_workers);
    sys.write(" open=");
    writeUnsigned(sys, detail.info.open_handles);
    sys.write(" busy=");
    writeUnsigned(sys, detail.info.busy_rejections);
    sys.write(" timeout=");
    writeUnsigned(sys, detail.info.timeouts);
    sys.write(" cancel=");
    writeUnsigned(sys, detail.info.cancellations);
    const last = spanZ(detail.info.last_error[0..]);
    if (last.len > 0) {
        sys.write(" last=");
        sys.write(last);
    }
    sys.println("");
}

fn selfTest(sys: *r4os.r4sys.Context) i32 {
    sys.println("SERVMAN selftest");
    if (!sys.hasFn("service_start")) return fail(sys, "service-api");
    var info: r4os.abi.ServiceInfo = .{};
    const rc = sys.serviceInfo(0, &info);
    if (rc < 0) return failCode(sys, "service-info", rc);
    var out: [256]u8 = .{0} ** 256;
    var pos: usize = 0;
    if (!append(&out, &pos, "SERVICE;name=TEST;path=C:\\R4OS\\SERVICES\\TEST.R4X;start=manual;enabled=yes\r\n")) return fail(sys, "append");
    var report: ConfigReport = .{};
    parseConfig(sys, out[0..pos], &report, true);
    if (report.lines != 1 or report.invalid != 0) return fail(sys, "parse");
    sys.println("SERVMAN selftest: OK");
    return 0;
}

fn commandStatus(sys: *r4os.r4sys.Context, rest: []const u8) i32 {
    const part = takeToken(rest) orelse {
        printUsage(sys);
        return 1;
    };
    var name_z: [r4os.abi.service_name_bytes + 1]u8 = .{0} ** (r4os.abi.service_name_bytes + 1);
    const name_ptr = makeZ(name_z[0..], part.token) orelse return fail(sys, "name-too-long");
    var detail: r4os.abi.ServiceDetail = .{};
    const rc = sys.serviceDetailByName(name_ptr, &detail);
    if (rc != r4os.abi.service_api_result_ok) {
        printCommandResult(sys, "STATUS", part.token, rc);
        return 1;
    }
    printServiceDetail(sys, &detail);
    printEndpointStatus(sys, name_ptr);
    return 0;
}

fn commandOne(sys: *r4os.r4sys.Context, rest: []const u8, action: Action) i32 {
    const part = takeToken(rest) orelse {
        printUsage(sys);
        return 1;
    };
    var name_z: [r4os.abi.service_name_bytes + 1]u8 = .{0} ** (r4os.abi.service_name_bytes + 1);
    const name_ptr = makeZ(name_z[0..], part.token) orelse return fail(sys, "name-too-long");
    var info: r4os.abi.ServiceInfo = .{};
    const rc = switch (action) {
        .start => sys.serviceStart(name_ptr, &info),
        .stop => sys.serviceStop(name_ptr, &info, 40),
        .restart => sys.serviceRestart(name_ptr, &info),
        .manual => sys.serviceSetStartMode(name_ptr, r4os.abi.service_start_manual, &info),
        .auto => sys.serviceSetStartMode(name_ptr, r4os.abi.service_start_auto, &info),
        .disable => sys.serviceSetStartMode(name_ptr, r4os.abi.service_start_disabled, &info),
        .remove => sys.serviceRemove(name_ptr),
    };
    printCommandResult(sys, actionName(action), part.token, rc);
    if (rc == r4os.abi.service_api_result_self_restart) {
        // Say what to do instead, so the refusal is actionable rather than
        // just a code.
        sys.println("       This command runs inside that service; stopping it");
        sys.println("       would kill this session mid-command.  Run it from the");
        sys.println("       local console, or from a different service/session.");
    }
    if (rc != r4os.abi.service_api_result_ok) return 1;
    if (action == .manual or action == .auto or action == .disable or action == .remove) {
        return if (saveConfig(sys, true)) 0 else 1;
    }
    return 0;
}

fn commandInstall(sys: *r4os.r4sys.Context, rest_raw: []const u8) i32 {
    const name_part = takeToken(rest_raw) orelse {
        printUsage(sys);
        return 1;
    };
    const path_part = takeToken(name_part.rest) orelse {
        printUsage(sys);
        return 1;
    };

    var args_value: [r4os.abi.service_args_bytes]u8 = .{0} ** r4os.abi.service_args_bytes;
    var desc_value: [r4os.abi.service_description_bytes]u8 = .{0} ** r4os.abi.service_description_bytes;
    var mode: u32 = r4os.abi.service_start_manual;
    var rest = path_part.rest;
    while (takeToken(rest)) |part| {
        if (tokenEquals(part.token, "/AUTO")) {
            mode = r4os.abi.service_start_auto;
        } else if (tokenEquals(part.token, "/DISABLED") or tokenEquals(part.token, "/DISABLE")) {
            mode = r4os.abi.service_start_disabled;
        } else if (startsWithIgnoreCase(part.token, "/ARGS=")) {
            setZ(args_value[0..], part.token[6..]);
        } else if (startsWithIgnoreCase(part.token, "/DESC=")) {
            setZ(desc_value[0..], part.token[6..]);
        }
        rest = part.rest;
    }

    var name_z: [r4os.abi.service_name_bytes + 1]u8 = .{0} ** (r4os.abi.service_name_bytes + 1);
    var path_z: [r4os.abi.service_path_bytes + 1]u8 = .{0} ** (r4os.abi.service_path_bytes + 1);
    var args_z: [r4os.abi.service_args_bytes + 1]u8 = .{0} ** (r4os.abi.service_args_bytes + 1);
    var desc_z: [r4os.abi.service_description_bytes + 1]u8 = .{0} ** (r4os.abi.service_description_bytes + 1);
    const name_ptr = makeZ(name_z[0..], name_part.token) orelse return fail(sys, "name-too-long");
    const path_ptr = makeZ(path_z[0..], path_part.token) orelse return fail(sys, "path-too-long");
    const args_ptr = makeZ(args_z[0..], spanZ(args_value[0..])) orelse return fail(sys, "args-too-long");
    const desc_ptr = makeZ(desc_z[0..], spanZ(desc_value[0..])) orelse return fail(sys, "desc-too-long");
    var info: r4os.abi.ServiceInfo = .{};
    const rc = sys.serviceInstall(name_ptr, path_ptr, args_ptr, mode, desc_ptr, &info);
    printCommandResult(sys, "INSTALL", name_part.token, rc);
    if (rc != r4os.abi.service_api_result_ok) return 1;
    return if (saveConfig(sys, true)) 0 else 1;
}

fn loadConfigCommand(sys: *r4os.r4sys.Context, missing_ok: bool) i32 {
    var report: ConfigReport = .{};
    return loadConfig(sys, missing_ok, "LOAD", &report);
}

fn bootCommand(sys: *r4os.r4sys.Context) i32 {
    var report: ConfigReport = .{};
    const load_rc = loadConfig(sys, true, "BOOT", &report);
    if (load_rc != 0 and (report.too_large or (report.loaded == 0 and report.duplicate == 0))) return load_rc;
    return startAutoServices(sys);
}

fn loadConfig(sys: *r4os.r4sys.Context, missing_ok: bool, label: []const u8, report: *ConfigReport) i32 {
    var buf: [config_max]u8 = undefined;
    const read = sys.fileRead(config_path, buf[0..]);
    if (read < 0) {
        report.missing = true;
        if (missing_ok) {
            printConfigReport(sys, label, report);
            return 0;
        }
        sys.write("SERVMAN ");
        sys.write(label);
        sys.write(": ");
        sys.write(config_path);
        sys.println(" is not readable or missing.");
        return 1;
    }
    const len: usize = @intCast(read);
    if (len > buf.len) {
        sys.write("SERVMAN ");
        sys.write(label);
        sys.println(": SERVICES.R4S too large.");
        return 1;
    }
    parseConfig(sys, buf[0..len], report, false);
    printConfigReport(sys, label, report);
    return if (report.invalid == 0 and !report.too_large) 0 else 1;
}

fn saveConfigCommand(sys: *r4os.r4sys.Context) i32 {
    return if (saveConfig(sys, true)) 0 else 1;
}

fn dumpConfigCommand(sys: *r4os.r4sys.Context) i32 {
    var out: [config_max]u8 = undefined;
    const len = writeConfig(sys, out[0..]) orelse {
        sys.println("SERVMAN CONFIG: complete configuration unavailable or buffer too small.");
        return 1;
    };
    const visible = stripBom(out[0..len]);
    sys.write(visible);
    if (visible.len == 0 or visible[visible.len - 1] != '\n') sys.println("");
    return 0;
}

fn saveConfig(sys: *r4os.r4sys.Context, verbose: bool) bool {
    var out: [config_max]u8 = undefined;
    const len = writeConfig(sys, out[0..]) orelse {
        if (verbose) sys.println("SERVMAN SAVE: complete configuration unavailable or buffer too small.");
        return false;
    };
    const written = sys.fileWrite(config_path, out[0..len]);
    if (written != @as(i32, @intCast(len))) {
        if (verbose) sys.println("SERVMAN SAVE: SERVICES.R4S could not be written.");
        return false;
    }
    if (verbose) {
        sys.write("SERVMAN SAVE: ");
        writeUnsigned(sys, len);
        sys.println(" Bytes geschrieben.");
    }
    return true;
}

fn parseConfig(sys: *r4os.r4sys.Context, data_raw: []const u8, report: *ConfigReport, dry_run: bool) void {
    const data = stripBom(data_raw);
    var line_start: usize = 0;
    while (line_start <= data.len) {
        var line_end = line_start;
        while (line_end < data.len and data[line_end] != '\n') : (line_end += 1) {}
        var line = data[line_start..line_end];
        if (line.len > 0 and line[line.len - 1] == '\r') line = line[0 .. line.len - 1];
        parseConfigLine(sys, line, report, dry_run);
        if (line_end >= data.len) break;
        line_start = line_end + 1;
    }
}

fn parseConfigLine(sys: *r4os.r4sys.Context, line_raw: []const u8, report: *ConfigReport, dry_run: bool) void {
    const line = trim(line_raw);
    if (line.len == 0 or line[0] == '#') return;
    report.lines += 1;
    if (!startsWithIgnoreCase(line, "SERVICE")) {
        report.invalid += 1;
        return;
    }

    var name_buf: [r4os.abi.service_name_bytes + 1]u8 = .{0} ** (r4os.abi.service_name_bytes + 1);
    var path_buf: [r4os.abi.service_path_bytes + 1]u8 = .{0} ** (r4os.abi.service_path_bytes + 1);
    var args_buf: [r4os.abi.service_args_bytes + 1]u8 = .{0} ** (r4os.abi.service_args_bytes + 1);
    var desc_buf: [r4os.abi.service_description_bytes + 1]u8 = .{0} ** (r4os.abi.service_description_bytes + 1);
    var mode: u32 = r4os.abi.service_start_manual;
    var enabled = true;

    var field_start: usize = 0;
    var first = true;
    while (field_start <= line.len) {
        var field_end = field_start;
        while (field_end < line.len and line[field_end] != ';') : (field_end += 1) {}
        const field = trim(line[field_start..field_end]);
        if (field.len > 0) {
            if (first and tokenEquals(field, "SERVICE")) {
                first = false;
            } else if (indexOf(field, '=')) |eq| {
                const key = trim(field[0..eq]);
                const value = trim(field[eq + 1 ..]);
                if (tokenEquals(key, "name")) {
                    if (!copyZChecked(name_buf[0..], value)) {
                        report.invalid += 1;
                        return;
                    }
                } else if (tokenEquals(key, "path")) {
                    if (!copyZChecked(path_buf[0..], value)) {
                        report.invalid += 1;
                        return;
                    }
                } else if (tokenEquals(key, "args")) {
                    if (!copyZChecked(args_buf[0..], value)) {
                        report.invalid += 1;
                        return;
                    }
                } else if (tokenEquals(key, "description")) {
                    if (!copyZChecked(desc_buf[0..], value)) {
                        report.invalid += 1;
                        return;
                    }
                } else if (tokenEquals(key, "start")) {
                    if (tokenEquals(value, "auto")) mode = r4os.abi.service_start_auto else if (tokenEquals(value, "disabled")) mode = r4os.abi.service_start_disabled else if (tokenEquals(value, "manual")) mode = r4os.abi.service_start_manual else {
                        report.invalid += 1;
                        return;
                    }
                } else if (tokenEquals(key, "enabled")) {
                    if (tokenEquals(value, "yes") or tokenEquals(value, "true") or tokenEquals(value, "on") or tokenEquals(value, "1")) enabled = true else if (tokenEquals(value, "no") or tokenEquals(value, "false") or tokenEquals(value, "off") or tokenEquals(value, "0")) enabled = false else {
                        report.invalid += 1;
                        return;
                    }
                }
                first = false;
            } else {
                report.invalid += 1;
                return;
            }
        }
        if (field_end >= line.len) break;
        field_start = field_end + 1;
    }

    const name = spanZ(name_buf[0..]);
    const path = spanZ(path_buf[0..]);
    if (name.len == 0 or path.len == 0) {
        report.invalid += 1;
        return;
    }
    if (dry_run) return;

    var info: r4os.abi.ServiceInfo = .{};
    const final_mode = if (!enabled) r4os.abi.service_start_disabled else mode;
    const rc = sys.serviceInstall(@ptrCast(name_buf[0..].ptr), @ptrCast(path_buf[0..].ptr), @ptrCast(args_buf[0..].ptr), final_mode, @ptrCast(desc_buf[0..].ptr), &info);
    if (rc == r4os.abi.service_api_result_ok) {
        report.loaded += 1;
    } else if (rc == r4os.abi.service_api_result_duplicate) {
        report.duplicate += 1;
    } else if (rc == r4os.abi.service_api_result_full) {
        report.too_large = true;
    } else {
        report.invalid += 1;
    }
}

fn readDetails(sys: *r4os.r4sys.Context, staging: []r4os.abi.ServiceDetail) ?usize {
    return switch (r4os.app_services.readCompleteDetails(sys, staging)) {
        .complete => |count| count,
        .failure => |rc| {
            sys.write("SERVMAN: service enumeration failed: ");
            sys.println(resultName(rc));
            return null;
        },
    };
}

fn writeConfig(sys: *r4os.r4sys.Context, out: []u8) ?usize {
    var pos: usize = 0;
    if (!append(out, &pos, "\xEF\xBB\xBF# R4OS SERVICES.R4S\r\n")) return null;
    if (!append(out, &pos, "# Managed by SERVMAN.R4X\r\n")) return null;
    var staging: [16]r4os.abi.ServiceDetail = undefined;
    const count = readDetails(sys, &staging) orelse return null;
    for (staging[0..count]) |detail| {
        if (!append(out, &pos, "SERVICE;name=")) return null;
        if (!append(out, &pos, spanZ(detail.info.name[0..]))) return null;
        if (!append(out, &pos, ";path=")) return null;
        if (!append(out, &pos, spanZ(detail.path[0..]))) return null;
        const args = spanZ(detail.args[0..]);
        if (args.len > 0) {
            if (!append(out, &pos, ";args=")) return null;
            if (!append(out, &pos, args)) return null;
        }
        if (!append(out, &pos, ";start=")) return null;
        if (!append(out, &pos, serviceStartName(detail.info.start_mode))) return null;
        if (!append(out, &pos, ";enabled=")) return null;
        if (!append(out, &pos, if (detail.info.start_mode == r4os.abi.service_start_disabled) "no" else "yes")) return null;
        const desc = spanZ(detail.description[0..]);
        if (desc.len > 0) {
            if (!append(out, &pos, ";description=")) return null;
            if (!append(out, &pos, desc)) return null;
        }
        if (!append(out, &pos, "\r\n")) return null;
    }
    return pos;
}

fn printConfigReport(sys: *r4os.r4sys.Context, label: []const u8, report: *const ConfigReport) void {
    sys.write("SERVMAN ");
    sys.write(label);
    sys.write(": lines=");
    writeUnsigned(sys, report.lines);
    sys.write(" loaded=");
    writeUnsigned(sys, report.loaded);
    sys.write(" duplicate=");
    writeUnsigned(sys, report.duplicate);
    sys.write(" invalid=");
    writeUnsigned(sys, report.invalid);
    if (report.missing) sys.write(" missing=yes");
    if (report.too_large) sys.write(" too-large=yes");
    sys.println("");
}

fn startAutoServices(sys: *r4os.r4sys.Context) i32 {
    var attempted: u32 = 0;
    var started: u32 = 0;
    var failed: u32 = 0;
    var staging: [16]r4os.abi.ServiceDetail = undefined;
    const total = readDetails(sys, &staging) orelse return 1;
    for (staging[0..total]) |detail| {
        if (detail.info.start_mode != r4os.abi.service_start_auto) continue;

        attempted += 1;
        var info: r4os.abi.ServiceInfo = .{};
        const name = spanZ(detail.info.name[0..]);
        const start_rc = sys.serviceStart(@ptrCast(detail.info.name[0..].ptr), &info);
        if (start_rc == r4os.abi.service_api_result_ok) {
            started += 1;
        } else {
            failed += 1;
            printCommandResult(sys, "BOOT", name, start_rc);
        }
    }

    sys.write("SERVMAN BOOT: autostart attempted=");
    writeUnsigned(sys, attempted);
    sys.write(" started=");
    writeUnsigned(sys, started);
    sys.write(" failed=");
    writeUnsigned(sys, failed);
    sys.println("");
    return 0;
}

fn printList(sys: *r4os.r4sys.Context) i32 {
    var staging: [16]r4os.abi.ServiceDetail = undefined;
    const count = readDetails(sys, &staging) orelse return 1;
    sys.println("SERVMAN Services");
    for (staging[0..count]) |*detail| printServiceLine(sys, detail);
    if (count == 0) sys.println("  No registered services.");
    return 0;
}

fn printServiceLine(sys: *r4os.r4sys.Context, detail: *const r4os.abi.ServiceDetail) void {
    sys.write("  ");
    sys.write(spanZ(detail.info.name[0..]));
    sys.write(" state=");
    sys.write(serviceStateName(detail.info.state));
    sys.write(" start=");
    sys.write(serviceStartName(detail.info.start_mode));
    sys.write(" path=");
    sys.write(spanZ(detail.path[0..]));
    if ((detail.info.flags & r4os.abi.service_api_flag_endpoint) != 0) {
        sys.write(" q=");
        writeUnsigned(sys, detail.info.queue_used);
        sys.write("/");
        writeUnsigned(sys, detail.info.queue_depth);
        sys.write(" workers=");
        writeUnsigned(sys, detail.info.active_workers);
    }
    sys.println("");
}

fn printServiceDetail(sys: *r4os.r4sys.Context, detail: *const r4os.abi.ServiceDetail) void {
    sys.write("Name: ");
    sys.println(spanZ(detail.info.name[0..]));
    sys.write("Status: ");
    sys.println(serviceStateName(detail.info.state));
    sys.write("Start: ");
    sys.println(serviceStartName(detail.info.start_mode));
    sys.write("Instance: ");
    writeUnsigned(sys, detail.info.instance_id);
    sys.println("");
    if (detail.info.instance_id != 0 and sys.base.hasDevFn("memory_summary")) {
        if (programInstanceById(sys, detail.info.instance_id)) |instance| {
            sys.write("Memory: ");
            sys.write(memoryProfileName(instance.memory_profile));
            sys.write(" reserveMB=");
            writeUnsigned(sys, instance.memory_reserved_limit / 1024 / 1024);
            sys.write(" commitMB=");
            writeUnsigned(sys, instance.memory_committed_limit / 1024 / 1024);
            sys.write(" usedKB=");
            writeUnsigned(sys, instance.memory_committed_bytes / 1024);
            sys.println("");
        }
    }
    sys.write("ExitCode: ");
    sys.printI32(detail.info.exit_code);
    sys.println("");
    sys.write("Restarts: ");
    writeUnsigned(sys, detail.info.restart_count);
    sys.println("");
    sys.write("Path: ");
    sys.println(spanZ(detail.path[0..]));
    sys.write("Args: ");
    sys.println(spanZ(detail.args[0..]));
    sys.write("Description: ");
    sys.println(spanZ(detail.description[0..]));
    sys.write("LastError: ");
    sys.println(spanZ(detail.info.last_error[0..]));
    if ((detail.info.flags & r4os.abi.service_api_flag_endpoint) != 0) {
        sys.write("EndpointQueue: used=");
        writeUnsigned(sys, detail.info.queue_used);
        sys.write("/");
        writeUnsigned(sys, detail.info.queue_depth);
        sys.write(" high=");
        writeUnsigned(sys, detail.info.queue_high_water);
        sys.write(" workers=");
        writeUnsigned(sys, detail.info.active_workers);
        sys.write("/");
        writeUnsigned(sys, detail.info.max_active_workers);
        sys.write(" open=");
        writeUnsigned(sys, detail.info.open_handles);
        sys.println("");
        sys.write("EndpointErrors: busy=");
        writeUnsigned(sys, detail.info.busy_rejections);
        sys.write(" timeout=");
        writeUnsigned(sys, detail.info.timeouts);
        sys.write(" cancel=");
        writeUnsigned(sys, detail.info.cancellations);
        sys.println("");
    }
}

fn programInstanceById(sys: *r4os.r4sys.Context, id: u32) ?r4os.abi.ProgramInstanceInfo {
    var index: u32 = 0;
    while (true) : (index += 1) {
        var info: r4os.abi.ProgramInstanceInfo = .{};
        if (sys.programInstance(index, &info) <= 0) return null;
        if (info.id == id) return info;
    }
}

fn memoryProfileName(profile: u8) []const u8 {
    return switch (profile) {
        r4os.abi.memory_profile_tiny => "tiny",
        r4os.abi.memory_profile_normal => "normal",
        r4os.abi.memory_profile_desktop => "desktop",
        r4os.abi.memory_profile_service => "service",
        r4os.abi.memory_profile_large_service => "large-service",
        r4os.abi.memory_profile_build_tool => "build-tool",
        r4os.abi.memory_profile_browser => "browser",
        r4os.abi.memory_profile_workstation => "workstation",
        else => "unknown",
    };
}

fn printEndpointStatus(sys: *r4os.r4sys.Context, name: [*:0]const u8) void {
    var info: r4os.abi.ServiceInfo = .{};
    const open_rc = sys.serviceOpen(name, &info);
    if (open_rc != r4os.abi.service_api_result_ok or info.handle == 0) return;
    defer _ = sys.serviceClose(info.handle);

    var header: r4os.abi.ServiceMessageHeader = .{};
    var response: [r4os.abi.service_api_max_payload]u8 = undefined;
    var got: i32 = 0;
    var attempt: u32 = 0;
    while (attempt < endpoint_status_attempts) : (attempt += 1) {
        header = .{};
        got = sys.serviceCall(info.handle, endpoint_status_op, "STATUS", &header, response[0..], sys.ticksFromMilliseconds(endpoint_status_timeout_ms));
        if (got > 0 and header.status == r4os.abi.service_api_result_ok) break;
        sys.sleepTicks(sys.ticksFromMilliseconds(50));
    }
    if (got <= 0 or header.status != r4os.abi.service_api_result_ok) return;
    const len: usize = @intCast(got);
    if (!isPrintableEndpointStatus(response[0..len])) return;
    sys.write("Endpoint: ");
    sys.write(response[0..len]);
    sys.println("");
    if (hasEndpointSessionDiagnostics(response[0..len])) {
        sys.write("EndpointSessions: workers=");
        sys.write(if (containsBytes(response[0..len], "workers=") or containsBytes(response[0..len], "worker_started=")) "yes" else "no");
        sys.write(" sessions=");
        sys.write(if (containsBytes(response[0..len], "sessions=") or containsBytes(response[0..len], "session_handles=")) "yes" else "no");
        sys.write(" slow=");
        sys.write(if (containsBytes(response[0..len], "slow=")) "yes" else "no");
        sys.write(" timeouts=");
        sys.write(if (containsBytes(response[0..len], "timeouts=") or containsBytes(response[0..len], "long_req=")) "yes" else "no");
        sys.println("");
    }
}

fn hasEndpointSessionDiagnostics(value: []const u8) bool {
    return containsBytes(value, "workers=") or
        containsBytes(value, "worker_started=") or
        containsBytes(value, "session_handles=") or
        containsBytes(value, "last_worker=");
}

fn isPrintableEndpointStatus(value: []const u8) bool {
    if (value.len == 0) return false;
    for (value) |ch| {
        if (ch == '\r' or ch == '\n' or ch == '\t') continue;
        if (ch < 0x20 or ch > 0x7e) return false;
    }
    return true;
}

fn containsBytes(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var j: usize = 0;
        while (j < needle.len and haystack[i + j] == needle[j]) : (j += 1) {}
        if (j == needle.len) return true;
    }
    return false;
}

fn printCommandResult(sys: *r4os.r4sys.Context, action: []const u8, name: []const u8, rc: i32) void {
    sys.write("SERVMAN ");
    sys.write(action);
    sys.write(" ");
    sys.write(name);
    sys.write(": ");
    sys.write(resultName(rc));
    sys.write(" (");
    sys.printI32(rc);
    sys.println(")");
}

fn actionName(action: Action) []const u8 {
    return switch (action) {
        .start => "START",
        .stop => "STOP",
        .restart => "RESTART",
        .manual => "MANUAL",
        .auto => "AUTO",
        .disable => "DISABLE",
        .remove => "REMOVE",
    };
}

fn serviceStateName(raw: u32) []const u8 {
    return switch (raw) {
        r4os.abi.service_state_stopped => "stopped",
        r4os.abi.service_state_starting => "starting",
        r4os.abi.service_state_running => "running",
        r4os.abi.service_state_stopping => "stopping",
        r4os.abi.service_state_failed => "failed",
        r4os.abi.service_state_disabled => "disabled",
        else => "empty",
    };
}

fn serviceStartName(raw: u32) []const u8 {
    return switch (raw) {
        r4os.abi.service_start_auto => "auto",
        r4os.abi.service_start_disabled => "disabled",
        else => "manual",
    };
}

fn resultName(rc: i32) []const u8 {
    return switch (rc) {
        r4os.abi.service_api_result_ok => "OK",
        r4os.abi.service_api_result_invalid => "invalid",
        r4os.abi.service_api_result_not_found => "not-found",
        r4os.abi.service_api_result_not_running => "not-running",
        r4os.abi.service_api_result_no_endpoint => "no-endpoint",
        r4os.abi.service_api_result_payload_too_large => "payload-too-large",
        r4os.abi.service_api_result_buffer_too_small => "buffer-too-small",
        r4os.abi.service_api_result_busy => "busy",
        r4os.abi.service_api_result_timeout => "timeout",
        r4os.abi.service_api_result_bad_handle => "bad-handle",
        r4os.abi.service_api_result_full => "full",
        r4os.abi.service_api_result_bad_op => "bad-op",
        r4os.abi.service_api_result_duplicate => "duplicate",
        r4os.abi.service_api_result_bad_path => "bad-path",
        r4os.abi.service_api_result_config_io => "config-io",
        r4os.abi.service_api_result_running => "running",
        r4os.abi.service_api_result_disabled => "disabled",
        r4os.abi.service_api_result_spawn_failed => "spawn-failed",
        r4os.abi.service_api_result_stop_failed => "stop-failed",
        // 0.60.29: refused because the caller runs inside that very service,
        // e.g. `SERVMAN RESTART SSHD` issued over an SSH session.
        r4os.abi.service_api_result_self_restart => "self-restart-refused",
        else => "unknown",
    };
}

fn fail(sys: *r4os.r4sys.Context, label: []const u8) i32 {
    sys.write("SERVMAN FAILED: ");
    sys.println(label);
    return 1;
}

fn failCode(sys: *r4os.r4sys.Context, label: []const u8, code: i32) i32 {
    sys.write("SERVMAN FAILED: ");
    sys.write(label);
    sys.write(" code=");
    sys.printI32(code);
    sys.println("");
    return 1;
}

fn writeUnsigned(sys: *r4os.r4sys.Context, value: u64) void {
    var tmp: [32]u8 = undefined;
    var n = value;
    var pos: usize = tmp.len;
    if (n == 0) {
        pos -= 1;
        tmp[pos] = '0';
    } else {
        while (n > 0 and pos > 0) {
            pos -= 1;
            tmp[pos] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
        }
    }
    sys.write(tmp[pos..]);
}

fn takeToken(s_raw: []const u8) ?Token {
    const s = trim(s_raw);
    if (s.len == 0) return null;
    var end: usize = 0;
    while (end < s.len and s[end] != ' ' and s[end] != '\t') : (end += 1) {}
    return .{ .token = s[0..end], .rest = trim(s[end..]) };
}

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end = s.len;
    while (start < end and (s[start] == ' ' or s[start] == '\t' or s[start] == '\r' or s[start] == '\n')) : (start += 1) {}
    while (end > start and (s[end - 1] == ' ' or s[end - 1] == '\t' or s[end - 1] == '\r' or s[end - 1] == '\n')) : (end -= 1) {}
    return s[start..end];
}

fn zSlice(ptr: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return ptr[0..len];
}

fn spanZ(buffer: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buffer.len and buffer[len] != 0) : (len += 1) {}
    return buffer[0..len];
}

fn makeZ(out: []u8, value: []const u8) ?[*:0]const u8 {
    if (out.len == 0 or value.len >= out.len) return null;
    @memset(out, 0);
    if (value.len > 0) @memcpy(out[0..value.len], value);
    return @ptrCast(out.ptr);
}

fn setZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const len = @min(out.len - 1, value.len);
    if (len > 0) @memcpy(out[0..len], value[0..len]);
}

fn copyZChecked(out: []u8, value: []const u8) bool {
    if (out.len == 0 or value.len >= out.len) return false;
    @memset(out, 0);
    if (value.len > 0) @memcpy(out[0..value.len], value);
    return true;
}

fn append(out: []u8, pos: *usize, value: []const u8) bool {
    if (pos.* + value.len > out.len) return false;
    if (value.len > 0) @memcpy(out[pos.* .. pos.* + value.len], value);
    pos.* += value.len;
    return true;
}

fn tokenEquals(a: []const u8, b: []const u8) bool {
    return sameBytesIgnoreCase(trimPrefix(a), trimPrefix(b));
}

fn trimPrefix(s: []const u8) []const u8 {
    if (s.len > 0 and (s[0] == '/' or s[0] == '-')) return s[1..];
    return s;
}

fn startsWithIgnoreCase(s: []const u8, prefix: []const u8) bool {
    return s.len >= prefix.len and sameBytesIgnoreCase(s[0..prefix.len], prefix);
}

fn sameBytesIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (upper(a[i]) != upper(b[i])) return false;
    }
    return true;
}

fn stripBom(data: []const u8) []const u8 {
    if (data.len >= 3 and data[0] == 0xEF and data[1] == 0xBB and data[2] == 0xBF) return data[3..];
    return data;
}

fn indexOf(s: []const u8, ch: u8) ?usize {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] == ch) return i;
    }
    return null;
}

fn upper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}
