const r4os = @import("r4os");
const std = @import("std");

const Aes128Gcm = std.crypto.aead.aes_gcm.Aes128Gcm;
const HmacSha256 = std.crypto.auth.hmac.sha2.HmacSha256;
const Sha256 = std.crypto.hash.sha2.Sha256;
const Sha384 = std.crypto.hash.sha2.Sha384;
const X25519 = std.crypto.dh.X25519;
const P256 = std.crypto.ecc.P256;
const P384 = std.crypto.ecc.P384;
const Certificate = std.crypto.Certificate;

pub const op_capabilities: u32 = 1;
pub const op_classify_record: u32 = 2;
pub const op_selftest: u32 = 3;
pub const op_parse_client_hello: u32 = 4;
pub const op_plan_server_handshake: u32 = 5;
pub const op_build_server_handshake_fixture: u32 = 6;
pub const op_stream_contract: u32 = 7;
pub const op_stream_write_record: u32 = 8;
pub const op_stream_read_record: u32 = 9;
pub const op_stream_alert_record: u32 = 10;
pub const op_stream_transport_status: u32 = 11;
pub const op_productive_contract: u32 = 12;
pub const op_tls12_key_schedule: u32 = 13;
pub const op_tls12_protect_record: u32 = 14;
pub const op_tls12_open_record: u32 = 15;
pub const op_tls12_x25519: u32 = 16;
pub const op_negative_wire_contract: u32 = 17;
pub const op_tls12_rsa_key_contract: u32 = 18;
pub const op_tls12_sign_server_key_exchange: u32 = 19;
pub const op_tls12_session_contract: u32 = 20;
pub const op_tls12_session_harness: u32 = 21;
pub const op_tls12_live_begin: u32 = 22;
pub const op_tls12_live_finish: u32 = 23;
pub const op_tls12_app_write: u32 = 24;
pub const op_tls12_app_read: u32 = 25;
pub const op_tls12_client_contract: u32 = 26;
pub const op_tls12_client_begin: u32 = 27;
pub const op_tls12_client_server_flight: u32 = 28;
pub const op_tls12_client_finish: u32 = 29;
pub const op_tls12_client_app_write: u32 = 30;
pub const op_tls12_client_app_read: u32 = 31;
pub const op_tls12_client_harness: u32 = 32;
pub const op_tls12_server_binding_key: u32 = 33;

const tls_record_header_len: usize = 5;
const tls_max_fragment_len: usize = 16 * 1024;
const tls_server_handshake_fixture_min_capacity: usize = 4096;
const tls_stream_fixture_tag_len: usize = 16;
const tls_aes_gcm_explicit_nonce_len: usize = 8;
const tls_aes_gcm_tag_len: usize = 16;
const tls_aes_gcm_fixed_iv_len: usize = 4;
const tls_max_record_fragment_len: usize = tls_max_fragment_len + tls_aes_gcm_explicit_nonce_len + tls_aes_gcm_tag_len;
const tls_aes_128_key_len: usize = 16;
const tls_pre_master_len: usize = 32;
const tls_random_len: usize = 32;
const tls_master_secret_len: usize = 48;
const tls12_key_schedule_in_len: usize = 4 + tls_pre_master_len + tls_random_len + tls_random_len;
const tls12_key_schedule_out_len: usize = 4 + tls_master_secret_len + tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len + tls_aes_gcm_fixed_iv_len;
const tls12_key_schedule_master_offset: usize = 4;
const tls12_key_schedule_client_key_offset: usize = tls12_key_schedule_master_offset + tls_master_secret_len;
const tls12_key_schedule_server_key_offset: usize = tls12_key_schedule_client_key_offset + tls_aes_128_key_len;
const tls12_key_schedule_client_iv_offset: usize = tls12_key_schedule_server_key_offset + tls_aes_128_key_len;
const tls12_key_schedule_server_iv_offset: usize = tls12_key_schedule_client_iv_offset + tls_aes_gcm_fixed_iv_len;
const tls12_record_protect_header_len: usize = 4 + 8 + 1 + tls_aes_gcm_fixed_iv_len + tls_aes_128_key_len;
const tls12_record_open_header_len: usize = 4 + 8 + tls_aes_gcm_fixed_iv_len + tls_aes_128_key_len;
const tls12_x25519_in_len: usize = 4 + X25519.secret_length + X25519.public_length;
const tls12_x25519_out_len: usize = 4 + X25519.public_length + X25519.shared_length;
const tls12_rsa_sign_header_len: usize = 4;
const tls12_rsa_sign_out_header_len: usize = 8;
const tls12_finished_verify_len: usize = 12;
const tls12_finished_message_len: usize = 4 + tls12_finished_verify_len;
const tls12_ccs_record_len: usize = tls_record_header_len + 1;
const tls_content_change_cipher_spec: u8 = 20;
const tls_content_alert: u8 = 21;
const tls_content_handshake: u8 = 22;
const tls_content_application_data: u8 = 23;
const tls_handshake_client_hello: u8 = 1;
const tls_handshake_server_hello: u8 = 2;
const tls_handshake_new_session_ticket: u8 = 4;
const tls_handshake_certificate: u8 = 11;
const tls_handshake_server_key_exchange: u8 = 12;
const tls_handshake_server_hello_done: u8 = 14;
const tls_handshake_client_key_exchange: u8 = 16;
const tls_handshake_finished: u8 = 20;
const tls_version_major: u8 = 3;
const tls_version_tls12_minor: u8 = 3;
const tls_version_tls13_minor: u8 = 4;
const tls_cipher_tls13_aes_128_gcm_sha256: u16 = 0x1301;
const tls_cipher_ecdhe_ecdsa_aes_128_gcm_sha256: u16 = 0xC02B;
const tls_cipher_ecdhe_rsa_aes_128_gcm_sha256: u16 = 0xC02F;
const tls_named_group_x25519: u16 = 29;
const tls_named_group_secp256r1: u16 = 23;
const tls_ec_public_max_len: usize = 65;
const tls_signature_rsa_pss_rsae_sha256: u16 = 0x0804;
const tls_signature_ecdsa_secp384r1_sha384: u16 = 0x0503;
const tls_signature_ecdsa_secp256r1_sha256: u16 = 0x0403;
const tls_signature_rsa_pkcs1_sha256: u16 = 0x0401;
const rsa_max_modulus_bits: usize = 2048;
const rsa_max_modulus_bytes: usize = rsa_max_modulus_bits / 8;
const rsa_min_modulus_bytes: usize = 64;
const rsa_sha256_digest_info_len: usize = 19 + Sha256.digest_length;
const tls_cert_max_der_bytes: usize = 2048;
const tls_peer_cert_max_der_bytes: usize = 4096;
const tls_cert_chain_max_count: usize = 4;
const tls_root_max_count: usize = 8;
const ext_server_name: u16 = 0;
const ext_supported_groups: u16 = 10;
const ext_ec_point_formats: u16 = 11;
const ext_signature_algorithms: u16 = 13;
const ext_alpn: u16 = 16;
const ext_extended_master_secret: u16 = 23;
const ext_session_ticket: u16 = 35;
const ext_supported_versions: u16 = 43;
const ext_key_share: u16 = 51;
const ext_renegotiation_info: u16 = 0xff01;
const dev_cert_path = "C:\\R4OS\\CONFIG\\TLS\\R4TLSDEV.CRT";
const dev_key_path = "C:\\R4OS\\CONFIG\\TLS\\R4TLSDEV.KEY";
const root_catalog_path = "C:\\R4OS\\CERTS\\CATALOG.R4S";
const root_cert_path = "C:\\R4OS\\CERTS\\ROOTS\\R4OSDEV.CRT";
const dev_certificate_fixture = "R4OS-DEV-TLS-CERT-FIXTURE-05518";
const stream_fixture_tag_seed = "R4TLS05519STREAM";
const fixture_x25519_secret = [_]u8{ 0xa5, 0x46, 0xe3, 0x6b, 0xf0, 0x52, 0x7c, 0x9d, 0x3b, 0x16, 0x15, 0x4b, 0x82, 0x46, 0x5e, 0xdd, 0x62, 0x14, 0x4c, 0x0a, 0xc1, 0xfc, 0x5a, 0x18, 0x50, 0x6a, 0x22, 0x44, 0xba, 0x44, 0x9a, 0xc4 };
const fixture_x25519_public = [_]u8{ 0xe6, 0xdb, 0x68, 0x67, 0x58, 0x30, 0x30, 0xdb, 0x35, 0x94, 0xc1, 0xa4, 0x24, 0xb1, 0x5f, 0x7c, 0x72, 0x66, 0x24, 0xec, 0x26, 0xb3, 0x35, 0x3b, 0x10, 0xa9, 0x03, 0xa6, 0xd0, 0xab, 0x1c, 0x4c };
const fixture_server_secret = [_]u8{ 0x53, 0x22, 0x91, 0x8d, 0x34, 0xf1, 0xa8, 0xc7, 0x0b, 0x66, 0x3c, 0x14, 0xd2, 0x81, 0x5a, 0x9f, 0xe0, 0x42, 0x7b, 0x21, 0x6c, 0xba, 0x5d, 0x33, 0x18, 0xa4, 0x7e, 0xc1, 0x90, 0x0f, 0xb6, 0x2d };
const magic_key_schedule_in = "R4K1";
const magic_key_schedule_out = "R4KR";
const magic_record_protect_in = "R4RP";
const magic_record_open_in = "R4RO";
const magic_x25519_in = "R4X2";
const magic_x25519_out = "R4XR";
const magic_rsa_sign_in = "R4SG";
const magic_rsa_sign_out = "R4SR";
const magic_tls12_live_begin_out = "R4LB";
const magic_tls12_live_finish_out = "R4LF";
const magic_tls12_live_state = "R4L2";
const magic_tls12_live_stream = "R4LK";
const magic_tls12_app_write_in = "R4AW";
const magic_tls12_app_write_out = "R4WX";
const magic_tls12_app_read_in = "R4AR";
const magic_tls12_app_read_out = "R4RX";
const magic_tls12_client_begin_in = "R4CB";
const magic_tls12_client_begin_out = "R4CH";
const magic_tls12_client_state = "R4CS";
const magic_tls12_client_flight_in = "R4CF";
const magic_tls12_client_flight_out = "R4CQ";
const magic_tls12_client_finish_in = "R4CE";
const magic_tls12_client_finish_out = "R4CT";
const magic_tls12_client_app_write_in = "R4CW";
const magic_tls12_client_app_write_out = "R4CX";
const magic_tls12_client_app_read_in = "R4CR";
const magic_tls12_client_app_read_out = "R4CY";
const rsa_modulus_field = "MODULUS_HEX";
const rsa_public_exponent_field = "PUBLIC_EXPONENT_HEX";
const rsa_private_exponent_field = "PRIVATE_EXPONENT_HEX";
const cert_der_field = "CERT_DER_HEX";
const signature_scheme_name = "RSA_PKCS1_SHA256";
const RsaModulus = std.crypto.ff.Modulus(rsa_max_modulus_bits);
const tls12_live_header_len: usize = 12;
const tls12_live_state_header_len: usize = 4 + 4 + tls_random_len + tls_random_len + X25519.secret_length;
const tls12_live_stream_state_len: usize = 4 + 8 + 8 + tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len + tls_aes_gcm_fixed_iv_len + tls_master_secret_len + Sha256.digest_length;
const tls12_live_stream_client_seq_offset: usize = 4;
const tls12_live_stream_server_seq_offset: usize = tls12_live_stream_client_seq_offset + 8;
const tls12_live_stream_client_key_offset: usize = tls12_live_stream_server_seq_offset + 8;
const tls12_live_stream_server_key_offset: usize = tls12_live_stream_client_key_offset + tls_aes_128_key_len;
const tls12_live_stream_client_iv_offset: usize = tls12_live_stream_server_key_offset + tls_aes_128_key_len;
const tls12_live_stream_server_iv_offset: usize = tls12_live_stream_client_iv_offset + tls_aes_gcm_fixed_iv_len;
const tls12_live_stream_master_offset: usize = tls12_live_stream_server_iv_offset + tls_aes_gcm_fixed_iv_len;
const tls12_live_stream_cert_hash_offset: usize = tls12_live_stream_master_offset + tls_master_secret_len;
const tls12_app_io_header_len: usize = 4 + tls12_live_stream_state_len;
const tls12_live_max_transcript_len: usize = 8192;
const tls12_client_begin_header_len: usize = 4 + tls_pre_master_len + 8 + 2;
const tls12_client_result_header_len: usize = 12;
const tls12_client_state_header_len: usize = 4 + 8 + 2 + tls_pre_master_len + tls_random_len + 4;
const tls12_client_ready_header_len: usize = 4 + tls12_live_stream_state_len + 4;
const tls12_client_max_hostname_len: usize = 253;

pub const stream_result_ok: i32 = 0;
pub const stream_result_would_block: i32 = 1;
pub const stream_result_backpressure: i32 = 2;
pub const stream_result_disconnect: i32 = 3;
pub const stream_result_alert: i32 = 4;
pub const stream_result_bad_buffer: i32 = -2;
pub const stream_result_buffer_small: i32 = -5;
pub const stream_result_malformed_record: i32 = -6;
pub const stream_result_unsupported_record: i32 = -7;
pub const stream_result_integrity_failed: i32 = -8;
pub const stream_result_material_missing: i32 = -9;
pub const stream_result_material_invalid: i32 = -10;
pub const stream_result_entropy_unavailable: i32 = -11;

var system_cert_bytes: u32 = 0;
var system_key_bytes: u32 = 0;
var system_cert_loaded: bool = false;
var system_key_loaded: bool = false;
var system_cert_der: [tls_cert_max_der_bytes]u8 = .{0} ** tls_cert_max_der_bytes;
var system_cert_der_len: usize = 0;
var system_root_cert_der: [tls_root_max_count][tls_cert_max_der_bytes]u8 = .{.{0} ** tls_cert_max_der_bytes} ** tls_root_max_count;
var system_root_cert_der_len: [tls_root_max_count]usize = .{0} ** tls_root_max_count;
var system_root_count: usize = 0;
var system_root_loaded: bool = false;
var system_root_status: TlsMaterialStatus = .missing;
var system_key_context = RsaKeyContext.empty();
var system_cert_status: TlsMaterialStatus = .missing;
var system_key_status: TlsMaterialStatus = .missing;
var protocol_api: ?*const r4os.r4dev.ProtocolApi2 = null;

const TlsMaterialStatus = enum(u8) {
    missing,
    ok,
    bad_pem,
    missing_field,
    bad_hex,
    field_too_large,
    bad_type,
    unsupported_scheme,
    key_too_small,
    cert_too_large,
    cert_der_invalid,
    key_mismatch,
    sign_failed,
};

const TlsMaterialError = error{
    BadPem,
    MissingField,
    BadHex,
    FieldTooLarge,
    BadType,
    UnsupportedScheme,
    KeyTooSmall,
    CertTooLarge,
    CertDerInvalid,
    KeyMismatch,
    SignFailed,
};

const RsaKeyContext = struct {
    modulus: [rsa_max_modulus_bytes]u8,
    public_exponent: [4]u8,
    private_exponent: [rsa_max_modulus_bytes]u8,
    modulus_len: usize,
    public_exponent_len: usize,
    private_exponent_len: usize,
    valid: bool,

    fn empty() RsaKeyContext {
        return .{
            .modulus = .{0} ** rsa_max_modulus_bytes,
            .public_exponent = .{0} ** 4,
            .private_exponent = .{0} ** rsa_max_modulus_bytes,
            .modulus_len = 0,
            .public_exponent_len = 0,
            .private_exponent_len = 0,
            .valid = false,
        };
    }

    fn fromPublicKey(modulus: []const u8, exponent: []const u8) ?RsaKeyContext {
        if (modulus.len < rsa_min_modulus_bytes or modulus.len > rsa_max_modulus_bytes or exponent.len == 0 or exponent.len > 4) return null;
        var key = empty();
        @memcpy(key.modulus[0..modulus.len], modulus);
        @memcpy(key.public_exponent[0..exponent.len], exponent);
        key.modulus_len = modulus.len;
        key.public_exponent_len = exponent.len;
        key.valid = true;
        return key;
    }
};

const RsaCertContext = struct {
    der: [tls_cert_max_der_bytes]u8,
    modulus: [rsa_max_modulus_bytes]u8,
    public_exponent: [4]u8,
    der_len: usize,
    modulus_len: usize,
    public_exponent_len: usize,

    fn empty() RsaCertContext {
        return .{
            .der = .{0} ** tls_cert_max_der_bytes,
            .modulus = .{0} ** rsa_max_modulus_bytes,
            .public_exponent = .{0} ** 4,
            .der_len = 0,
            .modulus_len = 0,
            .public_exponent_len = 0,
        };
    }
};

const TlsMaterialView = struct {
    cert_der: []const u8,
    key: *const RsaKeyContext,
};

const Tls12SessionKeys = struct {
    master: [tls_master_secret_len]u8,
    client_key: [tls_aes_128_key_len]u8,
    server_key: [tls_aes_128_key_len]u8,
    client_iv: [tls_aes_gcm_fixed_iv_len]u8,
    server_iv: [tls_aes_gcm_fixed_iv_len]u8,
};

const Tls12SessionHarnessResult = struct {
    client_hello_len: usize,
    server_handshake_len: usize,
    client_key_exchange_len: usize,
    client_finished_record_len: usize,
    server_finished_record_len: usize,
    transcript_len: usize,
    client_seq_next: u64,
    server_seq_next: u64,
    shared_secret: [tls_pre_master_len]u8,
    client_verify: [tls12_finished_verify_len]u8,
    server_verify: [tls12_finished_verify_len]u8,
};

const Tls12LiveStateView = struct {
    total_len: usize,
    transcript: []const u8,
    client_random: [tls_random_len]u8,
    server_random: [tls_random_len]u8,
    server_secret: [X25519.secret_length]u8,
};

const Tls12LiveStreamView = struct {
    client_sequence: u64,
    server_sequence: u64,
    client_key: []const u8,
    server_key: []const u8,
    client_iv: []const u8,
    server_iv: []const u8,
    master: []const u8,
    cert_hash: []const u8,
};

const Tls12ClientStateView = struct {
    total_len: usize,
    now_utc: u64,
    hostname: []const u8,
    secret: [tls_pre_master_len]u8,
    client_random: [tls_random_len]u8,
    transcript: []const u8,
};

const Tls12ClientReadyView = struct {
    total_len: usize,
    stream_state: []const u8,
    transcript: []const u8,
};

const X509CertificateView = struct {
    tbs: []const u8,
    signature: []const u8,
    issuer: []const u8,
    subject: []const u8,
    not_before: u64,
    not_after: u64,
    common_name: []const u8,
    san_names: []const u8,
    public_key: RsaCertContext,
};

const DerElement = struct {
    tag: u8,
    full: []const u8,
    value: []const u8,
};

const Tls12ServerFlightView = struct {
    fragment: []const u8,
    server_random: [tls_random_len]u8,
    extended_master_secret: bool,
    secure_renegotiation: bool,
    certificate: []const u8,
    certificates: [tls_cert_chain_max_count][]const u8,
    certificate_count: usize,
    named_group: u16,
    server_public: [tls_ec_public_max_len]u8,
    server_public_len: usize,
    signed_params: []const u8,
    signature_scheme: u16,
    signature: []const u8,
};

const Tls12ServerFlightError = error{
    RecordHeaderInvalid,
    MessageFramingInvalid,
    ServerHelloInvalid,
    CertificateListInvalid,
    ServerKeyExchangeInvalid,
    ServerHelloDoneInvalid,
    UnexpectedMessage,
    IncompleteFlight,
};

comptime {
    if (!@import("builtin").is_test) asm (r4os.technical2.protocolEntriesAsm("r4tls_init", "r4tls_shutdown", "r4tls_query", "r4tls_dispatch"));
}

export fn r4tls_init(api: *const r4os.r4dev.ProtocolApi2) callconv(.c) i32 {
    var ctx = r4os.r4dev.ProtocolContext2.init(api);
    if (!ctx.requires(.{ "register_role", "set_status" })) return -3;
    protocol_api = api;
    ctx.bindEntropy();
    ctx.logInfo("R4TLS.R4P init");
    if (ctx.registerRole("security.tls", .data, 0) != 0) return -4;
    loadSystemTlsFiles(&ctx);
    if (ctx.setStatus(.active, if (system_cert_loaded and system_key_loaded) "R4TLS TLS core active, system TLS files loaded" else "R4TLS TLS core active, system TLS files incomplete") != 0) return -5;
    return 0;
}

export fn r4tls_shutdown() callconv(.c) i32 {
    r4os.secure_random.Provider.bind(.{});
    protocol_api = null;
    return 0;
}

export fn r4tls_query(out: *r4os.abi.ProtocolStatus) callconv(.c) i32 {
    out.* = .{
        .state = @intFromEnum(r4os.abi.ProtocolState.active),
        .flags = 0,
        .last_error = 0,
        .reserved = 0,
        .note = note("R4TLS ready"),
    };
    return 0;
}

export fn r4tls_dispatch(op: u32, in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) callconv(.c) i32 {
    out_buffer.len = 0;
    return switch (op) {
        op_capabilities => writeOut(out_buffer, "role=security.tls;stage=tls12-client-server-app-stream;tls12=parse+plan+client+server+app-records+prf+x25519+p256+aes128gcm-records+rsa-pkcs1-sha256+ecdsa-p256-p384-sha256-sha384+x509;roots=external;tls13=boundary"),
        op_classify_record => classifyRecord(in_buffer, out_buffer),
        op_selftest => selftest(out_buffer),
        op_parse_client_hello => parseClientHello(in_buffer, out_buffer),
        op_plan_server_handshake => planServerHandshake(in_buffer, out_buffer),
        op_build_server_handshake_fixture => buildServerHandshakeFixture(in_buffer, out_buffer),
        op_stream_contract => describeStreamContract(in_buffer, out_buffer),
        op_stream_write_record => streamWriteRecord(in_buffer, out_buffer),
        op_stream_read_record => streamReadRecord(in_buffer, out_buffer),
        op_stream_alert_record => streamAlertRecord(in_buffer, out_buffer),
        op_stream_transport_status => describeTransportStatus(in_buffer, out_buffer),
        op_productive_contract => describeProductiveContract(in_buffer, out_buffer),
        op_tls12_key_schedule => tls12KeyScheduleDispatch(in_buffer, out_buffer),
        op_tls12_protect_record => tls12ProtectRecordDispatch(in_buffer, out_buffer),
        op_tls12_open_record => tls12OpenRecordDispatch(in_buffer, out_buffer),
        op_tls12_x25519 => tls12X25519Dispatch(in_buffer, out_buffer),
        op_negative_wire_contract => describeNegativeWireContract(in_buffer, out_buffer),
        op_tls12_rsa_key_contract => describeRsaKeyContract(in_buffer, out_buffer),
        op_tls12_sign_server_key_exchange => tls12SignServerKeyExchangeDispatch(in_buffer, out_buffer),
        op_tls12_session_contract => describeTls12SessionContract(in_buffer, out_buffer),
        op_tls12_session_harness => tls12SessionHarnessDispatch(in_buffer, out_buffer),
        op_tls12_live_begin => tls12LiveBeginDispatch(in_buffer, out_buffer),
        op_tls12_live_finish => tls12LiveFinishDispatch(in_buffer, out_buffer),
        op_tls12_app_write => tls12AppWriteDispatch(in_buffer, out_buffer),
        op_tls12_app_read => tls12AppReadDispatch(in_buffer, out_buffer),
        op_tls12_client_contract => describeTls12ClientContract(in_buffer, out_buffer),
        op_tls12_client_begin => tls12ClientBeginDispatch(in_buffer, out_buffer),
        op_tls12_client_server_flight => tls12ClientServerFlightDispatch(in_buffer, out_buffer),
        op_tls12_client_finish => tls12ClientFinishDispatch(in_buffer, out_buffer),
        op_tls12_client_app_write => tls12ClientAppWriteDispatch(in_buffer, out_buffer),
        op_tls12_client_app_read => tls12ClientAppReadDispatch(in_buffer, out_buffer),
        op_tls12_client_harness => tls12ClientHarnessDispatch(in_buffer, out_buffer),
        op_tls12_server_binding_key => tls12ServerBindingKeyDispatch(in_buffer, out_buffer),
        else => -4,
    };
}

fn classifyRecord(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return -2;
    const record = recordHeader(input) orelse return -6;

    var text: [96]u8 = .{0} ** 96;
    var pos: usize = 0;
    appendText(text[0..], &pos, "tls-record;type=");
    appendU64(text[0..], &pos, record.content_type);
    appendText(text[0..], &pos, ";version=");
    appendU64(text[0..], &pos, record.major);
    appendText(text[0..], &pos, ".");
    appendU64(text[0..], &pos, record.minor);
    appendText(text[0..], &pos, ";length=");
    appendU64(text[0..], &pos, record.fragment_len);
    appendText(text[0..], &pos, ";complete=");
    appendText(text[0..], &pos, if (input.len >= tls_record_header_len + record.fragment_len) "yes" else "no");
    appendText(text[0..], &pos, ";kind=");
    appendText(text[0..], &pos, recordKind(record.content_type));
    if (record.content_type == tls_content_handshake and record.minor == tls_version_tls12_minor) appendText(text[0..], &pos, ";hint=tls12-handshake");
    return writeOut(out_buffer, text[0..pos]);
}

const TlsRecordHeader = struct {
    content_type: u8,
    major: u8,
    minor: u8,
    fragment_len: usize,
};

const ClientHelloInfo = struct {
    record_major: u8 = 0,
    record_minor: u8 = 0,
    legacy_major: u8 = 0,
    legacy_minor: u8 = 0,
    handshake_len: usize = 0,
    cipher_suites: u16 = 0,
    compression_methods: u8 = 0,
    extensions: u16 = 0,
    has_server_name: bool = false,
    has_supported_versions: bool = false,
    has_supported_groups: bool = false,
    has_signature_algorithms: bool = false,
    has_key_share: bool = false,
    has_alpn: bool = false,
    has_secure_renegotiation: bool = false,
    has_tls12_version: bool = false,
    has_tls13_version: bool = false,
    has_cipher_tls13_aes128_gcm_sha256: bool = false,
    has_cipher_ecdhe_rsa_aes128_gcm_sha256: bool = false,
    has_group_x25519: bool = false,
    has_signature_rsa_pss_sha256: bool = false,
    has_signature_rsa_pkcs1_sha256: bool = false,
    has_key_share_x25519: bool = false,
    client_random: [tls_random_len]u8 = .{0} ** tls_random_len,
    key_share_x25519: [X25519.public_length]u8 = .{0} ** X25519.public_length,
};

const ServerHandshakePlan = struct {
    selected_major: u8 = tls_version_major,
    selected_minor: u8 = tls_version_tls12_minor,
    selected_cipher: u16 = tls_cipher_ecdhe_rsa_aes_128_gcm_sha256,
    certificate_len: u16 = dev_certificate_fixture.len,
    requires_server_key_exchange: bool = true,
    tls13_seen: bool = false,
    stream_ready: bool = false,
    secure_renegotiation: bool = false,
    selected_signature: u16 = tls_signature_rsa_pkcs1_sha256,
    client_random: [tls_random_len]u8 = .{0} ** tls_random_len,
    server_random: [tls_random_len]u8 = .{0} ** tls_random_len,
    server_secret: [X25519.secret_length]u8 = .{0} ** X25519.secret_length,
};

fn recordHeader(input: []const u8) ?TlsRecordHeader {
    if (input.len < tls_record_header_len) return null;
    const fragment_len = (@as(usize, input[3]) << 8) | input[4];
    if (input[1] != tls_version_major or fragment_len > tls_max_record_fragment_len) return null;
    return .{
        .content_type = input[0],
        .major = input[1],
        .minor = input[2],
        .fragment_len = fragment_len,
    };
}

fn parseClientHello(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return -2;
    const info = parseClientHelloInfo(input) orelse return -6;
    var text: [256]u8 = .{0} ** 256;
    var pos: usize = 0;
    appendText(text[0..], &pos, "clienthello;record=");
    appendU64(text[0..], &pos, info.record_major);
    appendText(text[0..], &pos, ".");
    appendU64(text[0..], &pos, info.record_minor);
    appendText(text[0..], &pos, ";legacy=");
    appendU64(text[0..], &pos, info.legacy_major);
    appendText(text[0..], &pos, ".");
    appendU64(text[0..], &pos, info.legacy_minor);
    appendText(text[0..], &pos, ";hlen=");
    appendU64(text[0..], &pos, info.handshake_len);
    appendText(text[0..], &pos, ";ciphers=");
    appendU64(text[0..], &pos, info.cipher_suites);
    appendText(text[0..], &pos, ";comp=");
    appendU64(text[0..], &pos, info.compression_methods);
    appendText(text[0..], &pos, ";ext=");
    appendU64(text[0..], &pos, info.extensions);
    appendText(text[0..], &pos, ";sni=");
    appendText(text[0..], &pos, boolText(info.has_server_name));
    appendText(text[0..], &pos, ";alpn=");
    appendText(text[0..], &pos, boolText(info.has_alpn));
    appendText(text[0..], &pos, ";vers=");
    appendText(text[0..], &pos, boolText(info.has_supported_versions));
    appendText(text[0..], &pos, ";groups=");
    appendText(text[0..], &pos, boolText(info.has_supported_groups));
    appendText(text[0..], &pos, ";sig=");
    appendText(text[0..], &pos, boolText(info.has_signature_algorithms));
    appendText(text[0..], &pos, ";keyshare=");
    appendText(text[0..], &pos, boolText(info.has_key_share));
    appendText(text[0..], &pos, ";x25519_key=");
    appendText(text[0..], &pos, boolText(info.has_key_share_x25519));
    appendText(text[0..], &pos, ";tls12=");
    appendText(text[0..], &pos, boolText(info.has_tls12_version));
    appendText(text[0..], &pos, ";tls13=");
    appendText(text[0..], &pos, boolText(info.has_tls13_version));
    appendText(text[0..], &pos, ";c02f=");
    appendText(text[0..], &pos, boolText(info.has_cipher_ecdhe_rsa_aes128_gcm_sha256));
    appendText(text[0..], &pos, ";rsa_pkcs1=");
    appendText(text[0..], &pos, boolText(info.has_signature_rsa_pkcs1_sha256));
    return writeOut(out_buffer, text[0..pos]);
}

fn parseClientHelloInfo(input: []const u8) ?ClientHelloInfo {
    const record = recordHeader(input) orelse return null;
    if (record.content_type != tls_content_handshake) return null;
    const record_end = tls_record_header_len + record.fragment_len;
    if (input.len < record_end) return null;
    const fragment = input[tls_record_header_len..record_end];
    if (fragment.len < 4 or fragment[0] != tls_handshake_client_hello) return null;
    const handshake_len = readBe24(fragment[1..4]);
    if (handshake_len + 4 > fragment.len) return null;
    const body = fragment[4 .. 4 + handshake_len];
    if (body.len < 35) return null;

    var info = ClientHelloInfo{
        .record_major = record.major,
        .record_minor = record.minor,
        .legacy_major = body[0],
        .legacy_minor = body[1],
        .handshake_len = handshake_len,
    };
    @memcpy(info.client_random[0..], body[2..34]);
    var pos: usize = 34;
    const session_id_len: usize = body[pos];
    pos += 1;
    if (pos + session_id_len > body.len) return null;
    pos += session_id_len;

    if (pos + 2 > body.len) return null;
    const cipher_bytes = readBe16(body[pos .. pos + 2]);
    pos += 2;
    if (cipher_bytes == 0 or (cipher_bytes & 1) != 0 or pos + cipher_bytes > body.len) return null;
    info.cipher_suites = @intCast(cipher_bytes / 2);
    var cipher_pos = pos;
    while (cipher_pos < pos + cipher_bytes) : (cipher_pos += 2) {
        const cipher = readBe16(body[cipher_pos .. cipher_pos + 2]);
        switch (cipher) {
            tls_cipher_tls13_aes_128_gcm_sha256 => info.has_cipher_tls13_aes128_gcm_sha256 = true,
            tls_cipher_ecdhe_rsa_aes_128_gcm_sha256 => info.has_cipher_ecdhe_rsa_aes128_gcm_sha256 = true,
            else => {},
        }
    }
    pos += cipher_bytes;

    if (pos >= body.len) return null;
    const compression_len: usize = body[pos];
    pos += 1;
    if (compression_len == 0 or pos + compression_len > body.len) return null;
    info.compression_methods = @intCast(compression_len);
    pos += compression_len;

    if (pos == body.len) {
        if (info.legacy_major == tls_version_major and info.legacy_minor == tls_version_tls12_minor) info.has_tls12_version = true;
        return info;
    }
    if (pos + 2 > body.len) return null;
    const extensions_len = readBe16(body[pos .. pos + 2]);
    pos += 2;
    if (pos + extensions_len != body.len) return null;
    const extensions_end = pos + extensions_len;
    while (pos < extensions_end) {
        if (pos + 4 > extensions_end) return null;
        const ext_type = readBe16(body[pos .. pos + 2]);
        const ext_len = readBe16(body[pos + 2 .. pos + 4]);
        pos += 4;
        if (pos + ext_len > extensions_end) return null;
        info.extensions += 1;
        const ext_data = body[pos .. pos + ext_len];
        switch (ext_type) {
            ext_server_name => info.has_server_name = true,
            ext_supported_versions => {
                info.has_supported_versions = true;
                if (!parseSupportedVersions(ext_data, &info)) return null;
            },
            ext_supported_groups => {
                info.has_supported_groups = true;
                if (!parseSupportedGroups(ext_data, &info)) return null;
            },
            ext_signature_algorithms => {
                info.has_signature_algorithms = true;
                if (!parseSignatureAlgorithms(ext_data, &info)) return null;
            },
            ext_key_share => {
                info.has_key_share = true;
                if (!parseKeyShare(ext_data, &info)) return null;
            },
            ext_alpn => info.has_alpn = true,
            ext_renegotiation_info => {
                if (info.has_secure_renegotiation or ext_data.len != 1 or ext_data[0] != 0) return null;
                info.has_secure_renegotiation = true;
            },
            else => {},
        }
        pos += ext_len;
    }
    if (!info.has_supported_versions and info.legacy_major == tls_version_major and info.legacy_minor == tls_version_tls12_minor) {
        info.has_tls12_version = true;
    }
    return info;
}

fn parseSupportedVersions(data: []const u8, info: *ClientHelloInfo) bool {
    if (data.len < 1) return false;
    const len: usize = data[0];
    if (len == 0 or (len & 1) != 0 or len + 1 != data.len) return false;
    var pos: usize = 1;
    while (pos < data.len) : (pos += 2) {
        if (data[pos] != tls_version_major) continue;
        switch (data[pos + 1]) {
            tls_version_tls12_minor => info.has_tls12_version = true,
            tls_version_tls13_minor => info.has_tls13_version = true,
            else => {},
        }
    }
    return true;
}

fn parseSupportedGroups(data: []const u8, info: *ClientHelloInfo) bool {
    if (data.len < 2) return false;
    const len = readBe16(data[0..2]);
    if (len == 0 or (len & 1) != 0 or len + 2 != data.len) return false;
    var pos: usize = 2;
    while (pos < data.len) : (pos += 2) {
        if (readBe16(data[pos .. pos + 2]) == tls_named_group_x25519) info.has_group_x25519 = true;
    }
    return true;
}

fn parseSignatureAlgorithms(data: []const u8, info: *ClientHelloInfo) bool {
    if (data.len < 2) return false;
    const len = readBe16(data[0..2]);
    if (len == 0 or (len & 1) != 0 or len + 2 != data.len) return false;
    var pos: usize = 2;
    while (pos < data.len) : (pos += 2) {
        switch (readBe16(data[pos .. pos + 2])) {
            tls_signature_rsa_pss_rsae_sha256 => info.has_signature_rsa_pss_sha256 = true,
            tls_signature_rsa_pkcs1_sha256 => info.has_signature_rsa_pkcs1_sha256 = true,
            else => {},
        }
    }
    return true;
}

fn parseKeyShare(data: []const u8, info: *ClientHelloInfo) bool {
    if (data.len < 2) return false;
    const len = readBe16(data[0..2]);
    if (len + 2 != data.len) return false;
    var pos: usize = 2;
    while (pos < data.len) {
        if (pos + 4 > data.len) return false;
        const group = readBe16(data[pos .. pos + 2]);
        const key_len = readBe16(data[pos + 2 .. pos + 4]);
        pos += 4;
        if (pos + key_len > data.len) return false;
        if (group == tls_named_group_x25519 and key_len == X25519.public_length) {
            info.has_key_share_x25519 = true;
            @memcpy(info.key_share_x25519[0..], data[pos .. pos + key_len]);
        }
        pos += key_len;
    }
    return true;
}

fn planServerHandshake(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return -2;
    const info = parseClientHelloInfo(input) orelse return -6;
    var plan = planServerHandshakeInfo(info) catch |err| return serverPlanErrorCode(err);
    defer std.crypto.secureZero(u8, &plan.server_secret);
    var text: [640]u8 = .{0} ** 640;
    var pos: usize = 0;
    appendText(text[0..], &pos, "serverhandshake;mode=tls12;record=");
    appendU64(text[0..], &pos, plan.selected_major);
    appendText(text[0..], &pos, ".");
    appendU64(text[0..], &pos, plan.selected_minor);
    appendText(text[0..], &pos, ";cipher=");
    appendHex16(text[0..], &pos, plan.selected_cipher);
    appendText(text[0..], &pos, ";cipher_name=");
    appendText(text[0..], &pos, cipherName(plan.selected_cipher));
    appendText(text[0..], &pos, ";serverhello=yes;certificate=yes;cert_len=");
    appendU64(text[0..], &pos, plan.certificate_len);
    appendText(text[0..], &pos, ";cert_path=");
    appendText(text[0..], &pos, dev_cert_path);
    appendText(text[0..], &pos, ";key_path=");
    appendText(text[0..], &pos, dev_key_path);
    appendText(text[0..], &pos, ";server_key_exchange=");
    appendText(text[0..], &pos, if (plan.requires_server_key_exchange) "required" else "none");
    appendText(text[0..], &pos, ";signature=");
    appendHex16(text[0..], &pos, plan.selected_signature);
    appendText(text[0..], &pos, ";signature_name=RSA_PKCS1_SHA256");
    appendText(text[0..], &pos, ";tls13=");
    appendText(text[0..], &pos, if (plan.tls13_seen) "seen-boundary" else "not-offered");
    appendText(text[0..], &pos, ";transcript=clienthello+serverhello+certificate+serverkeyexchange+serverhellodone;stream_ready=");
    appendText(text[0..], &pos, boolText(plan.stream_ready));
    return writeOut(out_buffer, text[0..pos]);
}

const ServerPlanError = error{ Unsupported, EntropyUnavailable };

fn serverPlanErrorCode(err: ServerPlanError) i32 {
    return switch (err) {
        error.Unsupported => stream_result_unsupported_record,
        error.EntropyUnavailable => stream_result_entropy_unavailable,
    };
}

fn planServerHandshakeInfo(info: ClientHelloInfo) ServerPlanError!ServerHandshakePlan {
    if (!info.has_tls12_version or !info.has_cipher_ecdhe_rsa_aes128_gcm_sha256 or
        !info.has_group_x25519 or !info.has_signature_rsa_pkcs1_sha256) return error.Unsupported;
    var plan = ServerHandshakePlan{
        .tls13_seen = info.has_tls13_version,
        .secure_renegotiation = info.has_secure_renegotiation,
        .client_random = info.client_random,
    };
    errdefer std.crypto.secureZero(u8, &plan.server_secret);
    if (!r4os.secure_random.fill(&plan.server_secret) or !r4os.secure_random.fill(&plan.server_random))
        return error.EntropyUnavailable;
    return plan;
}

fn buildServerHandshakeFixture(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return -2;
    const info = parseClientHelloInfo(input) orelse return -6;
    var plan = planServerHandshakeInfo(info) catch |err| return serverPlanErrorCode(err);
    defer std.crypto.secureZero(u8, &plan.server_secret);
    const material = getSystemTlsMaterial() orelse return stream_result_material_missing;
    const out = outputBytes(out_buffer) orelse return -2;
    const len = buildServerHandshakeRecord(out, plan, material) orelse return -5;
    out_buffer.len = @intCast(len);
    return 0;
}

fn buildServerHandshakeRecord(out: []u8, plan: ServerHandshakePlan, material: TlsMaterialView) ?usize {
    if (out.len < tls_server_handshake_fixture_min_capacity) return null;
    var pos: usize = 0;
    out[pos] = tls_content_handshake;
    pos += 1;
    out[pos] = tls_version_major;
    pos += 1;
    out[pos] = tls_version_tls12_minor;
    pos += 1;
    const record_len_pos = pos;
    pos += 2;
    const fragment_start = pos;
    pos = appendServerHello(out, pos, plan);
    pos = appendCertificate(out, pos, material.cert_der);
    pos = appendServerKeyExchangePlan(out, pos, plan, material.key) orelse return null;
    pos = appendServerHelloDone(out, pos);
    writeBe16(out[record_len_pos .. record_len_pos + 2], @intCast(pos - fragment_start));
    return pos;
}

fn describeStreamContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var text: [640]u8 = .{0} ** 640;
    var pos: usize = 0;
    appendText(text[0..], &pos, "stream-contract;ops=read,write,flush,close,alert");
    appendText(text[0..], &pos, ";transport=R4NET/TCPSVC");
    appendText(text[0..], &pos, ";owner=consumer-retains-tcp-handle");
    appendText(text[0..], &pos, ";r4tls=record-framing+alert+status-map");
    appendText(text[0..], &pos, ";would_block=net_service_status_would_block");
    appendText(text[0..], &pos, ";backpressure=tx_window=0");
    appendText(text[0..], &pos, ";disconnect=conn-invalid|lifecycle");
    appendText(text[0..], &pos, ";flush=consumer-waits-for-tcpsvc");
    appendText(text[0..], &pos, ";close=close_notify+tcpsvc-close");
    appendText(text[0..], &pos, ";buffer=input-owned-output-owned");
    appendText(text[0..], &pos, ";max_plaintext=");
    appendU64(text[0..], &pos, tls_max_fragment_len - tls_stream_fixture_tag_len);
    appendText(text[0..], &pos, ";protection=tls12-aes128-gcm");
    appendText(text[0..], &pos, ";fixture_ops=diagnostic-only");
    appendText(text[0..], &pos, ";productive_ops=12,13,14,15,16,17,18,19,20,21");
    appendText(text[0..], &pos, ",22,23,24,25");
    appendText(text[0..], &pos, ";r4lk_app_write=op24:R4AW->R4WX");
    appendText(text[0..], &pos, ";r4lk_app_read=op25:R4AR->R4RX");
    appendText(text[0..], &pos, ";app_write=server-to-client");
    appendText(text[0..], &pos, ";app_read=client-to-server");
    appendText(text[0..], &pos, ";cipher_ready=yes");
    return writeOut(out_buffer, text[0..pos]);
}

fn streamWriteRecord(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len > tls_max_fragment_len - tls_stream_fixture_tag_len) return stream_result_malformed_record;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    const fragment_len = input.len + tls_stream_fixture_tag_len;
    const record_len = tls_record_header_len + fragment_len;
    if (record_len > out.len) return stream_result_buffer_small;

    out[0] = tls_content_application_data;
    out[1] = tls_version_major;
    out[2] = tls_version_tls12_minor;
    writeBe16(out[3..5], @intCast(fragment_len));
    var i: usize = 0;
    while (i < input.len) : (i += 1) out[tls_record_header_len + i] = streamFixtureProtectByte(input[i], i);
    appendStreamFixtureTag(out[tls_record_header_len + input.len .. record_len], out[tls_record_header_len .. tls_record_header_len + input.len]);
    out_buffer.len = @intCast(record_len);
    return stream_result_ok;
}

fn streamReadRecord(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls_record_header_len) return stream_result_would_block;
    const record = recordHeader(input) orelse return stream_result_malformed_record;
    const record_len = tls_record_header_len + record.fragment_len;
    if (input.len < record_len) return stream_result_would_block;
    if (record.content_type == tls_content_alert) return stream_result_alert;
    if (record.content_type != tls_content_application_data) return stream_result_unsupported_record;
    if (record.fragment_len < tls_stream_fixture_tag_len) return stream_result_malformed_record;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    const payload_len = record.fragment_len - tls_stream_fixture_tag_len;
    if (payload_len > out.len) return stream_result_buffer_small;
    const fragment = input[tls_record_header_len..record_len];
    const cipher = fragment[0..payload_len];
    const tag = fragment[payload_len..record.fragment_len];
    if (!verifyStreamFixtureTag(tag, cipher)) return stream_result_integrity_failed;
    var i: usize = 0;
    while (i < payload_len) : (i += 1) out[i] = streamFixtureProtectByte(cipher[i], i);
    out_buffer.len = @intCast(payload_len);
    return stream_result_ok;
}

fn streamAlertRecord(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (tls_record_header_len + 2 > out.len) return stream_result_buffer_small;
    const level: u8 = if (input.len >= 1) input[0] else 1;
    const description: u8 = if (input.len >= 2) input[1] else 0;
    out[0] = tls_content_alert;
    out[1] = tls_version_major;
    out[2] = tls_version_tls12_minor;
    writeBe16(out[3..5], 2);
    out[5] = level;
    out[6] = description;
    out_buffer.len = @intCast(tls_record_header_len + 2);
    return stream_result_ok;
}

fn describeTransportStatus(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const result = tcpResultFromBuffer(in_buffer) orelse return stream_result_malformed_record;
    const status_code = tcpServiceStatusCode(result);
    const handle_valid = (result.flags & r4os.abi.net_service_tcp_flag_handle_valid) != 0;
    const conn_valid = (result.flags & r4os.abi.net_service_tcp_flag_conn_valid) != 0;
    const lifecycle_valid = (result.flags & r4os.abi.net_service_tcp_flag_lifecycle_valid) != 0;
    const would_block = status_code == r4os.abi.net_service_status_would_block or result.lifecycle_cause == r4os.abi.net_service_socket_lifecycle_would_block;
    const backpressure = result.tx_window == 0;
    const disconnect = !handle_valid or !conn_valid or tcpLifecycleDisconnect(result.lifecycle_cause);

    var text: [512]u8 = .{0} ** 512;
    var pos: usize = 0;
    appendText(text[0..], &pos, "stream-transport;transport=tcpsvc;owner=caller-retains-tcpsvc");
    appendText(text[0..], &pos, ";handle_valid=");
    appendText(text[0..], &pos, boolText(handle_valid));
    appendText(text[0..], &pos, ";conn_valid=");
    appendText(text[0..], &pos, boolText(conn_valid));
    appendText(text[0..], &pos, ";lifecycle_valid=");
    appendText(text[0..], &pos, boolText(lifecycle_valid));
    appendText(text[0..], &pos, ";would_block=");
    appendText(text[0..], &pos, boolText(would_block));
    appendText(text[0..], &pos, ";backpressure=");
    appendText(text[0..], &pos, boolText(backpressure));
    appendText(text[0..], &pos, ";disconnect=");
    appendText(text[0..], &pos, boolText(disconnect));
    appendText(text[0..], &pos, ";pending_rx=");
    appendU64(text[0..], &pos, result.pending_rx);
    appendText(text[0..], &pos, ";rx_window=");
    appendU64(text[0..], &pos, result.rx_window);
    appendText(text[0..], &pos, ";tx_window=");
    appendU64(text[0..], &pos, result.tx_window);
    appendText(text[0..], &pos, ";service_status=");
    appendText(text[0..], &pos, tcpServiceStatusName(status_code));
    appendText(text[0..], &pos, ";lifecycle=");
    appendText(text[0..], &pos, tcpLifecycleName(result.lifecycle_cause));
    return writeOut(out_buffer, text[0..pos]);
}

fn describeProductiveContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var text: [1024]u8 = .{0} ** 1024;
    var pos: usize = 0;
    appendText(text[0..], &pos, "productive-contract;tls12=yes");
    appendText(text[0..], &pos, ";cipher=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256");
    appendText(text[0..], &pos, ";prf=HMAC-SHA256");
    appendText(text[0..], &pos, ";key_schedule=op13:R4K1->R4KR");
    appendText(text[0..], &pos, ";x25519=op16:R4X2->R4XR");
    appendText(text[0..], &pos, ";record_protect=op14:R4RP");
    appendText(text[0..], &pos, ";record_open=op15:R4RO");
    appendText(text[0..], &pos, ";rsa_key_contract=op18");
    appendText(text[0..], &pos, ";rsa_sign=op19:R4SG->R4SR");
    appendText(text[0..], &pos, ";session_contract=op20");
    appendText(text[0..], &pos, ";session_harness=op21");
    appendText(text[0..], &pos, ";live_begin=op22:R4LB");
    appendText(text[0..], &pos, ";live_finish=op23:R4LF");
    appendText(text[0..], &pos, ";app_write=op24:R4AW->R4WX");
    appendText(text[0..], &pos, ";app_read=op25:R4AR->R4RX");
    appendText(text[0..], &pos, ";rsa_signature=");
    appendText(text[0..], &pos, signatureSchemeName());
    appendText(text[0..], &pos, ";server_ecdh=derived-x25519-public");
    appendText(text[0..], &pos, ";server_ecdh_scope=per-session-hardware-entropy");
    appendText(text[0..], &pos, ";session_state=clientkeyexchange+ccs+finished");
    appendText(text[0..], &pos, ";finished=client-verify+server-verify");
    appendText(text[0..], &pos, ";aad=seq64+type+0303+plain_len");
    appendText(text[0..], &pos, ";nonce=fixed_iv4+explicit_seq8");
    appendText(text[0..], &pos, ";tag=16");
    appendText(text[0..], &pos, ";fixture_ops=diagnostic-only");
    appendText(text[0..], &pos, ";cert_path=");
    appendText(text[0..], &pos, dev_cert_path);
    appendText(text[0..], &pos, ";key_path=");
    appendText(text[0..], &pos, dev_key_path);
    appendText(text[0..], &pos, ";file_io=r4p-protocol-api");
    appendText(text[0..], &pos, ";cert_loaded=");
    appendText(text[0..], &pos, boolText(system_cert_loaded));
    appendText(text[0..], &pos, ";cert_bytes=");
    appendU64(text[0..], &pos, system_cert_bytes);
    appendText(text[0..], &pos, ";key_loaded=");
    appendText(text[0..], &pos, boolText(system_key_loaded));
    appendText(text[0..], &pos, ";key_bytes=");
    appendU64(text[0..], &pos, system_key_bytes);
    appendText(text[0..], &pos, ";cert_status=");
    appendText(text[0..], &pos, materialStatusName(system_cert_status));
    appendText(text[0..], &pos, ";key_status=");
    appendText(text[0..], &pos, materialStatusName(system_key_status));
    return writeOut(out_buffer, text[0..pos]);
}

fn loadSystemTlsFiles(ctx: *const r4os.r4dev.ProtocolContext2) void {
    resetSystemTlsMaterial();

    var cert_buf: [4096]u8 = .{0} ** 4096;
    const cert_len = ctx.fileRead(dev_cert_path, cert_buf[0..]);
    if (cert_len > 0) {
        const len: usize = @intCast(cert_len);
        system_cert_bytes = @intCast(len);
        if (parseRsaCertContext(cert_buf[0..len])) |cert| {
            @memcpy(system_cert_der[0..cert.der_len], cert.der[0..cert.der_len]);
            system_cert_der_len = cert.der_len;
            system_cert_loaded = true;
            system_cert_status = .ok;
        } else |err| {
            system_cert_status = materialStatusFromError(err);
        }
    } else {
        system_cert_bytes = 0;
        system_cert_loaded = false;
        system_cert_status = .missing;
    }

    var key_buf: [4096]u8 = .{0} ** 4096;
    const key_len = ctx.fileRead(dev_key_path, key_buf[0..]);
    if (key_len > 0) {
        const len: usize = @intCast(key_len);
        system_key_bytes = @intCast(len);
        if (parseRsaKeyContext(key_buf[0..len])) |key| {
            system_key_context = key;
            system_key_loaded = true;
            system_key_status = .ok;
        } else |err| {
            system_key_status = materialStatusFromError(err);
        }
    } else {
        system_key_bytes = 0;
        system_key_loaded = false;
        system_key_status = .missing;
    }

    if (system_cert_loaded and system_key_loaded and !certificateMatchesKey(system_cert_der[0..system_cert_der_len], &system_key_context)) {
        system_cert_loaded = false;
        system_cert_status = .key_mismatch;
        system_key_loaded = false;
        system_key_status = .key_mismatch;
    }

    var catalog_buf: [2048]u8 = .{0} ** 2048;
    const catalog_len = ctx.fileRead(root_catalog_path, catalog_buf[0..]);
    const catalog = if (catalog_len > 0) catalog_buf[0..@intCast(catalog_len)] else "";
    const root_fields = [_][]const u8{ "ROOT", "ROOT_2", "ROOT_3", "ROOT_4", "ROOT_5", "ROOT_6", "ROOT_7", "ROOT_8" };
    for (root_fields, 0..) |field, index| {
        const configured_path = if (findFieldValue(catalog, field)) |value| value else if (index == 0) root_cert_path else continue;
        if (configured_path.len == 0 or configured_path.len >= 260) continue;
        var selected_root_path: [260:0]u8 = .{0} ** 260;
        @memcpy(selected_root_path[0..configured_path.len], configured_path);
        var root_buf: [4096]u8 = .{0} ** 4096;
        const root_len = ctx.fileRead(@ptrCast(&selected_root_path), root_buf[0..]);
        if (root_len <= 0 or system_root_count >= tls_root_max_count) continue;
        const slot = system_root_count;
        if (parseTrustAnchorDer(root_buf[0..@intCast(root_len)], system_root_cert_der[slot][0..])) |der_len| {
            system_root_cert_der_len[slot] = der_len;
            system_root_count += 1;
            system_root_loaded = true;
            system_root_status = .ok;
        } else |err| {
            system_root_status = materialStatusFromError(err);
        }
    }
}

fn resetSystemTlsMaterial() void {
    system_cert_bytes = 0;
    system_key_bytes = 0;
    system_cert_loaded = false;
    system_key_loaded = false;
    system_cert_der_len = 0;
    system_key_context = RsaKeyContext.empty();
    system_cert_status = .missing;
    system_key_status = .missing;
    system_root_status = .missing;
    system_root_loaded = false;
    system_root_cert_der_len = .{0} ** tls_root_max_count;
    system_root_count = 0;
    @memset(system_cert_der[0..], 0);
    @memset(std.mem.sliceAsBytes(system_root_cert_der[0..]), 0);
}

fn getSystemTlsMaterial() ?TlsMaterialView {
    ensureSystemTlsMaterialLoaded();
    if (!system_cert_loaded or !system_key_loaded or !system_key_context.valid or system_cert_der_len == 0) return null;
    return .{
        .cert_der = system_cert_der[0..system_cert_der_len],
        .key = &system_key_context,
    };
}

fn ensureSystemTlsMaterialLoaded() void {
    if (system_cert_loaded and system_key_loaded and system_key_context.valid and system_cert_der_len != 0 and system_root_loaded and system_root_count != 0) return;
    const api = protocol_api orelse return;
    var ctx = r4os.r4dev.ProtocolContext2.init(api);
    loadSystemTlsFiles(&ctx);
}

fn parseRsaKeyContext(text: []const u8) TlsMaterialError!RsaKeyContext {
    if (!contains(text, "BEGIN R4OS DEVELOPMENT TLS PRIVATE KEY") or !contains(text, "END R4OS DEVELOPMENT TLS PRIVATE KEY")) return error.BadPem;
    try requireFieldEquals(text, "KEY_TYPE", "RSA");
    try requireFieldEquals(text, "SIGNATURE_SCHEME", signatureSchemeName());

    var key = RsaKeyContext.empty();
    key.modulus_len = try parseHexFieldInto(text, rsa_modulus_field, key.modulus[0..]);
    key.public_exponent_len = try parseHexFieldInto(text, rsa_public_exponent_field, key.public_exponent[0..]);
    key.private_exponent_len = try parseHexFieldInto(text, rsa_private_exponent_field, key.private_exponent[0..]);
    if (key.modulus_len < rsa_min_modulus_bytes or key.modulus_len > rsa_max_modulus_bytes) return error.KeyTooSmall;
    if (key.private_exponent_len == 0 or key.private_exponent_len > key.modulus_len) return error.BadType;
    const exponent = publicExponentValue(key.public_exponent[0..key.public_exponent_len]) catch return error.BadType;
    if (exponent < 3 or (exponent & 1) == 0) return error.BadType;
    const modulus = RsaModulus.fromBytes(key.modulus[0..key.modulus_len], .big) catch return error.BadType;
    if (modulus.bits() < rsa_min_modulus_bytes * 8) return error.KeyTooSmall;
    key.valid = true;
    return key;
}

fn parseRsaCertContext(text: []const u8) TlsMaterialError!RsaCertContext {
    if (!contains(text, "BEGIN R4OS DEVELOPMENT TLS CERTIFICATE") or !contains(text, "END R4OS DEVELOPMENT TLS CERTIFICATE")) return error.BadPem;
    try requireFieldEquals(text, "KEY_TYPE", "RSA");
    try requireFieldEquals(text, "SIGNATURE_SCHEME", signatureSchemeName());

    var cert = RsaCertContext{
        .der = .{0} ** tls_cert_max_der_bytes,
        .modulus = .{0} ** rsa_max_modulus_bytes,
        .public_exponent = .{0} ** 4,
        .der_len = 0,
        .modulus_len = 0,
        .public_exponent_len = 0,
    };
    cert.der_len = try parseHexFieldInto(text, cert_der_field, cert.der[0..]);
    cert.modulus_len = try parseHexFieldInto(text, rsa_modulus_field, cert.modulus[0..]);
    cert.public_exponent_len = try parseHexFieldInto(text, rsa_public_exponent_field, cert.public_exponent[0..]);
    if (cert.der_len < rsa_min_modulus_bytes or cert.der[0] != 0x30) return error.CertDerInvalid;
    if (cert.modulus_len < rsa_min_modulus_bytes) return error.KeyTooSmall;
    _ = publicExponentValue(cert.public_exponent[0..cert.public_exponent_len]) catch return error.BadType;
    if (!containsBytes(cert.der[0..cert.der_len], cert.modulus[0..cert.modulus_len])) return error.KeyMismatch;
    if (!containsBytes(cert.der[0..cert.der_len], cert.public_exponent[0..cert.public_exponent_len])) return error.KeyMismatch;
    return cert;
}

fn parseTrustAnchorDer(text: []const u8, out: []u8) TlsMaterialError!usize {
    const certificate_wrapper = contains(text, "BEGIN R4OS") and contains(text, "CERTIFICATE");
    const trust_anchor_wrapper = contains(text, "BEGIN R4OS TRUST ANCHOR") and contains(text, "END R4OS TRUST ANCHOR");
    if (!certificate_wrapper and !trust_anchor_wrapper) return error.BadPem;
    const der_len = try parseHexFieldInto(text, cert_der_field, out);
    if (der_len < 64 or out[0] != 0x30) return error.CertDerInvalid;
    const certificate = Certificate{ .buffer = out[0..der_len], .index = 0 };
    _ = certificate.parse() catch return error.CertDerInvalid;
    return der_len;
}

fn certificateMatchesKey(cert_der: []const u8, key: *const RsaKeyContext) bool {
    if (!key.valid) return false;
    if (!containsBytes(cert_der, key.modulus[0..key.modulus_len])) return false;
    if (!containsBytes(cert_der, key.public_exponent[0..key.public_exponent_len])) return false;
    return true;
}

fn describeRsaKeyContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var text: [1024]u8 = .{0} ** 1024;
    var pos: usize = 0;
    appendText(text[0..], &pos, "rsa-key-contract;format=R4OS-DEVELOPMENT-TLS");
    appendText(text[0..], &pos, ";key_type=RSA");
    appendText(text[0..], &pos, ";signature_scheme=");
    appendText(text[0..], &pos, signatureSchemeName());
    appendText(text[0..], &pos, ";sign_op=op19:R4SG->R4SR");
    appendText(text[0..], &pos, ";cert_path=");
    appendText(text[0..], &pos, dev_cert_path);
    appendText(text[0..], &pos, ";key_path=");
    appendText(text[0..], &pos, dev_key_path);
    appendText(text[0..], &pos, ";cert_status=");
    appendText(text[0..], &pos, materialStatusName(system_cert_status));
    appendText(text[0..], &pos, ";key_status=");
    appendText(text[0..], &pos, materialStatusName(system_key_status));
    appendText(text[0..], &pos, ";cert_der_bytes=");
    appendU64(text[0..], &pos, system_cert_der_len);
    appendText(text[0..], &pos, ";modulus_bits=");
    appendU64(text[0..], &pos, if (system_key_context.valid) system_key_context.modulus_len * 8 else 0);
    appendText(text[0..], &pos, ";der_key_match=");
    appendText(text[0..], &pos, boolText(system_cert_loaded and system_key_loaded));
    appendText(text[0..], &pos, ";pem_errors=bad_pem|missing_field|bad_hex|field_too_large|bad_type|key_mismatch");
    return writeOut(out_buffer, text[0..pos]);
}

fn tls12SignServerKeyExchangeDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len <= tls12_rsa_sign_header_len or !startsWith(input, magic_rsa_sign_in)) return stream_result_malformed_record;
    const material = getSystemTlsMaterial() orelse return stream_result_material_missing;
    const payload = input[tls12_rsa_sign_header_len..];
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_rsa_sign_out_header_len + material.key.modulus_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_rsa_sign_out);
    writeBe16(out[4..6], tls_signature_rsa_pkcs1_sha256);
    const sig_len = rsaPkcs1Sha256Sign(out[tls12_rsa_sign_out_header_len..], material.key, payload) catch return stream_result_material_invalid;
    writeBe16(out[6..8], @intCast(sig_len));
    out_buffer.len = @intCast(tls12_rsa_sign_out_header_len + sig_len);
    return stream_result_ok;
}

fn rsaPkcs1Sha256Sign(out: []u8, key: *const RsaKeyContext, payload: []const u8) TlsMaterialError!usize {
    if (!key.valid) return error.MissingField;
    if (out.len < key.modulus_len) return error.FieldTooLarge;
    var encoded: [rsa_max_modulus_bytes]u8 = .{0} ** rsa_max_modulus_bytes;
    try buildPkcs1Sha256Encoded(encoded[0..key.modulus_len], payload);

    const modulus = RsaModulus.fromBytes(key.modulus[0..key.modulus_len], .big) catch return error.BadType;
    const message = RsaModulus.Fe.fromBytes(modulus, encoded[0..key.modulus_len], .big) catch return error.SignFailed;
    const signature = modulus.powWithEncodedExponent(message, key.private_exponent[0..key.private_exponent_len], .big) catch return error.SignFailed;
    signature.toBytes(out[0..key.modulus_len], .big) catch return error.SignFailed;
    if (!rsaPkcs1Sha256Verify(key, payload, out[0..key.modulus_len])) return error.SignFailed;
    return key.modulus_len;
}

fn rsaPkcs1Sha256Verify(key: *const RsaKeyContext, payload: []const u8, signature: []const u8) bool {
    if (!key.valid or signature.len != key.modulus_len) return false;
    var expected: [rsa_max_modulus_bytes]u8 = .{0} ** rsa_max_modulus_bytes;
    buildPkcs1Sha256Encoded(expected[0..key.modulus_len], payload) catch return false;
    const modulus = RsaModulus.fromBytes(key.modulus[0..key.modulus_len], .big) catch return false;
    const sig_fe = RsaModulus.Fe.fromBytes(modulus, signature, .big) catch return false;
    const message = modulus.powWithEncodedPublicExponent(sig_fe, key.public_exponent[0..key.public_exponent_len], .big) catch return false;
    var recovered: [rsa_max_modulus_bytes]u8 = .{0} ** rsa_max_modulus_bytes;
    message.toBytes(recovered[0..key.modulus_len], .big) catch return false;
    return std.mem.eql(u8, recovered[0..key.modulus_len], expected[0..key.modulus_len]);
}

fn rsaCertKey(cert: *const RsaCertContext) ?RsaKeyContext {
    if (cert.modulus_len < rsa_min_modulus_bytes or cert.modulus_len > rsa_max_modulus_bytes or cert.public_exponent_len == 0) return null;
    var key = RsaKeyContext.empty();
    @memcpy(key.modulus[0..cert.modulus_len], cert.modulus[0..cert.modulus_len]);
    @memcpy(key.public_exponent[0..cert.public_exponent_len], cert.public_exponent[0..cert.public_exponent_len]);
    key.modulus_len = cert.modulus_len;
    key.public_exponent_len = cert.public_exponent_len;
    key.valid = true;
    return key;
}

const X509ValidationFailure = enum {
    none,
    material,
    clock,
    parse,
    hostname,
    validity,
    chain,
    root,
};

fn validateX509Leaf(leaf_der: []const u8, hostname: []const u8, now_utc: u64) ?Certificate.Parsed {
    var certificates: [tls_cert_chain_max_count][]const u8 = .{""} ** tls_cert_chain_max_count;
    certificates[0] = leaf_der;
    var failure: X509ValidationFailure = .none;
    return validateX509Chain(certificates, 1, hostname, now_utc, &failure);
}

fn validateX509Chain(certificates: [tls_cert_chain_max_count][]const u8, certificate_count: usize, hostname: []const u8, now_utc: u64, failure: *X509ValidationFailure) ?Certificate.Parsed {
    failure.* = .none;
    if (!system_root_loaded or system_root_count == 0 or certificate_count == 0 or certificate_count > tls_cert_chain_max_count) {
        failure.* = .material;
        return null;
    }
    const now_seconds = utcStampToUnixSeconds(now_utc) orelse {
        failure.* = .clock;
        return null;
    };
    const leaf_certificate = Certificate{ .buffer = certificates[0], .index = 0 };
    var child = leaf_certificate.parse() catch {
        failure.* = .parse;
        return null;
    };
    child.verifyHostName(hostname) catch {
        failure.* = .hostname;
        return null;
    };

    var index: usize = 1;
    while (index < certificate_count) : (index += 1) {
        const issuer_certificate = Certificate{ .buffer = certificates[index], .index = 0 };
        const issuer = issuer_certificate.parse() catch {
            failure.* = .parse;
            return null;
        };
        child.verify(issuer, now_seconds) catch |err| {
            failure.* = switch (err) {
                error.CertificateNotYetValid, error.CertificateExpired => .validity,
                else => .chain,
            };
            return null;
        };
        child = issuer;
    }

    var root_index: usize = 0;
    while (root_index < system_root_count) : (root_index += 1) {
        const root_certificate = Certificate{ .buffer = system_root_cert_der[root_index][0..system_root_cert_der_len[root_index]], .index = 0 };
        const root = root_certificate.parse() catch continue;
        child.verify(root, now_seconds) catch |err| {
            if (err == error.CertificateNotYetValid or err == error.CertificateExpired) failure.* = .validity;
            continue;
        };
        // RFC 5280 section 6.1.1 defines the trust anchor as trusted input;
        // it is not part of the prospective certification path. The final
        // path certificate is still verified against this configured root,
        // but the root certificate itself is therefore not self-verified.
        return leaf_certificate.parse() catch null;
    }
    if (failure.* == .none) failure.* = .root;
    return null;
}

fn utcStampToUnixSeconds(stamp: u64) ?i64 {
    const year: u16 = @intCast(stamp / 10_000_000_000);
    const month: u8 = @intCast((stamp / 100_000_000) % 100);
    const day: u8 = @intCast((stamp / 1_000_000) % 100);
    const hour: u8 = @intCast((stamp / 10_000) % 100);
    const minute: u8 = @intCast((stamp / 100) % 100);
    const second: u8 = @intCast(stamp % 100);
    if (year < 1970 or month == 0 or month > 12 or day == 0 or hour > 23 or minute > 59 or second > 59) return null;
    const days_in_month = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    const leap = (year % 4 == 0 and year % 100 != 0) or year % 400 == 0;
    const max_day = if (month == 2 and leap) 29 else days_in_month[month - 1];
    if (day > max_day) return null;
    var days: i64 = 0;
    var current_year: u16 = 1970;
    while (current_year < year) : (current_year += 1) days += if ((current_year % 4 == 0 and current_year % 100 != 0) or current_year % 400 == 0) 366 else 365;
    var current_month: u8 = 1;
    while (current_month < month) : (current_month += 1) days += if (current_month == 2 and leap) 29 else days_in_month[current_month - 1];
    days += day - 1;
    return days * 86_400 + @as(i64, hour) * 3600 + @as(i64, minute) * 60 + second;
}

fn parseX509Certificate(der: []const u8) ?X509CertificateView {
    var outer_pos: usize = 0;
    const certificate = derElement(der, &outer_pos) orelse return null;
    if (certificate.tag != 0x30 or outer_pos != der.len) return null;
    var cert_pos: usize = 0;
    const tbs = derElement(certificate.value, &cert_pos) orelse return null;
    const signature_algorithm = derElement(certificate.value, &cert_pos) orelse return null;
    const signature_bits = derElement(certificate.value, &cert_pos) orelse return null;
    if (tbs.tag != 0x30 or signature_algorithm.tag != 0x30 or signature_bits.tag != 0x03 or signature_bits.value.len < 2 or signature_bits.value[0] != 0) return null;
    if (!algorithmIsSha256Rsa(signature_algorithm.value)) return null;

    var pos: usize = 0;
    if (pos < tbs.value.len and tbs.value[pos] == 0xA0) _ = derElement(tbs.value, &pos) orelse return null;
    _ = derElement(tbs.value, &pos) orelse return null;
    const tbs_signature = derElement(tbs.value, &pos) orelse return null;
    const issuer = derElement(tbs.value, &pos) orelse return null;
    const validity = derElement(tbs.value, &pos) orelse return null;
    const subject = derElement(tbs.value, &pos) orelse return null;
    const spki = derElement(tbs.value, &pos) orelse return null;
    if (tbs_signature.tag != 0x30 or !algorithmIsSha256Rsa(tbs_signature.value) or issuer.tag != 0x30 or validity.tag != 0x30 or subject.tag != 0x30 or spki.tag != 0x30) return null;

    var validity_pos: usize = 0;
    const not_before_element = derElement(validity.value, &validity_pos) orelse return null;
    const not_after_element = derElement(validity.value, &validity_pos) orelse return null;
    const not_before = parseDerTime(not_before_element) orelse return null;
    const not_after = parseDerTime(not_after_element) orelse return null;
    const common_name = findNameValue(subject.value, &[_]u8{ 0x55, 0x04, 0x03 }) orelse "";
    const public_key = parseSubjectPublicKey(spki.value) orelse return null;

    var san_names: []const u8 = "";
    while (pos < tbs.value.len) {
        const optional = derElement(tbs.value, &pos) orelse return null;
        if (optional.tag == 0xA3) san_names = findSubjectAltNames(optional.value) orelse "";
    }
    return .{
        .tbs = tbs.full,
        .signature = signature_bits.value[1..],
        .issuer = issuer.full,
        .subject = subject.full,
        .not_before = not_before,
        .not_after = not_after,
        .common_name = common_name,
        .san_names = san_names,
        .public_key = public_key,
    };
}

fn parseSubjectPublicKey(spki_value: []const u8) ?RsaCertContext {
    var pos: usize = 0;
    const algorithm = derElement(spki_value, &pos) orelse return null;
    const bits = derElement(spki_value, &pos) orelse return null;
    if (algorithm.tag != 0x30 or bits.tag != 0x03 or bits.value.len < 2 or bits.value[0] != 0) return null;
    if (!algorithmIsRsa(algorithm.value)) return null;
    var bit_pos: usize = 0;
    const sequence = derElement(bits.value[1..], &bit_pos) orelse return null;
    if (sequence.tag != 0x30 or bit_pos != bits.value.len - 1) return null;
    var key_pos: usize = 0;
    const modulus_element = derElement(sequence.value, &key_pos) orelse return null;
    const exponent_element = derElement(sequence.value, &key_pos) orelse return null;
    if (modulus_element.tag != 0x02 or exponent_element.tag != 0x02) return null;
    var modulus = modulus_element.value;
    while (modulus.len > 0 and modulus[0] == 0) modulus = modulus[1..];
    var exponent = exponent_element.value;
    while (exponent.len > 0 and exponent[0] == 0) exponent = exponent[1..];
    if (modulus.len < rsa_min_modulus_bytes or modulus.len > rsa_max_modulus_bytes or exponent.len == 0 or exponent.len > 4) return null;
    var cert = RsaCertContext.empty();
    @memcpy(cert.modulus[0..modulus.len], modulus);
    @memcpy(cert.public_exponent[0..exponent.len], exponent);
    cert.modulus_len = modulus.len;
    cert.public_exponent_len = exponent.len;
    return cert;
}

fn findNameValue(name_value: []const u8, oid: []const u8) ?[]const u8 {
    var set_pos: usize = 0;
    while (set_pos < name_value.len) {
        const set = derElement(name_value, &set_pos) orelse return null;
        if (set.tag != 0x31) continue;
        var seq_pos: usize = 0;
        const sequence = derElement(set.value, &seq_pos) orelse continue;
        if (sequence.tag != 0x30) continue;
        var attr_pos: usize = 0;
        const attr_oid = derElement(sequence.value, &attr_pos) orelse continue;
        const attr_value = derElement(sequence.value, &attr_pos) orelse continue;
        if (attr_oid.tag == 0x06 and std.mem.eql(u8, attr_oid.value, oid) and
            (attr_value.tag == 0x0C or attr_value.tag == 0x13 or attr_value.tag == 0x16))
        {
            return attr_value.value;
        }
    }
    return null;
}

fn findSubjectAltNames(explicit_value: []const u8) ?[]const u8 {
    var pos: usize = 0;
    const extensions = derElement(explicit_value, &pos) orelse return null;
    if (extensions.tag != 0x30) return null;
    var ext_pos: usize = 0;
    while (ext_pos < extensions.value.len) {
        const extension = derElement(extensions.value, &ext_pos) orelse return null;
        if (extension.tag != 0x30) continue;
        var item_pos: usize = 0;
        const oid = derElement(extension.value, &item_pos) orelse continue;
        if (item_pos < extension.value.len and extension.value[item_pos] == 0x01) _ = derElement(extension.value, &item_pos) orelse continue;
        const octets = derElement(extension.value, &item_pos) orelse continue;
        if (oid.tag == 0x06 and std.mem.eql(u8, oid.value, &[_]u8{ 0x55, 0x1D, 0x11 }) and octets.tag == 0x04) return octets.value;
    }
    return null;
}

fn certificateHostnameMatches(cert: X509CertificateView, hostname: []const u8) bool {
    if (cert.san_names.len != 0) {
        var pos: usize = 0;
        const names = derElement(cert.san_names, &pos) orelse return false;
        if (names.tag != 0x30) return false;
        var name_pos: usize = 0;
        while (name_pos < names.value.len) {
            const name = derElement(names.value, &name_pos) orelse return false;
            if (name.tag == 0x82 and hostnamePatternMatches(name.value, hostname)) return true;
        }
        return false;
    }
    return hostnamePatternMatches(cert.common_name, hostname);
}

fn hostnamePatternMatches(pattern: []const u8, hostname: []const u8) bool {
    if (std.ascii.eqlIgnoreCase(pattern, hostname)) return true;
    if (pattern.len < 3 or pattern[0] != '*' or pattern[1] != '.') return false;
    const suffix = pattern[1..];
    if (hostname.len <= suffix.len or !std.ascii.endsWithIgnoreCase(hostname, suffix)) return false;
    const prefix = hostname[0 .. hostname.len - suffix.len];
    return prefix.len > 0 and std.mem.indexOfScalar(u8, prefix, '.') == null;
}

fn parseDerTime(element: DerElement) ?u64 {
    const value = element.value;
    var year: u64 = 0;
    var offset: usize = 0;
    if (element.tag == 0x17 and value.len == 13 and value[12] == 'Z') {
        const short = parseTwoDigits(value[0..2]) orelse return null;
        year = if (short >= 50) 1900 + short else 2000 + short;
        offset = 2;
    } else if (element.tag == 0x18 and value.len == 15 and value[14] == 'Z') {
        year = parseFourDigits(value[0..4]) orelse return null;
        offset = 4;
    } else return null;
    const month = parseTwoDigits(value[offset .. offset + 2]) orelse return null;
    const day = parseTwoDigits(value[offset + 2 .. offset + 4]) orelse return null;
    const hour = parseTwoDigits(value[offset + 4 .. offset + 6]) orelse return null;
    const minute = parseTwoDigits(value[offset + 6 .. offset + 8]) orelse return null;
    const second = parseTwoDigits(value[offset + 8 .. offset + 10]) orelse return null;
    if (month == 0 or month > 12 or day == 0 or day > 31 or hour > 23 or minute > 59 or second > 60) return null;
    return year * 10_000_000_000 + month * 100_000_000 + day * 1_000_000 + hour * 10_000 + minute * 100 + second;
}

fn parseTwoDigits(value: []const u8) ?u64 {
    if (value.len != 2 or value[0] < '0' or value[0] > '9' or value[1] < '0' or value[1] > '9') return null;
    return @as(u64, value[0] - '0') * 10 + value[1] - '0';
}

fn parseFourDigits(value: []const u8) ?u64 {
    const high = parseTwoDigits(value[0..2]) orelse return null;
    const low = parseTwoDigits(value[2..4]) orelse return null;
    return high * 100 + low;
}

fn algorithmIsSha256Rsa(value: []const u8) bool {
    return containsBytes(value, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B });
}

fn algorithmIsRsa(value: []const u8) bool {
    return containsBytes(value, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01 });
}

fn derElement(input: []const u8, pos: *usize) ?DerElement {
    const start = pos.*;
    if (start + 2 > input.len) return null;
    const tag = input[start];
    var cursor = start + 1;
    const first_len = input[cursor];
    cursor += 1;
    var len: usize = 0;
    if ((first_len & 0x80) == 0) {
        len = first_len;
    } else {
        const count: usize = first_len & 0x7F;
        if (count == 0 or count > 4 or cursor + count > input.len) return null;
        for (input[cursor .. cursor + count]) |byte| {
            len = std.math.mul(usize, len, 256) catch return null;
            len = std.math.add(usize, len, byte) catch return null;
        }
        if (len < 128) return null;
        cursor += count;
    }
    if (len > input.len - cursor) return null;
    const end = cursor + len;
    pos.* = end;
    return .{ .tag = tag, .full = input[start..end], .value = input[cursor..end] };
}

fn buildPkcs1Sha256Encoded(out: []u8, payload: []const u8) TlsMaterialError!void {
    if (out.len < rsa_sha256_digest_info_len + 11) return error.KeyTooSmall;
    const sha256_der = [_]u8{
        0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
        0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
        0x00, 0x04, 0x20,
    };
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(payload, &digest, .{});
    const ps_len = out.len - sha256_der.len - digest.len - 3;
    if (ps_len < 8) return error.KeyTooSmall;
    out[0] = 0x00;
    out[1] = 0x01;
    @memset(out[2 .. 2 + ps_len], 0xff);
    out[2 + ps_len] = 0x00;
    @memcpy(out[3 + ps_len .. 3 + ps_len + sha256_der.len], sha256_der[0..]);
    @memcpy(out[3 + ps_len + sha256_der.len .. 3 + ps_len + sha256_der.len + digest.len], digest[0..]);
}

fn requireFieldEquals(text: []const u8, field: []const u8, expected: []const u8) TlsMaterialError!void {
    const value = findFieldValue(text, field) orelse return error.MissingField;
    if (!std.mem.eql(u8, value, expected)) {
        if (std.mem.eql(u8, field, "SIGNATURE_SCHEME")) return error.UnsupportedScheme;
        return error.BadType;
    }
}

fn parseHexFieldInto(text: []const u8, field: []const u8, out: []u8) TlsMaterialError!usize {
    const hex = findFieldValue(text, field) orelse return error.MissingField;
    if (hex.len == 0 or (hex.len & 1) != 0) return error.BadHex;
    const len = hex.len / 2;
    if (len > out.len) return error.FieldTooLarge;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        const hi = hexValue(hex[i * 2]) orelse return error.BadHex;
        const lo = hexValue(hex[i * 2 + 1]) orelse return error.BadHex;
        out[i] = (hi << 4) | lo;
    }
    return len;
}

fn findFieldValue(text: []const u8, field: []const u8) ?[]const u8 {
    var pos: usize = 0;
    while (pos < text.len) {
        var line_end = pos;
        while (line_end < text.len and text[line_end] != '\n') : (line_end += 1) {}
        const raw_line = text[pos..line_end];
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len > field.len + 1 and startsWith(line, field) and line[field.len] == '=') {
            return std.mem.trim(u8, line[field.len + 1 ..], " \t\r");
        }
        pos = if (line_end < text.len) line_end + 1 else text.len;
    }
    return null;
}

fn publicExponentValue(bytes: []const u8) TlsMaterialError!u32 {
    if (bytes.len == 0 or bytes.len > 4) return error.BadType;
    var value: u32 = 0;
    var i: usize = 0;
    while (i < bytes.len) : (i += 1) value = (value << 8) | bytes[i];
    return value;
}

fn hexValue(ch: u8) ?u8 {
    if (ch >= '0' and ch <= '9') return ch - '0';
    if (ch >= 'a' and ch <= 'f') return ch - 'a' + 10;
    if (ch >= 'A' and ch <= 'F') return ch - 'A' + 10;
    return null;
}

fn containsBytes(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        if (std.mem.eql(u8, haystack[i .. i + needle.len], needle)) return true;
    }
    return false;
}

fn materialStatusFromError(err: TlsMaterialError) TlsMaterialStatus {
    return switch (err) {
        error.BadPem => .bad_pem,
        error.MissingField => .missing_field,
        error.BadHex => .bad_hex,
        error.FieldTooLarge => .field_too_large,
        error.BadType => .bad_type,
        error.UnsupportedScheme => .unsupported_scheme,
        error.KeyTooSmall => .key_too_small,
        error.CertTooLarge => .cert_too_large,
        error.CertDerInvalid => .cert_der_invalid,
        error.KeyMismatch => .key_mismatch,
        error.SignFailed => .sign_failed,
    };
}

fn materialStatusName(status: TlsMaterialStatus) []const u8 {
    return switch (status) {
        .missing => "missing",
        .ok => "ok",
        .bad_pem => "bad-pem",
        .missing_field => "missing-field",
        .bad_hex => "bad-hex",
        .field_too_large => "field-too-large",
        .bad_type => "bad-type",
        .unsupported_scheme => "unsupported-scheme",
        .key_too_small => "key-too-small",
        .cert_too_large => "cert-too-large",
        .cert_der_invalid => "cert-der-invalid",
        .key_mismatch => "key-mismatch",
        .sign_failed => "sign-failed",
    };
}

fn signatureSchemeName() []const u8 {
    return signature_scheme_name;
}

fn describeNegativeWireContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    return writeOut(out_buffer, "negative-wire;bad_cipher=-7;missing_tls12=-7;missing_x25519=-7;missing_signature=-7;malformed_record=-6;bad_tag=-8;missing_tls_material=-9;invalid_tls_material=-10;alert=fatal/handshake_failure");
}

fn describeTls12SessionContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var text: [768]u8 = .{0} ** 768;
    var pos: usize = 0;
    appendText(text[0..], &pos, "tls12-session-contract");
    appendText(text[0..], &pos, ";ops=op20:contract,op21:harness");
    appendText(text[0..], &pos, ",op22:live-begin,op23:live-finish");
    appendText(text[0..], &pos, ";owner=R4TLS");
    appendText(text[0..], &pos, ";state=clienthello+serverhandshake+clientkeyexchange+ccs+finished");
    appendText(text[0..], &pos, ";client_key_exchange=parse-x25519");
    appendText(text[0..], &pos, ";key_agreement=x25519");
    appendText(text[0..], &pos, ";key_schedule=prf-sha256");
    appendText(text[0..], &pos, ";records=aes128gcm");
    appendText(text[0..], &pos, ";finished=client-verify+server-finished");
    appendText(text[0..], &pos, ";sequence=client0/server0");
    appendText(text[0..], &pos, ";negative=bad-clientkeyexchange,bad-finished-tag,bad-transcript");
    appendText(text[0..], &pos, ";rdpsvc=consumer-only");
    appendText(text[0..], &pos, ";live_state=R4L2");
    appendText(text[0..], &pos, ";stream_state=R4LK");
    appendText(text[0..], &pos, ";next=credssp");
    return writeOut(out_buffer, text[0..pos]);
}

fn tls12SessionHarnessDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var result: Tls12SessionHarnessResult = undefined;
    const rc = runTls12SessionHarness(&result);
    if (rc != stream_result_ok) return rc;

    var text: [1024]u8 = .{0} ** 1024;
    var pos: usize = 0;
    appendText(text[0..], &pos, "tls12-session");
    appendText(text[0..], &pos, ";clienthello=yes;serverhandshake=yes");
    appendText(text[0..], &pos, ";client_key_exchange=ok");
    appendText(text[0..], &pos, ";shared_secret=");
    appendText(text[0..], &pos, boolText(!allZero(result.shared_secret[0..])));
    appendText(text[0..], &pos, ";key_schedule=ok");
    appendText(text[0..], &pos, ";client_ccs=ok");
    appendText(text[0..], &pos, ";client_finished=ok");
    appendText(text[0..], &pos, ";server_finished=ok");
    appendText(text[0..], &pos, ";client_seq_next=");
    appendU64(text[0..], &pos, result.client_seq_next);
    appendText(text[0..], &pos, ";server_seq_next=");
    appendU64(text[0..], &pos, result.server_seq_next);
    appendText(text[0..], &pos, ";client_hello_bytes=");
    appendU64(text[0..], &pos, result.client_hello_len);
    appendText(text[0..], &pos, ";server_handshake_bytes=");
    appendU64(text[0..], &pos, result.server_handshake_len);
    appendText(text[0..], &pos, ";client_key_exchange_bytes=");
    appendU64(text[0..], &pos, result.client_key_exchange_len);
    appendText(text[0..], &pos, ";client_finished_record=");
    appendU64(text[0..], &pos, result.client_finished_record_len);
    appendText(text[0..], &pos, ";server_finished_record=");
    appendU64(text[0..], &pos, result.server_finished_record_len);
    appendText(text[0..], &pos, ";transcript_bytes=");
    appendU64(text[0..], &pos, result.transcript_len);
    appendText(text[0..], &pos, ";negative=bad-clientkeyexchange,bad-finished-tag,bad-transcript");
    appendText(text[0..], &pos, ";next=credssp");
    return writeOut(out_buffer, text[0..pos]);
}

fn tls12KeyScheduleDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len != tls12_key_schedule_in_len or !startsWith(input, magic_key_schedule_in)) return stream_result_malformed_record;
    const pre_master = input[4 .. 4 + tls_pre_master_len];
    const client_random = input[4 + tls_pre_master_len .. 4 + tls_pre_master_len + tls_random_len];
    const server_random = input[4 + tls_pre_master_len + tls_random_len .. tls12_key_schedule_in_len];
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_key_schedule_out_len) return stream_result_buffer_small;

    @memcpy(out[0..4], magic_key_schedule_out);
    const master = out[4 .. 4 + tls_master_secret_len];
    tls12Prf(master, pre_master, "master secret", client_random, server_random);

    var key_block: [tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len + tls_aes_gcm_fixed_iv_len]u8 = undefined;
    tls12Prf(key_block[0..], master, "key expansion", server_random, client_random);
    @memcpy(out[4 + tls_master_secret_len .. 4 + tls_master_secret_len + key_block.len], key_block[0..]);
    out_buffer.len = @intCast(tls12_key_schedule_out_len);
    return stream_result_ok;
}

fn tls12ProtectRecordDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_record_protect_header_len or !startsWith(input, magic_record_protect_in)) return stream_result_malformed_record;
    const sequence = readBe64(input[4..12]);
    const content_type = input[12];
    if (!isProtectableContentType(content_type)) return stream_result_unsupported_record;
    const fixed_iv = input[13..17].*;
    const key = input[17..33].*;
    const plain = input[tls12_record_protect_header_len..];
    if (plain.len > tls_max_fragment_len) return stream_result_malformed_record;

    const fragment_len = tls_aes_gcm_explicit_nonce_len + plain.len + tls_aes_gcm_tag_len;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (tls_record_header_len + fragment_len > out.len) return stream_result_buffer_small;

    out[0] = content_type;
    out[1] = tls_version_major;
    out[2] = tls_version_tls12_minor;
    writeBe16(out[3..5], @intCast(fragment_len));
    writeBe64(out[5..13], sequence);
    var nonce: [Aes128Gcm.nonce_length]u8 = undefined;
    @memcpy(nonce[0..tls_aes_gcm_fixed_iv_len], fixed_iv[0..]);
    @memcpy(nonce[tls_aes_gcm_fixed_iv_len..], out[5..13]);
    var aad: [13]u8 = undefined;
    buildTls12Aad(&aad, sequence, content_type, plain.len);
    const cipher = out[13 .. 13 + plain.len];
    const tag: *[tls_aes_gcm_tag_len]u8 = out[13 + plain.len ..][0..tls_aes_gcm_tag_len];
    Aes128Gcm.encrypt(cipher, tag, plain, aad[0..], nonce, key);
    out_buffer.len = @intCast(tls_record_header_len + fragment_len);
    return stream_result_ok;
}

fn tls12OpenRecordDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_record_open_header_len + tls_record_header_len or !startsWith(input, magic_record_open_in)) return stream_result_malformed_record;
    const sequence = readBe64(input[4..12]);
    const fixed_iv = input[12..16].*;
    const key = input[16..32].*;
    const record_bytes = input[tls12_record_open_header_len..];
    const record = recordHeader(record_bytes) orelse return stream_result_malformed_record;
    if (!isProtectableContentType(record.content_type)) return stream_result_unsupported_record;
    const record_len = tls_record_header_len + record.fragment_len;
    if (record_bytes.len < record_len) return stream_result_would_block;
    if (record.fragment_len < tls_aes_gcm_explicit_nonce_len + tls_aes_gcm_tag_len) return stream_result_malformed_record;

    const payload_len = record.fragment_len - tls_aes_gcm_explicit_nonce_len - tls_aes_gcm_tag_len;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (payload_len > out.len) return stream_result_buffer_small;

    const explicit_nonce = record_bytes[tls_record_header_len .. tls_record_header_len + tls_aes_gcm_explicit_nonce_len];
    var nonce: [Aes128Gcm.nonce_length]u8 = undefined;
    @memcpy(nonce[0..tls_aes_gcm_fixed_iv_len], fixed_iv[0..]);
    @memcpy(nonce[tls_aes_gcm_fixed_iv_len..], explicit_nonce);
    var aad: [13]u8 = undefined;
    buildTls12Aad(&aad, sequence, record.content_type, payload_len);
    const cipher_start = tls_record_header_len + tls_aes_gcm_explicit_nonce_len;
    const cipher = record_bytes[cipher_start .. cipher_start + payload_len];
    const tag = record_bytes[cipher_start + payload_len ..][0..tls_aes_gcm_tag_len].*;
    Aes128Gcm.decrypt(out[0..payload_len], cipher, tag, aad[0..], nonce, key) catch return stream_result_integrity_failed;
    out_buffer.len = @intCast(payload_len);
    return stream_result_ok;
}

fn tls12X25519Dispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len != tls12_x25519_in_len or !startsWith(input, magic_x25519_in)) return stream_result_malformed_record;
    const server_secret = input[4 .. 4 + X25519.secret_length].*;
    const client_public = input[4 + X25519.secret_length .. tls12_x25519_in_len].*;
    const server_public = X25519.recoverPublicKey(server_secret) catch return stream_result_integrity_failed;
    const shared = X25519.scalarmult(server_secret, client_public) catch return stream_result_integrity_failed;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_x25519_out_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_x25519_out);
    @memcpy(out[4 .. 4 + X25519.public_length], server_public[0..]);
    @memcpy(out[4 + X25519.public_length .. tls12_x25519_out_len], shared[0..]);
    out_buffer.len = @intCast(tls12_x25519_out_len);
    return stream_result_ok;
}

fn tls12LiveBeginDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const client_hello = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    const client_info = parseClientHelloInfo(client_hello) orelse return stream_result_malformed_record;
    var plan = planServerHandshakeInfo(client_info) catch |err| return serverPlanErrorCode(err);
    defer std.crypto.secureZero(u8, &plan.server_secret);
    const material = getSystemTlsMaterial() orelse return stream_result_material_missing;

    var server_record: [4096]u8 = .{0} ** 4096;
    const server_record_len = buildServerHandshakeRecord(server_record[0..], plan, material) orelse return stream_result_buffer_small;
    const server_header = recordHeader(server_record[0..server_record_len]) orelse return stream_result_malformed_record;
    if (server_header.content_type != tls_content_handshake or server_header.fragment_len + tls_record_header_len != server_record_len) return stream_result_malformed_record;

    var transcript: [tls12_live_max_transcript_len]u8 = .{0} ** tls12_live_max_transcript_len;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, client_hello[tls_record_header_len..client_hello.len])) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, server_record[tls_record_header_len..server_record_len])) return stream_result_buffer_small;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_live_header_len) return stream_result_buffer_small;
    const state_offset = tls12_live_header_len;
    const state_len = writeTls12LiveState(out[state_offset..], client_info.client_random, plan.server_random, plan.server_secret, transcript[0..transcript_len]) orelse return stream_result_buffer_small;
    const server_offset = state_offset + state_len;
    const total_len = server_offset + server_record_len;
    if (total_len > out.len) return stream_result_buffer_small;

    @memcpy(out[0..4], magic_tls12_live_begin_out);
    writeBe32(out[4..8], @intCast(state_len));
    writeBe32(out[8..12], @intCast(server_record_len));
    @memcpy(out[server_offset..total_len], server_record[0..server_record_len]);
    out_buffer.len = @intCast(total_len);
    return stream_result_ok;
}

fn tls12LiveFinishDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    var state = parseTls12LiveState(input) orelse return stream_result_malformed_record;
    defer std.crypto.secureZero(u8, &state.server_secret);
    const flight = input[state.total_len..];
    if (flight.len < tls_record_header_len) return stream_result_would_block;

    const client_key_header = recordHeader(flight) orelse return stream_result_malformed_record;
    const client_key_record_len = tls_record_header_len + client_key_header.fragment_len;
    if (flight.len < client_key_record_len) return stream_result_would_block;
    const parsed_client_public = parseClientKeyExchangeRecord(flight[0..client_key_record_len]) orelse return stream_result_malformed_record;
    var client_public: [X25519.public_length]u8 = undefined;
    @memcpy(client_public[0..], parsed_client_public);

    var pos: usize = client_key_record_len;
    if (flight.len < pos + tls12_ccs_record_len) return stream_result_would_block;
    if (!isChangeCipherSpecRecord(flight[pos .. pos + tls12_ccs_record_len])) return stream_result_malformed_record;
    pos += tls12_ccs_record_len;
    if (flight.len < pos + tls_record_header_len) return stream_result_would_block;
    const finished_header = recordHeader(flight[pos..]) orelse return stream_result_malformed_record;
    const client_finished_record_len = tls_record_header_len + finished_header.fragment_len;
    if (flight.len < pos + client_finished_record_len) return stream_result_would_block;
    const client_finished_record = flight[pos .. pos + client_finished_record_len];

    const shared_secret = X25519.scalarmult(state.server_secret, client_public) catch return stream_result_integrity_failed;
    if (allZero(shared_secret[0..])) return stream_result_integrity_failed;
    const keys = deriveTls12SessionKeys(shared_secret, state.client_random, state.server_random);
    if (allZero(keys.master[0..]) or allZero(keys.client_key[0..]) or allZero(keys.server_key[0..])) return stream_result_integrity_failed;

    var transcript: [tls12_live_max_transcript_len]u8 = .{0} ** tls12_live_max_transcript_len;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, state.transcript)) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, flight[tls_record_header_len..client_key_record_len])) return stream_result_buffer_small;

    var client_transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &client_transcript_hash, .{});

    var client_open_req: [tls12_record_open_header_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls12_record_open_header_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    if (tls12_record_open_header_len + client_finished_record.len > client_open_req.len) return stream_result_buffer_small;
    @memcpy(client_open_req[0..4], magic_record_open_in);
    writeBe64(client_open_req[4..12], 0);
    @memcpy(client_open_req[12..16], keys.client_iv[0..]);
    @memcpy(client_open_req[16..32], keys.client_key[0..]);
    @memcpy(client_open_req[tls12_record_open_header_len .. tls12_record_open_header_len + client_finished_record.len], client_finished_record);
    var opened_client_finished: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    var client_open_in = r4os.abi.ProtocolBuffer{
        .data = &client_open_req,
        .len = @intCast(tls12_record_open_header_len + client_finished_record.len),
        .capacity = client_open_req.len,
    };
    var client_open_out = r4os.abi.ProtocolBuffer{
        .data = &opened_client_finished,
        .len = 0,
        .capacity = opened_client_finished.len,
    };
    if (tls12OpenRecordDispatch(&client_open_in, &client_open_out) != stream_result_ok) return stream_result_integrity_failed;
    const opened_client_finished_len: usize = @intCast(client_open_out.len);
    if (!verifyTls12Finished(opened_client_finished[0..opened_client_finished_len], keys.master[0..], "client finished", client_transcript_hash[0..])) return stream_result_integrity_failed;

    if (!appendBytesChecked(transcript[0..], &transcript_len, opened_client_finished[0..opened_client_finished_len])) return stream_result_buffer_small;
    var server_transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &server_transcript_hash, .{});

    var server_finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const server_finished_plain_len = buildTls12FinishedMessage(server_finished_plain[0..], keys.master[0..], "server finished", server_transcript_hash[0..]) orelse return stream_result_buffer_small;

    var server_protect_req: [tls12_record_protect_header_len + tls12_finished_message_len]u8 = .{0} ** (tls12_record_protect_header_len + tls12_finished_message_len);
    @memcpy(server_protect_req[0..4], magic_record_protect_in);
    writeBe64(server_protect_req[4..12], 0);
    server_protect_req[12] = tls_content_handshake;
    @memcpy(server_protect_req[13..17], keys.server_iv[0..]);
    @memcpy(server_protect_req[17..33], keys.server_key[0..]);
    @memcpy(server_protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + server_finished_plain_len], server_finished_plain[0..server_finished_plain_len]);
    var server_finished_record: [tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    var server_protect_in = r4os.abi.ProtocolBuffer{
        .data = &server_protect_req,
        .len = @intCast(tls12_record_protect_header_len + server_finished_plain_len),
        .capacity = server_protect_req.len,
    };
    var server_protect_out = r4os.abi.ProtocolBuffer{
        .data = &server_finished_record,
        .len = 0,
        .capacity = server_finished_record.len,
    };
    if (tls12ProtectRecordDispatch(&server_protect_in, &server_protect_out) != stream_result_ok) return stream_result_integrity_failed;
    const server_finished_record_len: usize = @intCast(server_protect_out.len);

    var server_flight: [tls12_ccs_record_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls12_ccs_record_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    const server_ccs_len = buildChangeCipherSpecRecord(server_flight[0..]) orelse return stream_result_buffer_small;
    @memcpy(server_flight[server_ccs_len .. server_ccs_len + server_finished_record_len], server_finished_record[0..server_finished_record_len]);
    const server_flight_len = server_ccs_len + server_finished_record_len;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_live_header_len + tls12_live_stream_state_len + server_flight_len) return stream_result_buffer_small;
    const stream_state_offset = tls12_live_header_len;
    const stream_state_len = writeTls12LiveStreamState(out[stream_state_offset..], keys) orelse return stream_result_buffer_small;
    const server_flight_offset = stream_state_offset + stream_state_len;
    @memcpy(out[server_flight_offset .. server_flight_offset + server_flight_len], server_flight[0..server_flight_len]);
    @memcpy(out[0..4], magic_tls12_live_finish_out);
    writeBe32(out[4..8], @intCast(stream_state_len));
    writeBe32(out[8..12], @intCast(server_flight_len));
    out_buffer.len = @intCast(server_flight_offset + server_flight_len);
    return stream_result_ok;
}

fn tls12AppWriteDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_app_io_header_len or !startsWith(input, magic_tls12_app_write_in)) return stream_result_malformed_record;
    const stream_bytes = input[4..tls12_app_io_header_len];
    const stream = parseTls12LiveStreamState(stream_bytes) orelse return stream_result_malformed_record;
    const plain = input[tls12_app_io_header_len..];
    if (plain.len > tls_max_fragment_len) return stream_result_malformed_record;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_app_io_header_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_app_write_out);
    if (!writeUpdatedTls12LiveStreamState(out[4..], stream_bytes, stream.client_sequence, stream.server_sequence +% 1)) return stream_result_buffer_small;

    var protect_req: [tls12_record_protect_header_len + tls_max_fragment_len]u8 = .{0} ** (tls12_record_protect_header_len + tls_max_fragment_len);
    @memcpy(protect_req[0..4], magic_record_protect_in);
    writeBe64(protect_req[4..12], stream.server_sequence);
    protect_req[12] = tls_content_application_data;
    @memcpy(protect_req[13..17], stream.server_iv);
    @memcpy(protect_req[17..33], stream.server_key);
    if (plain.len != 0) @memcpy(protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + plain.len], plain);
    var protect_in = r4os.abi.ProtocolBuffer{
        .data = &protect_req,
        .len = @intCast(tls12_record_protect_header_len + plain.len),
        .capacity = protect_req.len,
    };
    var protect_out = r4os.abi.ProtocolBuffer{
        .data = out[tls12_app_io_header_len..].ptr,
        .len = 0,
        .capacity = @intCast(out.len - tls12_app_io_header_len),
    };
    const rc = tls12ProtectRecordDispatch(&protect_in, &protect_out);
    if (rc != stream_result_ok) return rc;
    out_buffer.len = @intCast(tls12_app_io_header_len + @as(usize, @intCast(protect_out.len)));
    return stream_result_ok;
}

fn tls12AppReadDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_app_io_header_len or !startsWith(input, magic_tls12_app_read_in)) return stream_result_malformed_record;
    const stream_bytes = input[4..tls12_app_io_header_len];
    const stream = parseTls12LiveStreamState(stream_bytes) orelse return stream_result_malformed_record;
    const record_bytes = input[tls12_app_io_header_len..];
    if (record_bytes.len < tls_record_header_len) return stream_result_would_block;
    const record = recordHeader(record_bytes) orelse return stream_result_malformed_record;
    if (record.content_type != tls_content_application_data) return stream_result_unsupported_record;
    const record_len = tls_record_header_len + record.fragment_len;
    if (record_bytes.len < record_len) return stream_result_would_block;
    if (record_bytes.len != record_len) return stream_result_malformed_record;
    if (record_len > tls_record_header_len + tls_max_record_fragment_len) return stream_result_malformed_record;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_app_io_header_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_app_read_out);
    if (!writeUpdatedTls12LiveStreamState(out[4..], stream_bytes, stream.client_sequence +% 1, stream.server_sequence)) return stream_result_buffer_small;

    var open_req: [tls12_record_open_header_len + tls_record_header_len + tls_max_record_fragment_len]u8 = .{0} ** (tls12_record_open_header_len + tls_record_header_len + tls_max_record_fragment_len);
    @memcpy(open_req[0..4], magic_record_open_in);
    writeBe64(open_req[4..12], stream.client_sequence);
    @memcpy(open_req[12..16], stream.client_iv);
    @memcpy(open_req[16..32], stream.client_key);
    @memcpy(open_req[tls12_record_open_header_len .. tls12_record_open_header_len + record_len], record_bytes[0..record_len]);
    var open_in = r4os.abi.ProtocolBuffer{
        .data = &open_req,
        .len = @intCast(tls12_record_open_header_len + record_len),
        .capacity = open_req.len,
    };
    var open_out = r4os.abi.ProtocolBuffer{
        .data = out[tls12_app_io_header_len..].ptr,
        .len = 0,
        .capacity = @intCast(out.len - tls12_app_io_header_len),
    };
    const rc = tls12OpenRecordDispatch(&open_in, &open_out);
    if (rc != stream_result_ok) return rc;
    out_buffer.len = @intCast(tls12_app_io_header_len + @as(usize, @intCast(open_out.len)));
    return stream_result_ok;
}

fn describeTls12ClientContract(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    var text: [768]u8 = .{0} ** 768;
    var pos: usize = 0;
    appendText(text[0..], &pos, "tls12-client-contract;begin=op27:R4CB->R4CH;server-flight=op28:R4CF->R4CQ;finish=op29:R4CE->R4CT");
    appendText(text[0..], &pos, ";app-write=op30:R4CW->R4CX;app-read=op31:R4CR->R4CY");
    appendText(text[0..], &pos, ";cipher=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256");
    appendText(text[0..], &pos, ";x509=chain+validity+hostname+rsa-sha256+ecdsa-p256-p384-sha256-sha384");
    appendText(text[0..], &pos, ";root_path=");
    appendText(text[0..], &pos, root_cert_path);
    appendText(text[0..], &pos, ";root_loaded=");
    appendText(text[0..], &pos, boolText(system_root_loaded));
    appendText(text[0..], &pos, ";root_status=");
    appendText(text[0..], &pos, materialStatusName(system_root_status));
    return writeOut(out_buffer, text[0..pos]);
}

fn tls12ClientBeginDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_client_begin_header_len or !startsWith(input, magic_tls12_client_begin_in)) return stream_result_malformed_record;
    var secret: [tls_pre_master_len]u8 = undefined;
    @memcpy(secret[0..], input[4 .. 4 + tls_pre_master_len]);
    if (allZero(secret[0..])) return stream_result_integrity_failed;
    const now_utc = readBe64(input[4 + tls_pre_master_len .. 4 + tls_pre_master_len + 8]);
    const hostname_len = readBe16(input[4 + tls_pre_master_len + 8 .. tls12_client_begin_header_len]);
    if (hostname_len == 0 or hostname_len > tls12_client_max_hostname_len or input.len != tls12_client_begin_header_len + hostname_len) return stream_result_malformed_record;
    const hostname = input[tls12_client_begin_header_len..];

    var random_seed: [tls_pre_master_len + 8 + tls12_client_max_hostname_len]u8 = .{0} ** (tls_pre_master_len + 8 + tls12_client_max_hostname_len);
    @memcpy(random_seed[0..tls_pre_master_len], secret[0..]);
    writeBe64(random_seed[tls_pre_master_len .. tls_pre_master_len + 8], now_utc);
    @memcpy(random_seed[tls_pre_master_len + 8 .. tls_pre_master_len + 8 + hostname.len], hostname);
    var client_random: [tls_random_len]u8 = undefined;
    Sha256.hash(random_seed[0 .. tls_pre_master_len + 8 + hostname.len], &client_random, .{});
    var hello: [768]u8 = .{0} ** 768;
    const hello_len = buildTls12ClientHello(hello[0..], hostname, client_random) orelse return stream_result_buffer_small;
    const hello_header = recordHeader(hello[0..hello_len]) orelse return stream_result_malformed_record;
    const transcript = hello[tls_record_header_len .. tls_record_header_len + hello_header.fragment_len];

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_client_result_header_len) return stream_result_buffer_small;
    const state_offset = tls12_client_result_header_len;
    const state_len = writeTls12ClientState(out[state_offset..], now_utc, hostname, secret, client_random, transcript) orelse return stream_result_buffer_small;
    const hello_offset = state_offset + state_len;
    if (hello_offset + hello_len > out.len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_client_begin_out);
    writeBe32(out[4..8], @intCast(state_len));
    writeBe32(out[8..12], @intCast(hello_len));
    @memcpy(out[hello_offset .. hello_offset + hello_len], hello[0..hello_len]);
    out_buffer.len = @intCast(hello_offset + hello_len);
    return stream_result_ok;
}

fn tls12ClientServerFlightDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    ensureSystemTlsMaterialLoaded();
    const input = inputBytes(in_buffer) orelse return clientFlightFailure("R4TLS client flight: invalid protocol buffer", -21);
    if (input.len < tls12_client_result_header_len or !startsWith(input, magic_tls12_client_flight_in)) return clientFlightFailure("R4TLS client flight: invalid input header", -22);
    const state_len = readBe32(input[4..8]);
    const flight_len = readBe32(input[8..12]);
    if (state_len == 0) return clientFlightFailure("R4TLS client flight: zero client-state length", -23);
    if (flight_len == 0) return clientFlightFailure("R4TLS client flight: zero server-flight length", -25);
    const declared_len = tls12_client_result_header_len + state_len + flight_len;
    if (input.len < declared_len) return clientFlightFailure("R4TLS client flight: declared lengths exceed input", -26);
    if (input.len > declared_len) return clientFlightFailure("R4TLS client flight: trailing input beyond declared lengths", -27);
    const state_bytes = input[tls12_client_result_header_len .. tls12_client_result_header_len + state_len];
    const state = parseTls12ClientState(state_bytes) orelse return clientFlightFailure("R4TLS client flight: invalid serialized client state", -24);
    const flight = input[tls12_client_result_header_len + state_len ..];
    const server = parseTls12ServerFlight(flight) catch |err| return switch (err) {
        error.RecordHeaderInvalid => clientFlightFailure("R4TLS client flight: invalid record header", -31),
        error.MessageFramingInvalid => clientFlightFailure("R4TLS client flight: invalid message framing", -32),
        error.ServerHelloInvalid => clientFlightFailure("R4TLS client flight: invalid ServerHello", -33),
        error.CertificateListInvalid => clientFlightFailure("R4TLS client flight: invalid certificate list", -34),
        error.ServerKeyExchangeInvalid => clientFlightFailure("R4TLS client flight: invalid ServerKeyExchange", -35),
        error.ServerHelloDoneInvalid => clientFlightFailure("R4TLS client flight: invalid ServerHelloDone", -36),
        error.UnexpectedMessage => clientFlightFailure("R4TLS client flight: unexpected handshake message", -37),
        error.IncompleteFlight => clientFlightFailure("R4TLS client flight: incomplete handshake", -38),
    };
    var x509_failure: X509ValidationFailure = .none;
    const leaf = validateX509Chain(server.certificates, server.certificate_count, state.hostname, state.now_utc, &x509_failure) orelse return switch (x509_failure) {
        .material => clientFlightFailure("R4TLS client flight: certificate material unavailable", -41),
        .clock => clientFlightFailure("R4TLS client flight: certificate clock invalid", -42),
        .parse => clientFlightFailure("R4TLS client flight: certificate parse failed", -43),
        .hostname => clientFlightFailure("R4TLS client flight: certificate hostname rejected", -44),
        .validity => clientFlightFailure("R4TLS client flight: certificate validity rejected", -45),
        .chain => clientFlightFailure("R4TLS client flight: certificate chain signature rejected", -46),
        .root, .none => clientFlightFailure("R4TLS client flight: certificate root rejected", -47),
    };

    var signed_input: [tls_random_len + tls_random_len + 4 + tls_ec_public_max_len]u8 = undefined;
    @memcpy(signed_input[0..tls_random_len], state.client_random[0..]);
    @memcpy(signed_input[tls_random_len .. tls_random_len * 2], server.server_random[0..]);
    if (server.signed_params.len > signed_input.len - tls_random_len * 2) return stream_result_malformed_record;
    @memcpy(signed_input[tls_random_len * 2 .. tls_random_len * 2 + server.signed_params.len], server.signed_params);
    const signed_bytes = signed_input[0 .. tls_random_len * 2 + server.signed_params.len];
    switch (server.signature_scheme) {
        tls_signature_rsa_pkcs1_sha256 => {
            if (leaf.pub_key_algo != .rsaEncryption) return stream_result_material_invalid;
            const key_parts = std.crypto.Certificate.rsa.PublicKey.parseDer(leaf.pubKey()) catch return stream_result_material_invalid;
            const key = RsaKeyContext.fromPublicKey(key_parts.modulus, key_parts.exponent) orelse return stream_result_material_invalid;
            if (!rsaPkcs1Sha256Verify(&key, signed_bytes, server.signature)) return stream_result_integrity_failed;
        },
        tls_signature_ecdsa_secp384r1_sha384, tls_signature_ecdsa_secp256r1_sha256 => {
            // In TLS 1.2 these values select ECDSA plus a hash algorithm. They
            // do not require the certificate key to use the curve named by
            // the later TLS 1.3 scheme spelling. OpenSSL may therefore select
            // SHA-384 for a valid P-256 certificate.
            const verified = verifyTls12EcdsaSignature(leaf, server.signature_scheme, signed_bytes, server.signature) orelse return stream_result_material_invalid;
            if (!verified) return stream_result_integrity_failed;
        },
        else => return stream_result_unsupported_record,
    }

    var shared_secret: [tls_pre_master_len]u8 = undefined;
    var client_public: [tls_ec_public_max_len]u8 = .{0} ** tls_ec_public_max_len;
    const client_public_len: usize = switch (server.named_group) {
        tls_named_group_x25519 => block: {
            if (server.server_public_len != X25519.public_length) return stream_result_malformed_record;
            const server_x25519: [X25519.public_length]u8 = server.server_public[0..X25519.public_length].*;
            shared_secret = X25519.scalarmult(state.secret, server_x25519) catch return stream_result_integrity_failed;
            const public = X25519.recoverPublicKey(state.secret) catch return stream_result_integrity_failed;
            @memcpy(client_public[0..X25519.public_length], public[0..]);
            break :block X25519.public_length;
        },
        tls_named_group_secp256r1 => block: {
            if (server.server_public_len != tls_ec_public_max_len) return stream_result_malformed_record;
            const server_point = P256.fromSec1(server.server_public[0..server.server_public_len]) catch return stream_result_integrity_failed;
            const shared_point = server_point.mul(state.secret, .big) catch return stream_result_integrity_failed;
            shared_secret = shared_point.affineCoordinates().x.toBytes(.big);
            const public_point = P256.basePoint.mul(state.secret, .big) catch return stream_result_integrity_failed;
            const public = public_point.toUncompressedSec1();
            @memcpy(client_public[0..public.len], public[0..]);
            break :block public.len;
        },
        else => return stream_result_unsupported_record,
    };
    if (allZero(shared_secret[0..])) return stream_result_integrity_failed;
    var client_key_record: [96]u8 = .{0} ** 96;
    const client_key_len = buildClientKeyExchangeRecord(client_key_record[0..], client_public[0..client_public_len]) orelse return stream_result_buffer_small;
    const client_key_header = recordHeader(client_key_record[0..client_key_len]) orelse return stream_result_malformed_record;

    var transcript: [tls12_live_max_transcript_len]u8 = .{0} ** tls12_live_max_transcript_len;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, state.transcript)) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, server.fragment)) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, client_key_record[tls_record_header_len .. tls_record_header_len + client_key_header.fragment_len])) return stream_result_buffer_small;
    var transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &transcript_hash, .{});
    const keys = if (server.extended_master_secret)
        deriveTls12ExtendedSessionKeys(shared_secret, transcript_hash, state.client_random, server.server_random)
    else
        deriveTls12SessionKeys(shared_secret, state.client_random, server.server_random);
    var finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const finished_plain_len = buildTls12FinishedMessage(finished_plain[0..], keys.master[0..], "client finished", transcript_hash[0..]) orelse return stream_result_buffer_small;

    var protect_req: [tls12_record_protect_header_len + tls12_finished_message_len]u8 = .{0} ** (tls12_record_protect_header_len + tls12_finished_message_len);
    @memcpy(protect_req[0..4], magic_record_protect_in);
    writeBe64(protect_req[4..12], 0);
    protect_req[12] = tls_content_handshake;
    @memcpy(protect_req[13..17], keys.client_iv[0..]);
    @memcpy(protect_req[17..33], keys.client_key[0..]);
    @memcpy(protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + finished_plain_len], finished_plain[0..finished_plain_len]);
    var finished_record: [64]u8 = .{0} ** 64;
    var protect_in = r4os.abi.ProtocolBuffer{ .data = &protect_req, .len = @intCast(tls12_record_protect_header_len + finished_plain_len), .capacity = protect_req.len };
    var protect_out = r4os.abi.ProtocolBuffer{ .data = &finished_record, .len = 0, .capacity = finished_record.len };
    if (tls12ProtectRecordDispatch(&protect_in, &protect_out) != stream_result_ok) return stream_result_integrity_failed;
    const finished_record_len: usize = @intCast(protect_out.len);

    if (!appendBytesChecked(transcript[0..], &transcript_len, finished_plain[0..finished_plain_len])) return stream_result_buffer_small;
    var stream_state: [tls12_live_stream_state_len]u8 = .{0} ** tls12_live_stream_state_len;
    if (writeTls12ClientStreamState(stream_state[0..], keys, server.certificate, 1, 0) == null) return stream_result_buffer_small;
    var ready_state: [tls12_client_ready_header_len + tls12_live_max_transcript_len]u8 = .{0} ** (tls12_client_ready_header_len + tls12_live_max_transcript_len);
    const ready_len = writeTls12ClientReadyState(ready_state[0..], stream_state[0..], transcript[0..transcript_len]) orelse return stream_result_buffer_small;

    var client_flight: [64 + tls12_ccs_record_len + 64]u8 = .{0} ** (64 + tls12_ccs_record_len + 64);
    var client_flight_len: usize = 0;
    if (!appendBytesChecked(client_flight[0..], &client_flight_len, client_key_record[0..client_key_len])) return stream_result_buffer_small;
    const ccs_len = buildChangeCipherSpecRecord(client_flight[client_flight_len..]) orelse return stream_result_buffer_small;
    client_flight_len += ccs_len;
    if (!appendBytesChecked(client_flight[0..], &client_flight_len, finished_record[0..finished_record_len])) return stream_result_buffer_small;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_client_result_header_len + ready_len + client_flight_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_client_flight_out);
    writeBe32(out[4..8], @intCast(ready_len));
    writeBe32(out[8..12], @intCast(client_flight_len));
    @memcpy(out[tls12_client_result_header_len .. tls12_client_result_header_len + ready_len], ready_state[0..ready_len]);
    @memcpy(out[tls12_client_result_header_len + ready_len .. tls12_client_result_header_len + ready_len + client_flight_len], client_flight[0..client_flight_len]);
    out_buffer.len = @intCast(tls12_client_result_header_len + ready_len + client_flight_len);
    return stream_result_ok;
}

fn clientFlightFailure(comptime message: [:0]const u8, rc: i32) i32 {
    if (protocol_api) |api| {
        var ctx = r4os.r4dev.ProtocolContext2.init(api);
        ctx.logError(message);
    }
    return rc;
}

fn tls12ClientFinishDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_client_result_header_len or !startsWith(input, magic_tls12_client_finish_in)) return stream_result_malformed_record;
    const state_len = readBe32(input[4..8]);
    const flight_len = readBe32(input[8..12]);
    if (state_len == 0 or flight_len == 0 or input.len != tls12_client_result_header_len + state_len + flight_len) return stream_result_malformed_record;
    const ready = parseTls12ClientReadyState(input[tls12_client_result_header_len .. tls12_client_result_header_len + state_len]) orelse return stream_result_malformed_record;
    const stream = parseTls12LiveStreamState(ready.stream_state) orelse return stream_result_malformed_record;
    const flight = input[tls12_client_result_header_len + state_len ..];
    var transcript: [tls12_live_max_transcript_len]u8 = .{0} ** tls12_live_max_transcript_len;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, ready.transcript)) return stream_result_buffer_small;
    const post_client_start = transcript_len;
    var flight_pos: usize = 0;
    var saw_change_cipher_spec = false;
    while (flight_pos < flight.len) {
        const header = recordHeader(flight[flight_pos..]) orelse return stream_result_malformed_record;
        const current_len = tls_record_header_len + header.fragment_len;
        if (current_len > flight.len - flight_pos) return stream_result_malformed_record;
        const current = flight[flight_pos .. flight_pos + current_len];
        if (header.content_type == tls_content_handshake and !saw_change_cipher_spec) {
            if (!appendBytesChecked(transcript[0..], &transcript_len, current[tls_record_header_len..])) return stream_result_buffer_small;
            flight_pos += current_len;
            continue;
        }
        if (!saw_change_cipher_spec and isChangeCipherSpecRecord(current)) {
            saw_change_cipher_spec = true;
            flight_pos += current_len;
            break;
        }
        return stream_result_malformed_record;
    }
    if (!saw_change_cipher_spec or !validatePostClientHandshakeMessages(transcript[post_client_start..transcript_len])) return stream_result_malformed_record;
    const record_bytes = flight[flight_pos..];
    const header = recordHeader(record_bytes) orelse return stream_result_malformed_record;
    const record_len = tls_record_header_len + header.fragment_len;
    if (record_len != record_bytes.len or header.content_type != tls_content_handshake) return stream_result_malformed_record;

    var open_req: [tls12_record_open_header_len + 64]u8 = .{0} ** (tls12_record_open_header_len + 64);
    if (tls12_record_open_header_len + record_len > open_req.len) return stream_result_buffer_small;
    @memcpy(open_req[0..4], magic_record_open_in);
    writeBe64(open_req[4..12], 0);
    @memcpy(open_req[12..16], stream.server_iv);
    @memcpy(open_req[16..32], stream.server_key);
    @memcpy(open_req[tls12_record_open_header_len .. tls12_record_open_header_len + record_len], record_bytes);
    var finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    var open_in = r4os.abi.ProtocolBuffer{ .data = &open_req, .len = @intCast(tls12_record_open_header_len + record_len), .capacity = open_req.len };
    var open_out = r4os.abi.ProtocolBuffer{ .data = &finished_plain, .len = 0, .capacity = finished_plain.len };
    if (tls12OpenRecordDispatch(&open_in, &open_out) != stream_result_ok) return stream_result_integrity_failed;
    var transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &transcript_hash, .{});
    if (!verifyTls12Finished(finished_plain[0..@intCast(open_out.len)], stream.master, "server finished", transcript_hash[0..])) return stream_result_integrity_failed;

    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < 4 + tls12_live_stream_state_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_client_finish_out);
    if (!writeUpdatedTls12LiveStreamState(out[4..], ready.stream_state, stream.client_sequence, 1)) return stream_result_buffer_small;
    out_buffer.len = @intCast(4 + tls12_live_stream_state_len);
    return stream_result_ok;
}

fn validatePostClientHandshakeMessages(fragment: []const u8) bool {
    var pos: usize = 0;
    while (pos < fragment.len) {
        if (fragment.len - pos < 4 or fragment[pos] != tls_handshake_new_session_ticket) return false;
        const body_len = readBe24(fragment[pos + 1 .. pos + 4]);
        if (body_len < 6 or body_len > fragment.len - pos - 4) return false;
        const body = fragment[pos + 4 .. pos + 4 + body_len];
        const ticket_len = readBe16(body[4..6]);
        if (body_len != 6 + ticket_len) return false;
        pos += 4 + body_len;
    }
    return true;
}

fn tls12ClientAppWriteDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_app_io_header_len or !startsWith(input, magic_tls12_client_app_write_in)) return stream_result_malformed_record;
    const stream_bytes = input[4..tls12_app_io_header_len];
    const stream = parseTls12LiveStreamState(stream_bytes) orelse return stream_result_malformed_record;
    const plain = input[tls12_app_io_header_len..];
    if (plain.len > tls_max_fragment_len) return stream_result_malformed_record;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_app_io_header_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_client_app_write_out);
    if (!writeUpdatedTls12LiveStreamState(out[4..], stream_bytes, stream.client_sequence +% 1, stream.server_sequence)) return stream_result_buffer_small;
    var protect_req: [tls12_record_protect_header_len + tls_max_fragment_len]u8 = .{0} ** (tls12_record_protect_header_len + tls_max_fragment_len);
    @memcpy(protect_req[0..4], magic_record_protect_in);
    writeBe64(protect_req[4..12], stream.client_sequence);
    protect_req[12] = tls_content_application_data;
    @memcpy(protect_req[13..17], stream.client_iv);
    @memcpy(protect_req[17..33], stream.client_key);
    if (plain.len > 0) @memcpy(protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + plain.len], plain);
    var protect_in = r4os.abi.ProtocolBuffer{ .data = &protect_req, .len = @intCast(tls12_record_protect_header_len + plain.len), .capacity = protect_req.len };
    var protect_out = r4os.abi.ProtocolBuffer{ .data = out[tls12_app_io_header_len..].ptr, .len = 0, .capacity = @intCast(out.len - tls12_app_io_header_len) };
    const rc = tls12ProtectRecordDispatch(&protect_in, &protect_out);
    if (rc != stream_result_ok) return rc;
    out_buffer.len = @intCast(tls12_app_io_header_len + @as(usize, @intCast(protect_out.len)));
    return stream_result_ok;
}

fn tls12ClientAppReadDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len < tls12_app_io_header_len or !startsWith(input, magic_tls12_client_app_read_in)) return stream_result_malformed_record;
    const stream_bytes = input[4..tls12_app_io_header_len];
    const stream = parseTls12LiveStreamState(stream_bytes) orelse return stream_result_malformed_record;
    const record_bytes = input[tls12_app_io_header_len..];
    const header = recordHeader(record_bytes) orelse return stream_result_would_block;
    const record_len = tls_record_header_len + header.fragment_len;
    if (record_len != record_bytes.len or (header.content_type != tls_content_application_data and header.content_type != tls_content_alert)) return stream_result_malformed_record;
    const out = outputBytes(out_buffer) orelse return stream_result_bad_buffer;
    if (out.len < tls12_app_io_header_len) return stream_result_buffer_small;
    @memcpy(out[0..4], magic_tls12_client_app_read_out);
    if (!writeUpdatedTls12LiveStreamState(out[4..], stream_bytes, stream.client_sequence, stream.server_sequence +% 1)) return stream_result_buffer_small;
    var open_req: [tls12_record_open_header_len + tls_record_header_len + tls_max_record_fragment_len]u8 = .{0} ** (tls12_record_open_header_len + tls_record_header_len + tls_max_record_fragment_len);
    @memcpy(open_req[0..4], magic_record_open_in);
    writeBe64(open_req[4..12], stream.server_sequence);
    @memcpy(open_req[12..16], stream.server_iv);
    @memcpy(open_req[16..32], stream.server_key);
    @memcpy(open_req[tls12_record_open_header_len .. tls12_record_open_header_len + record_len], record_bytes);
    var open_in = r4os.abi.ProtocolBuffer{ .data = &open_req, .len = @intCast(tls12_record_open_header_len + record_len), .capacity = open_req.len };
    var open_out = r4os.abi.ProtocolBuffer{ .data = out[tls12_app_io_header_len..].ptr, .len = 0, .capacity = @intCast(out.len - tls12_app_io_header_len) };
    const rc = tls12OpenRecordDispatch(&open_in, &open_out);
    if (rc != stream_result_ok) return rc;
    out_buffer.len = @intCast(tls12_app_io_header_len + @as(usize, @intCast(open_out.len)));
    return stream_result_ok;
}

fn tls12ClientHarnessDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    _ = in_buffer;
    const rc = runTls12ClientHarness();
    if (rc != stream_result_ok) return rc;
    return writeOut(out_buffer, "tls12-client-harness;clienthello=ok;x509=chain+validity+hostname+signature;finished=ok;app-stream=ok;negative=hostname+time+signature");
}

fn buildTls12ClientHello(out: []u8, hostname: []const u8, client_random: [tls_random_len]u8) ?usize {
    if (hostname.len == 0 or hostname.len > tls12_client_max_hostname_len or out.len < 256 + hostname.len) return null;
    var pos: usize = 0;
    out[pos] = tls_content_handshake;
    pos += 1;
    out[pos] = tls_version_major;
    pos += 1;
    out[pos] = tls_version_tls12_minor;
    pos += 1;
    const record_len_pos = pos;
    pos += 2;
    const handshake_start = pos;
    out[pos] = tls_handshake_client_hello;
    pos += 1;
    const handshake_len_pos = pos;
    pos += 3;
    const body_start = pos;
    writeBe16(out[pos .. pos + 2], 0x0303);
    pos += 2;
    @memcpy(out[pos .. pos + tls_random_len], client_random[0..]);
    pos += tls_random_len;
    out[pos] = 0;
    pos += 1;
    writeBe16(out[pos .. pos + 2], 4);
    pos += 2;
    writeBe16(out[pos .. pos + 2], tls_cipher_ecdhe_ecdsa_aes_128_gcm_sha256);
    pos += 2;
    writeBe16(out[pos .. pos + 2], tls_cipher_ecdhe_rsa_aes_128_gcm_sha256);
    pos += 2;
    out[pos] = 1;
    pos += 1;
    out[pos] = 0;
    pos += 1;
    const extensions_len_pos = pos;
    pos += 2;
    const extensions_start = pos;
    pos = appendExtension(out, pos, ext_extended_master_secret, "");
    pos = appendExtension(out, pos, ext_session_ticket, "");
    pos = appendExtension(out, pos, ext_renegotiation_info, &[_]u8{0});
    pos = appendExtension(out, pos, ext_supported_groups, &[_]u8{ 0, 4, 0, 29, 0, 23 });
    pos = appendExtension(out, pos, ext_ec_point_formats, &[_]u8{ 1, 0 });
    pos = appendExtension(out, pos, ext_signature_algorithms, &[_]u8{ 0, 6, 5, 3, 4, 3, 4, 1 });
    var sni: [5 + tls12_client_max_hostname_len]u8 = .{0} ** (5 + tls12_client_max_hostname_len);
    writeBe16(sni[0..2], @intCast(3 + hostname.len));
    sni[2] = 0;
    writeBe16(sni[3..5], @intCast(hostname.len));
    @memcpy(sni[5 .. 5 + hostname.len], hostname);
    pos = appendExtension(out, pos, ext_server_name, sni[0 .. 5 + hostname.len]);
    pos = appendExtension(out, pos, ext_alpn, &[_]u8{ 0, 9, 8, 'h', 't', 't', 'p', '/', '1', '.', '1' });
    writeBe16(out[extensions_len_pos .. extensions_len_pos + 2], @intCast(pos - extensions_start));
    writeBe24(out[handshake_len_pos .. handshake_len_pos + 3], @intCast(pos - body_start));
    writeBe16(out[record_len_pos .. record_len_pos + 2], @intCast(pos - handshake_start));
    return pos;
}

fn writeTls12ClientState(out: []u8, now_utc: u64, hostname: []const u8, secret: [tls_pre_master_len]u8, client_random: [tls_random_len]u8, transcript: []const u8) ?usize {
    const total = tls12_client_state_header_len + hostname.len + transcript.len;
    if (hostname.len > tls12_client_max_hostname_len or transcript.len > tls12_live_max_transcript_len or out.len < total) return null;
    @memcpy(out[0..4], magic_tls12_client_state);
    writeBe64(out[4..12], now_utc);
    writeBe16(out[12..14], @intCast(hostname.len));
    @memcpy(out[14 .. 14 + tls_pre_master_len], secret[0..]);
    @memcpy(out[14 + tls_pre_master_len .. 14 + tls_pre_master_len + tls_random_len], client_random[0..]);
    writeBe32(out[14 + tls_pre_master_len + tls_random_len .. tls12_client_state_header_len], @intCast(transcript.len));
    @memcpy(out[tls12_client_state_header_len .. tls12_client_state_header_len + hostname.len], hostname);
    @memcpy(out[tls12_client_state_header_len + hostname.len .. total], transcript);
    return total;
}

fn parseTls12ClientState(input: []const u8) ?Tls12ClientStateView {
    if (input.len < tls12_client_state_header_len or !startsWith(input, magic_tls12_client_state)) return null;
    const hostname_len = readBe16(input[12..14]);
    const transcript_len = readBe32(input[14 + tls_pre_master_len + tls_random_len .. tls12_client_state_header_len]);
    const total = tls12_client_state_header_len + hostname_len + transcript_len;
    if (hostname_len == 0 or hostname_len > tls12_client_max_hostname_len or transcript_len > tls12_live_max_transcript_len or input.len != total) return null;
    var secret: [tls_pre_master_len]u8 = undefined;
    var client_random: [tls_random_len]u8 = undefined;
    @memcpy(secret[0..], input[14 .. 14 + tls_pre_master_len]);
    @memcpy(client_random[0..], input[14 + tls_pre_master_len .. 14 + tls_pre_master_len + tls_random_len]);
    return .{
        .total_len = total,
        .now_utc = readBe64(input[4..12]),
        .hostname = input[tls12_client_state_header_len .. tls12_client_state_header_len + hostname_len],
        .secret = secret,
        .client_random = client_random,
        .transcript = input[tls12_client_state_header_len + hostname_len .. total],
    };
}

fn writeTls12ClientReadyState(out: []u8, stream_state: []const u8, transcript: []const u8) ?usize {
    if (stream_state.len != tls12_live_stream_state_len or transcript.len > tls12_live_max_transcript_len) return null;
    const total = tls12_client_ready_header_len + transcript.len;
    if (out.len < total) return null;
    @memcpy(out[0..4], magic_tls12_client_state);
    @memcpy(out[4 .. 4 + tls12_live_stream_state_len], stream_state);
    writeBe32(out[4 + tls12_live_stream_state_len .. tls12_client_ready_header_len], @intCast(transcript.len));
    @memcpy(out[tls12_client_ready_header_len..total], transcript);
    return total;
}

fn parseTls12ClientReadyState(input: []const u8) ?Tls12ClientReadyView {
    if (input.len < tls12_client_ready_header_len or !startsWith(input, magic_tls12_client_state)) return null;
    const transcript_len = readBe32(input[4 + tls12_live_stream_state_len .. tls12_client_ready_header_len]);
    const total = tls12_client_ready_header_len + transcript_len;
    if (transcript_len > tls12_live_max_transcript_len or input.len != total) return null;
    return .{
        .total_len = total,
        .stream_state = input[4 .. 4 + tls12_live_stream_state_len],
        .transcript = input[tls12_client_ready_header_len..total],
    };
}

fn writeTls12ClientStreamState(out: []u8, keys: Tls12SessionKeys, certificate: []const u8, client_sequence: u64, server_sequence: u64) ?usize {
    if (out.len < tls12_live_stream_state_len) return null;
    var pos: usize = 0;
    @memcpy(out[pos .. pos + 4], magic_tls12_live_stream);
    pos += 4;
    writeBe64(out[pos .. pos + 8], client_sequence);
    pos += 8;
    writeBe64(out[pos .. pos + 8], server_sequence);
    pos += 8;
    @memcpy(out[pos .. pos + tls_aes_128_key_len], keys.client_key[0..]);
    pos += tls_aes_128_key_len;
    @memcpy(out[pos .. pos + tls_aes_128_key_len], keys.server_key[0..]);
    pos += tls_aes_128_key_len;
    @memcpy(out[pos .. pos + tls_aes_gcm_fixed_iv_len], keys.client_iv[0..]);
    pos += tls_aes_gcm_fixed_iv_len;
    @memcpy(out[pos .. pos + tls_aes_gcm_fixed_iv_len], keys.server_iv[0..]);
    pos += tls_aes_gcm_fixed_iv_len;
    @memcpy(out[pos .. pos + tls_master_secret_len], keys.master[0..]);
    pos += tls_master_secret_len;
    var cert_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(certificate, &cert_hash, .{});
    @memcpy(out[pos .. pos + Sha256.digest_length], cert_hash[0..]);
    pos += Sha256.digest_length;
    return if (pos == tls12_live_stream_state_len) pos else null;
}

fn parseTls12ServerFlight(flight: []const u8) Tls12ServerFlightError!Tls12ServerFlightView {
    const header = recordHeader(flight) orelse return error.RecordHeaderInvalid;
    if (header.content_type != tls_content_handshake or flight.len != tls_record_header_len + header.fragment_len) return error.RecordHeaderInvalid;
    const fragment = flight[tls_record_header_len..];
    var pos: usize = 0;
    var saw_hello = false;
    var saw_certificate = false;
    var saw_ske = false;
    var saw_done = false;
    var extended_master_secret = false;
    var secure_renegotiation = false;
    var server_random: [tls_random_len]u8 = .{0} ** tls_random_len;
    var certificate: []const u8 = "";
    var certificates: [tls_cert_chain_max_count][]const u8 = .{""} ** tls_cert_chain_max_count;
    var certificate_count: usize = 0;
    var named_group: u16 = 0;
    var server_public: [tls_ec_public_max_len]u8 = .{0} ** tls_ec_public_max_len;
    var server_public_len: usize = 0;
    var signed_params: []const u8 = "";
    var signature_scheme: u16 = 0;
    var signature: []const u8 = "";
    while (pos < fragment.len) {
        if (fragment.len - pos < 4) return error.MessageFramingInvalid;
        const kind = fragment[pos];
        const body_len = readBe24(fragment[pos + 1 .. pos + 4]);
        const full_len = 4 + body_len;
        if (full_len > fragment.len - pos) return error.MessageFramingInvalid;
        const body = fragment[pos + 4 .. pos + full_len];
        switch (kind) {
            tls_handshake_server_hello => {
                if (saw_hello or body.len < 38 or readBe16(body[0..2]) != 0x0303) return error.ServerHelloInvalid;
                @memcpy(server_random[0..], body[2 .. 2 + tls_random_len]);
                const session_len: usize = body[34];
                if (35 + session_len + 3 > body.len) return error.ServerHelloInvalid;
                const cipher = readBe16(body[35 + session_len .. 37 + session_len]);
                if ((cipher != tls_cipher_ecdhe_rsa_aes_128_gcm_sha256 and cipher != tls_cipher_ecdhe_ecdsa_aes_128_gcm_sha256) or body[37 + session_len] != 0) return error.ServerHelloInvalid;
                var extension_pos = 38 + session_len;
                if (extension_pos < body.len) {
                    if (body.len - extension_pos < 2) return error.ServerHelloInvalid;
                    const extensions_len: usize = readBe16(body[extension_pos .. extension_pos + 2]);
                    extension_pos += 2;
                    if (extensions_len != body.len - extension_pos) return error.ServerHelloInvalid;
                    const extensions_end = extension_pos + extensions_len;
                    while (extension_pos < extensions_end) {
                        if (extensions_end - extension_pos < 4) return error.ServerHelloInvalid;
                        const extension_type = readBe16(body[extension_pos .. extension_pos + 2]);
                        const extension_len: usize = readBe16(body[extension_pos + 2 .. extension_pos + 4]);
                        extension_pos += 4;
                        if (extension_len > extensions_end - extension_pos) return error.ServerHelloInvalid;
                        if (extension_type == ext_extended_master_secret) {
                            if (extended_master_secret or extension_len != 0) return error.ServerHelloInvalid;
                            extended_master_secret = true;
                        }
                        if (extension_type == ext_renegotiation_info) {
                            if (secure_renegotiation or extension_len != 1 or body[extension_pos] != 0) return error.ServerHelloInvalid;
                            secure_renegotiation = true;
                        }
                        extension_pos += extension_len;
                    }
                }
                if (!secure_renegotiation) return error.ServerHelloInvalid;
                saw_hello = true;
            },
            tls_handshake_certificate => {
                if (saw_certificate or body.len < 6) return error.CertificateListInvalid;
                const list_len = readBe24(body[0..3]);
                if (list_len == 0 or list_len + 3 != body.len) return error.CertificateListInvalid;
                var certificate_pos: usize = 3;
                while (certificate_pos < body.len and certificate_count < tls_cert_chain_max_count) {
                    if (certificate_pos + 3 > body.len) return error.CertificateListInvalid;
                    const cert_len = readBe24(body[certificate_pos .. certificate_pos + 3]);
                    certificate_pos += 3;
                    if (cert_len == 0 or cert_len > tls_peer_cert_max_der_bytes or cert_len > body.len - certificate_pos) return error.CertificateListInvalid;
                    certificates[certificate_count] = body[certificate_pos .. certificate_pos + cert_len];
                    certificate_pos += cert_len;
                    certificate_count += 1;
                }
                if (certificate_pos != body.len or certificate_count == 0) return error.CertificateListInvalid;
                certificate = certificates[0];
                saw_certificate = true;
            },
            tls_handshake_server_key_exchange => {
                if (saw_ske or body.len < 4 + X25519.public_length + 4 or body[0] != 3) return error.ServerKeyExchangeInvalid;
                named_group = @intCast(readBe16(body[1..3]));
                server_public_len = body[3];
                const group_valid = (named_group == tls_named_group_x25519 and server_public_len == X25519.public_length) or
                    (named_group == tls_named_group_secp256r1 and server_public_len == tls_ec_public_max_len);
                if (!group_valid or 4 + server_public_len + 4 > body.len) return error.ServerKeyExchangeInvalid;
                @memcpy(server_public[0..server_public_len], body[4 .. 4 + server_public_len]);
                const params_len = 4 + server_public_len;
                signature_scheme = @intCast(readBe16(body[params_len .. params_len + 2]));
                if (signature_scheme != tls_signature_rsa_pkcs1_sha256 and signature_scheme != tls_signature_ecdsa_secp256r1_sha256 and signature_scheme != tls_signature_ecdsa_secp384r1_sha384) return error.ServerKeyExchangeInvalid;
                const signature_len = readBe16(body[params_len + 2 .. params_len + 4]);
                if (signature_len == 0 or params_len + 4 + signature_len != body.len) return error.ServerKeyExchangeInvalid;
                signed_params = body[0..params_len];
                signature = body[params_len + 4 ..];
                saw_ske = true;
            },
            tls_handshake_server_hello_done => {
                if (saw_done or body.len != 0) return error.ServerHelloDoneInvalid;
                saw_done = true;
            },
            else => return error.UnexpectedMessage,
        }
        pos += full_len;
    }
    if (!saw_hello or !saw_certificate or !saw_ske or !saw_done) return error.IncompleteFlight;
    return .{
        .fragment = fragment,
        .server_random = server_random,
        .extended_master_secret = extended_master_secret,
        .secure_renegotiation = secure_renegotiation,
        .certificate = certificate,
        .certificates = certificates,
        .certificate_count = certificate_count,
        .named_group = named_group,
        .server_public = server_public,
        .server_public_len = server_public_len,
        .signed_params = signed_params,
        .signature_scheme = signature_scheme,
        .signature = signature,
    };
}

fn runTls12ClientHarness() i32 {
    ensureSystemTlsMaterialLoaded();
    if (!system_root_loaded or !system_cert_loaded or !system_key_loaded) return clientHarnessFailure("R4TLS client harness failed: material", stream_result_material_missing);
    if (!selftestP256KeyAgreement()) return clientHarnessFailure("R4TLS client harness failed: P-256 key agreement", stream_result_integrity_failed);
    if (!selftestP256Sha384Signature()) return clientHarnessFailure("R4TLS client harness failed: TLS 1.2 P-256 SHA-384 signature", stream_result_integrity_failed);
    if (!selftestP384Signature()) return clientHarnessFailure("R4TLS client harness failed: P-384 signature", stream_result_integrity_failed);
    const ticket_message = [_]u8{ tls_handshake_new_session_ticket, 0, 0, 7, 0, 0, 0, 60, 0, 1, 0xA5 };
    if (!validatePostClientHandshakeMessages(ticket_message[0..])) return clientHarnessFailure("R4TLS client harness failed: NewSessionTicket framing", stream_result_malformed_record);
    var malformed_ticket = ticket_message;
    malformed_ticket[9] = 2;
    if (validatePostClientHandshakeMessages(malformed_ticket[0..])) return clientHarnessFailure("R4TLS client harness failed: malformed NewSessionTicket accepted", stream_result_integrity_failed);
    const hostname = "R4OS Development TLS";
    var begin_input: [tls12_client_begin_header_len + hostname.len]u8 = .{0} ** (tls12_client_begin_header_len + hostname.len);
    @memcpy(begin_input[0..4], magic_tls12_client_begin_in);
    @memcpy(begin_input[4 .. 4 + tls_pre_master_len], fixture_x25519_secret[0..]);
    writeBe64(begin_input[4 + tls_pre_master_len .. 4 + tls_pre_master_len + 8], 20260730000000);
    writeBe16(begin_input[4 + tls_pre_master_len + 8 .. tls12_client_begin_header_len], hostname.len);
    @memcpy(begin_input[tls12_client_begin_header_len..], hostname);
    var begin_result: [12 + tls12_client_state_header_len + tls12_client_max_hostname_len + 768 + 768]u8 = .{0} ** (12 + tls12_client_state_header_len + tls12_client_max_hostname_len + 768 + 768);
    var begin_in = r4os.abi.ProtocolBuffer{ .data = &begin_input, .len = begin_input.len, .capacity = begin_input.len };
    var begin_out = r4os.abi.ProtocolBuffer{ .data = &begin_result, .len = 0, .capacity = begin_result.len };
    if (tls12ClientBeginDispatch(&begin_in, &begin_out) != stream_result_ok) return clientHarnessFailure("R4TLS client harness failed: client begin", stream_result_malformed_record);
    const begin_bytes = begin_result[0..@intCast(begin_out.len)];
    if (!startsWith(begin_bytes, magic_tls12_client_begin_out)) return stream_result_malformed_record;
    const state_len = readBe32(begin_bytes[4..8]);
    const hello_len = readBe32(begin_bytes[8..12]);
    const state = begin_bytes[12 .. 12 + state_len];
    const hello = begin_bytes[12 + state_len .. 12 + state_len + hello_len];

    var server_begin_result: [tls12_live_header_len + tls12_live_state_header_len + tls12_live_max_transcript_len + 4096]u8 = .{0} ** (tls12_live_header_len + tls12_live_state_header_len + tls12_live_max_transcript_len + 4096);
    var server_begin_in = r4os.abi.ProtocolBuffer{ .data = @ptrCast(@constCast(hello.ptr)), .len = @intCast(hello.len), .capacity = @intCast(hello.len) };
    var server_begin_out = r4os.abi.ProtocolBuffer{ .data = &server_begin_result, .len = 0, .capacity = server_begin_result.len };
    if (tls12LiveBeginDispatch(&server_begin_in, &server_begin_out) != stream_result_ok) return clientHarnessFailure("R4TLS client harness failed: server begin", stream_result_malformed_record);
    const server_begin = server_begin_result[0..@intCast(server_begin_out.len)];
    const server_state_len = readBe32(server_begin[4..8]);
    const server_flight_len = readBe32(server_begin[8..12]);
    const server_state = server_begin[12 .. 12 + server_state_len];
    const server_flight = server_begin[12 + server_state_len .. 12 + server_state_len + server_flight_len];

    var client_flight_input: [12 + tls12_client_state_header_len + tls12_client_max_hostname_len + 768 + 4096]u8 = .{0} ** (12 + tls12_client_state_header_len + tls12_client_max_hostname_len + 768 + 4096);
    @memcpy(client_flight_input[0..4], magic_tls12_client_flight_in);
    writeBe32(client_flight_input[4..8], @intCast(state.len));
    writeBe32(client_flight_input[8..12], @intCast(server_flight.len));
    @memcpy(client_flight_input[12 .. 12 + state.len], state);
    @memcpy(client_flight_input[12 + state.len .. 12 + state.len + server_flight.len], server_flight);
    var client_flight_result: [12 + tls12_client_ready_header_len + tls12_live_max_transcript_len + 256]u8 = .{0} ** (12 + tls12_client_ready_header_len + tls12_live_max_transcript_len + 256);
    var client_flight_in = r4os.abi.ProtocolBuffer{ .data = &client_flight_input, .len = @intCast(12 + state.len + server_flight.len), .capacity = client_flight_input.len };
    var client_flight_out = r4os.abi.ProtocolBuffer{ .data = &client_flight_result, .len = 0, .capacity = client_flight_result.len };
    if (tls12ClientServerFlightDispatch(&client_flight_in, &client_flight_out) != stream_result_ok) return clientHarnessFailure("R4TLS client harness failed: server flight", stream_result_integrity_failed);
    const client_flight_bytes = client_flight_result[0..@intCast(client_flight_out.len)];
    const ready_len = readBe32(client_flight_bytes[4..8]);
    const client_wire_len = readBe32(client_flight_bytes[8..12]);
    const ready_state = client_flight_bytes[12 .. 12 + ready_len];
    const client_wire = client_flight_bytes[12 + ready_len .. 12 + ready_len + client_wire_len];

    var server_finish_input: [tls12_live_state_header_len + tls12_live_max_transcript_len + 256]u8 = .{0} ** (tls12_live_state_header_len + tls12_live_max_transcript_len + 256);
    @memcpy(server_finish_input[0..server_state.len], server_state);
    @memcpy(server_finish_input[server_state.len .. server_state.len + client_wire.len], client_wire);
    var server_finish_result: [512]u8 = .{0} ** 512;
    var server_finish_in = r4os.abi.ProtocolBuffer{ .data = &server_finish_input, .len = @intCast(server_state.len + client_wire.len), .capacity = server_finish_input.len };
    var server_finish_out = r4os.abi.ProtocolBuffer{ .data = &server_finish_result, .len = 0, .capacity = server_finish_result.len };
    if (tls12LiveFinishDispatch(&server_finish_in, &server_finish_out) != stream_result_ok) return clientHarnessFailure("R4TLS client harness failed: server finish", stream_result_integrity_failed);
    const server_finish = server_finish_result[0..@intCast(server_finish_out.len)];
    const server_stream_len = readBe32(server_finish[4..8]);
    const server_final_flight_len = readBe32(server_finish[8..12]);
    const server_stream = server_finish[12 .. 12 + server_stream_len];
    const server_final_flight = server_finish[12 + server_stream_len .. 12 + server_stream_len + server_final_flight_len];

    var client_finish_input: [12 + tls12_client_ready_header_len + tls12_live_max_transcript_len + 128]u8 = .{0} ** (12 + tls12_client_ready_header_len + tls12_live_max_transcript_len + 128);
    @memcpy(client_finish_input[0..4], magic_tls12_client_finish_in);
    writeBe32(client_finish_input[4..8], @intCast(ready_state.len));
    writeBe32(client_finish_input[8..12], @intCast(server_final_flight.len));
    @memcpy(client_finish_input[12 .. 12 + ready_state.len], ready_state);
    @memcpy(client_finish_input[12 + ready_state.len .. 12 + ready_state.len + server_final_flight.len], server_final_flight);
    var client_finish_result: [4 + tls12_live_stream_state_len]u8 = .{0} ** (4 + tls12_live_stream_state_len);
    var client_finish_in = r4os.abi.ProtocolBuffer{ .data = &client_finish_input, .len = @intCast(12 + ready_state.len + server_final_flight.len), .capacity = client_finish_input.len };
    var client_finish_out = r4os.abi.ProtocolBuffer{ .data = &client_finish_result, .len = 0, .capacity = client_finish_result.len };
    if (tls12ClientFinishDispatch(&client_finish_in, &client_finish_out) != stream_result_ok) return clientHarnessFailure("R4TLS client harness failed: client finish", stream_result_integrity_failed);
    const client_stream = client_finish_result[4..@intCast(client_finish_out.len)];
    if (client_stream.len != tls12_live_stream_state_len or server_stream.len != tls12_live_stream_state_len) return stream_result_malformed_record;

    if (validateX509Leaf(system_cert_der[0..system_cert_der_len], "wrong.example", 20260730000000) != null) return clientHarnessFailure("R4TLS client harness failed: hostname negative", stream_result_integrity_failed);
    if (validateX509Leaf(system_cert_der[0..system_cert_der_len], hostname, 20400101000000) != null) return clientHarnessFailure("R4TLS client harness failed: time negative", stream_result_integrity_failed);
    var tampered_certificate: [tls_cert_max_der_bytes]u8 = .{0} ** tls_cert_max_der_bytes;
    @memcpy(tampered_certificate[0..system_cert_der_len], system_cert_der[0..system_cert_der_len]);
    tampered_certificate[system_cert_der_len - 1] ^= 0x01;
    if (validateX509Leaf(tampered_certificate[0..system_cert_der_len], hostname, 20260730000000) != null) return clientHarnessFailure("R4TLS client harness failed: signature negative", stream_result_integrity_failed);
    return stream_result_ok;
}

fn selftestP256KeyAgreement() bool {
    const client_point = P256.basePoint.mul(fixture_x25519_secret, .big) catch return false;
    const server_point = P256.basePoint.mul(fixture_server_secret, .big) catch return false;
    const client_shared = server_point.mul(fixture_x25519_secret, .big) catch return false;
    const server_shared = client_point.mul(fixture_server_secret, .big) catch return false;
    const client_x = client_shared.affineCoordinates().x.toBytes(.big);
    const server_x = server_shared.affineCoordinates().x.toBytes(.big);
    if (!std.mem.eql(u8, client_x[0..], server_x[0..]) or allZero(client_x[0..])) return false;

    const client_public = client_point.toUncompressedSec1();
    var record: [96]u8 = .{0} ** 96;
    const record_len = buildClientKeyExchangeRecord(record[0..], client_public[0..]) orelse return false;
    const parsed = parseClientKeyExchangeRecord(record[0..record_len]) orelse return false;
    return std.mem.eql(u8, parsed, client_public[0..]);
}

fn ecdsaVerify(comptime Curve: type, comptime Hash: type, public_key: []const u8, payload: []const u8, encoded_signature: []const u8) bool {
    const Ecdsa = std.crypto.sign.ecdsa.Ecdsa(Curve, Hash);
    const signature = Ecdsa.Signature.fromDer(encoded_signature) catch return false;
    const key = Ecdsa.PublicKey.fromSec1(public_key) catch return false;
    signature.verify(payload, key) catch return false;
    return true;
}

fn verifyTls12EcdsaSignature(leaf: Certificate.Parsed, signature_scheme: u16, payload: []const u8, encoded_signature: []const u8) ?bool {
    const curve = switch (leaf.pub_key_algo) {
        .X9_62_id_ecPublicKey => |named_curve| named_curve,
        else => return null,
    };
    return verifyTls12EcdsaSignatureForCurve(curve, leaf.pubKey(), signature_scheme, payload, encoded_signature);
}

fn verifyTls12EcdsaSignatureForCurve(curve: Certificate.NamedCurve, public_key: []const u8, signature_scheme: u16, payload: []const u8, encoded_signature: []const u8) ?bool {
    return switch (signature_scheme) {
        tls_signature_ecdsa_secp256r1_sha256 => switch (curve) {
            .X9_62_prime256v1 => ecdsaVerify(P256, Sha256, public_key, payload, encoded_signature),
            .secp384r1 => ecdsaVerify(P384, Sha256, public_key, payload, encoded_signature),
            else => null,
        },
        tls_signature_ecdsa_secp384r1_sha384 => switch (curve) {
            .X9_62_prime256v1 => ecdsaVerify(P256, Sha384, public_key, payload, encoded_signature),
            .secp384r1 => ecdsaVerify(P384, Sha384, public_key, payload, encoded_signature),
            else => null,
        },
        else => null,
    };
}

fn selftestP256Sha384Signature() bool {
    const Ecdsa = std.crypto.sign.ecdsa.Ecdsa(P256, Sha384);
    const seed = [_]u8{0x3c} ** Ecdsa.KeyPair.seed_length;
    const key_pair = Ecdsa.KeyPair.generateDeterministic(seed) catch return false;
    const payload = "R4TLS TLS 1.2 P-256 SHA-384 signature selftest";
    const signature = key_pair.sign(payload, null) catch return false;
    var encoded: [Ecdsa.Signature.der_encoded_length_max]u8 = undefined;
    const der = signature.toDer(&encoded);
    const public_key = key_pair.public_key.toUncompressedSec1();
    if (!(verifyTls12EcdsaSignatureForCurve(.X9_62_prime256v1, public_key[0..], tls_signature_ecdsa_secp384r1_sha384, payload, der) orelse false)) return false;
    encoded[der.len - 1] ^= 1;
    return !(verifyTls12EcdsaSignatureForCurve(.X9_62_prime256v1, public_key[0..], tls_signature_ecdsa_secp384r1_sha384, payload, encoded[0..der.len]) orelse true);
}

fn selftestP384Signature() bool {
    const Ecdsa = std.crypto.sign.ecdsa.EcdsaP384Sha384;
    const seed = [_]u8{0x5a} ** Ecdsa.KeyPair.seed_length;
    const key_pair = Ecdsa.KeyPair.generateDeterministic(seed) catch return false;
    const payload = "R4TLS P-384 SHA-384 signature selftest";
    const signature = key_pair.sign(payload, null) catch return false;
    var encoded: [Ecdsa.Signature.der_encoded_length_max]u8 = undefined;
    const der = signature.toDer(&encoded);
    const public_key = key_pair.public_key.toUncompressedSec1();
    if (!ecdsaVerify(P384, Sha384, public_key[0..], payload, der)) return false;
    encoded[der.len - 1] ^= 1;
    return !ecdsaVerify(P384, Sha384, public_key[0..], payload, encoded[0..der.len]);
}

fn clientHarnessFailure(comptime message: [:0]const u8, rc: i32) i32 {
    if (protocol_api) |api| {
        var ctx = r4os.r4dev.ProtocolContext2.init(api);
        ctx.logError(message);
    }
    return rc;
}

fn runTls12SessionHarness(result: *Tls12SessionHarnessResult) i32 {
    var client_hello: [192]u8 = .{0} ** 192;
    const client_hello_len = buildClientHelloFixture(client_hello[0..]);
    const client_info = parseClientHelloInfo(client_hello[0..client_hello_len]) orelse return stream_result_malformed_record;
    var plan = planServerHandshakeInfo(client_info) catch |err| return serverPlanErrorCode(err);
    defer std.crypto.secureZero(u8, &plan.server_secret);
    const material = getSystemTlsMaterial() orelse return stream_result_material_missing;

    var server_record: [4096]u8 = .{0} ** 4096;
    const server_record_len = buildServerHandshakeRecord(server_record[0..], plan, material) orelse return stream_result_buffer_small;
    const server_header = recordHeader(server_record[0..server_record_len]) orelse return stream_result_malformed_record;
    if (server_header.content_type != tls_content_handshake or server_header.fragment_len + tls_record_header_len != server_record_len) return stream_result_malformed_record;

    var client_key_exchange: [64]u8 = .{0} ** 64;
    const client_key_exchange_len = buildClientKeyExchangeRecord(client_key_exchange[0..], fixture_x25519_public[0..]) orelse return stream_result_buffer_small;
    const parsed_client_public = parseClientKeyExchangeRecord(client_key_exchange[0..client_key_exchange_len]) orelse return stream_result_malformed_record;
    if (!std.mem.eql(u8, parsed_client_public, client_info.key_share_x25519[0..])) return stream_result_malformed_record;
    var client_public: [X25519.public_length]u8 = undefined;
    @memcpy(client_public[0..], parsed_client_public);

    var bad_client_key_exchange = client_key_exchange;
    bad_client_key_exchange[tls_record_header_len + 4] = X25519.public_length - 1;
    if (parseClientKeyExchangeRecord(bad_client_key_exchange[0..client_key_exchange_len]) != null) return stream_result_malformed_record;

    const shared_secret = X25519.scalarmult(plan.server_secret, client_public) catch return stream_result_integrity_failed;
    if (allZero(shared_secret[0..])) return stream_result_integrity_failed;
    const keys = deriveTls12SessionKeys(shared_secret, client_info.client_random, plan.server_random);
    if (allZero(keys.master[0..]) or allZero(keys.client_key[0..]) or allZero(keys.server_key[0..])) return stream_result_integrity_failed;

    var transcript: [8192]u8 = .{0} ** 8192;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, client_hello[tls_record_header_len..client_hello_len])) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, server_record[tls_record_header_len..server_record_len])) return stream_result_buffer_small;
    if (!appendBytesChecked(transcript[0..], &transcript_len, client_key_exchange[tls_record_header_len..client_key_exchange_len])) return stream_result_buffer_small;

    var client_transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &client_transcript_hash, .{});

    var change_cipher_spec: [tls12_ccs_record_len]u8 = .{0} ** tls12_ccs_record_len;
    const ccs_len = buildChangeCipherSpecRecord(change_cipher_spec[0..]) orelse return stream_result_buffer_small;
    if (ccs_len != tls12_ccs_record_len or !isChangeCipherSpecRecord(change_cipher_spec[0..ccs_len])) return stream_result_malformed_record;

    var client_finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const client_finished_plain_len = buildTls12FinishedMessage(client_finished_plain[0..], keys.master[0..], "client finished", client_transcript_hash[0..]) orelse return stream_result_buffer_small;
    var client_verify: [tls12_finished_verify_len]u8 = undefined;
    @memcpy(client_verify[0..], client_finished_plain[4 .. 4 + tls12_finished_verify_len]);

    var client_protect_req: [tls12_record_protect_header_len + tls12_finished_message_len]u8 = .{0} ** (tls12_record_protect_header_len + tls12_finished_message_len);
    @memcpy(client_protect_req[0..4], magic_record_protect_in);
    writeBe64(client_protect_req[4..12], 0);
    client_protect_req[12] = tls_content_handshake;
    @memcpy(client_protect_req[13..17], keys.client_iv[0..]);
    @memcpy(client_protect_req[17..33], keys.client_key[0..]);
    @memcpy(client_protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + client_finished_plain_len], client_finished_plain[0..client_finished_plain_len]);
    var client_finished_record: [tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    var client_protect_in = r4os.abi.ProtocolBuffer{
        .data = &client_protect_req,
        .len = @intCast(tls12_record_protect_header_len + client_finished_plain_len),
        .capacity = client_protect_req.len,
    };
    var client_protect_out = r4os.abi.ProtocolBuffer{
        .data = &client_finished_record,
        .len = 0,
        .capacity = client_finished_record.len,
    };
    if (tls12ProtectRecordDispatch(&client_protect_in, &client_protect_out) != stream_result_ok) return stream_result_integrity_failed;
    const client_finished_record_len: usize = @intCast(client_protect_out.len);

    var client_open_req: [tls12_record_open_header_len + client_finished_record.len]u8 = .{0} ** (tls12_record_open_header_len + client_finished_record.len);
    @memcpy(client_open_req[0..4], magic_record_open_in);
    writeBe64(client_open_req[4..12], 0);
    @memcpy(client_open_req[12..16], keys.client_iv[0..]);
    @memcpy(client_open_req[16..32], keys.client_key[0..]);
    @memcpy(client_open_req[tls12_record_open_header_len .. tls12_record_open_header_len + client_finished_record_len], client_finished_record[0..client_finished_record_len]);
    var opened_client_finished: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    var client_open_in = r4os.abi.ProtocolBuffer{
        .data = &client_open_req,
        .len = @intCast(tls12_record_open_header_len + client_finished_record_len),
        .capacity = client_open_req.len,
    };
    var client_open_out = r4os.abi.ProtocolBuffer{
        .data = &opened_client_finished,
        .len = 0,
        .capacity = opened_client_finished.len,
    };
    if (tls12OpenRecordDispatch(&client_open_in, &client_open_out) != stream_result_ok) return stream_result_integrity_failed;
    const opened_client_finished_len: usize = @intCast(client_open_out.len);
    if (opened_client_finished_len != client_finished_plain_len) return stream_result_malformed_record;
    if (!verifyTls12Finished(opened_client_finished[0..opened_client_finished_len], keys.master[0..], "client finished", client_transcript_hash[0..])) return stream_result_integrity_failed;

    var tampered_client_open_req = client_open_req;
    tampered_client_open_req[tls12_record_open_header_len + client_finished_record_len - 1] ^= 0x5A;
    var tampered_client_open_in = r4os.abi.ProtocolBuffer{
        .data = &tampered_client_open_req,
        .len = @intCast(tls12_record_open_header_len + client_finished_record_len),
        .capacity = tampered_client_open_req.len,
    };
    if (tls12OpenRecordDispatch(&tampered_client_open_in, &client_open_out) != stream_result_integrity_failed) return stream_result_integrity_failed;

    var bad_transcript_hash = client_transcript_hash;
    bad_transcript_hash[0] ^= 0x80;
    if (verifyTls12Finished(opened_client_finished[0..opened_client_finished_len], keys.master[0..], "client finished", bad_transcript_hash[0..])) return stream_result_integrity_failed;

    if (!appendBytesChecked(transcript[0..], &transcript_len, opened_client_finished[0..opened_client_finished_len])) return stream_result_buffer_small;
    var server_transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &server_transcript_hash, .{});

    var server_finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const server_finished_plain_len = buildTls12FinishedMessage(server_finished_plain[0..], keys.master[0..], "server finished", server_transcript_hash[0..]) orelse return stream_result_buffer_small;
    var server_verify: [tls12_finished_verify_len]u8 = undefined;
    @memcpy(server_verify[0..], server_finished_plain[4 .. 4 + tls12_finished_verify_len]);

    var server_protect_req: [tls12_record_protect_header_len + tls12_finished_message_len]u8 = .{0} ** (tls12_record_protect_header_len + tls12_finished_message_len);
    @memcpy(server_protect_req[0..4], magic_record_protect_in);
    writeBe64(server_protect_req[4..12], 0);
    server_protect_req[12] = tls_content_handshake;
    @memcpy(server_protect_req[13..17], keys.server_iv[0..]);
    @memcpy(server_protect_req[17..33], keys.server_key[0..]);
    @memcpy(server_protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + server_finished_plain_len], server_finished_plain[0..server_finished_plain_len]);
    var server_finished_record: [tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    var server_protect_in = r4os.abi.ProtocolBuffer{
        .data = &server_protect_req,
        .len = @intCast(tls12_record_protect_header_len + server_finished_plain_len),
        .capacity = server_protect_req.len,
    };
    var server_protect_out = r4os.abi.ProtocolBuffer{
        .data = &server_finished_record,
        .len = 0,
        .capacity = server_finished_record.len,
    };
    if (tls12ProtectRecordDispatch(&server_protect_in, &server_protect_out) != stream_result_ok) return stream_result_integrity_failed;
    const server_finished_record_len: usize = @intCast(server_protect_out.len);

    var server_open_req: [tls12_record_open_header_len + server_finished_record.len]u8 = .{0} ** (tls12_record_open_header_len + server_finished_record.len);
    @memcpy(server_open_req[0..4], magic_record_open_in);
    writeBe64(server_open_req[4..12], 0);
    @memcpy(server_open_req[12..16], keys.server_iv[0..]);
    @memcpy(server_open_req[16..32], keys.server_key[0..]);
    @memcpy(server_open_req[tls12_record_open_header_len .. tls12_record_open_header_len + server_finished_record_len], server_finished_record[0..server_finished_record_len]);
    var opened_server_finished: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    var server_open_in = r4os.abi.ProtocolBuffer{
        .data = &server_open_req,
        .len = @intCast(tls12_record_open_header_len + server_finished_record_len),
        .capacity = server_open_req.len,
    };
    var server_open_out = r4os.abi.ProtocolBuffer{
        .data = &opened_server_finished,
        .len = 0,
        .capacity = opened_server_finished.len,
    };
    if (tls12OpenRecordDispatch(&server_open_in, &server_open_out) != stream_result_ok) return stream_result_integrity_failed;
    const opened_server_finished_len: usize = @intCast(server_open_out.len);
    if (opened_server_finished_len != server_finished_plain_len) return stream_result_malformed_record;
    if (!verifyTls12Finished(opened_server_finished[0..opened_server_finished_len], keys.master[0..], "server finished", server_transcript_hash[0..])) return stream_result_integrity_failed;

    result.* = .{
        .client_hello_len = client_hello_len,
        .server_handshake_len = server_record_len,
        .client_key_exchange_len = client_key_exchange_len,
        .client_finished_record_len = client_finished_record_len,
        .server_finished_record_len = server_finished_record_len,
        .transcript_len = transcript_len,
        .client_seq_next = 1,
        .server_seq_next = 1,
        .shared_secret = shared_secret,
        .client_verify = client_verify,
        .server_verify = server_verify,
    };
    return stream_result_ok;
}

fn selftestLiveSession(client_hello: []const u8) i32 {
    var begin_result: [tls12_live_header_len + tls12_live_state_header_len + tls12_live_max_transcript_len + 4096]u8 = .{0} ** (tls12_live_header_len + tls12_live_state_header_len + tls12_live_max_transcript_len + 4096);
    const begin_in = r4os.abi.ProtocolBuffer{
        .data = @ptrCast(@constCast(client_hello.ptr)),
        .len = @intCast(client_hello.len),
        .capacity = @intCast(client_hello.len),
    };
    var begin_out = r4os.abi.ProtocolBuffer{
        .data = &begin_result,
        .len = 0,
        .capacity = begin_result.len,
    };
    const begin_rc = tls12LiveBeginDispatch(&begin_in, &begin_out);
    if (begin_rc != stream_result_ok) return begin_rc;
    const begin_bytes = begin_result[0..@intCast(begin_out.len)];
    if (begin_bytes.len < tls12_live_header_len or !startsWith(begin_bytes, magic_tls12_live_begin_out)) return stream_result_malformed_record;
    const state_len = readBe32(begin_bytes[4..8]);
    const server_len = readBe32(begin_bytes[8..12]);
    if (state_len == 0 or server_len == 0 or begin_bytes.len != tls12_live_header_len + state_len + server_len) return stream_result_malformed_record;
    const state_bytes = begin_bytes[tls12_live_header_len .. tls12_live_header_len + state_len];
    const state = parseTls12LiveState(state_bytes) orelse return stream_result_malformed_record;
    if (state.total_len != state_len) return stream_result_malformed_record;
    const server_record = recordHeader(begin_bytes[tls12_live_header_len + state_len ..]) orelse return stream_result_malformed_record;
    if (server_record.content_type != tls_content_handshake or server_record.fragment_len + tls_record_header_len != server_len) return stream_result_malformed_record;

    var client_flight: [512]u8 = .{0} ** 512;
    const client_flight_len = buildTls12LiveClientFlight(state, client_flight[0..]) orelse return stream_result_buffer_small;
    var finish_input: [tls12_live_state_header_len + tls12_live_max_transcript_len + 512]u8 = .{0} ** (tls12_live_state_header_len + tls12_live_max_transcript_len + 512);
    if (state_len + client_flight_len > finish_input.len) return stream_result_buffer_small;
    @memcpy(finish_input[0..state_len], state_bytes);
    @memcpy(finish_input[state_len .. state_len + client_flight_len], client_flight[0..client_flight_len]);

    var finish_result: [512]u8 = .{0} ** 512;
    const finish_in = r4os.abi.ProtocolBuffer{
        .data = &finish_input,
        .len = @intCast(state_len + client_flight_len),
        .capacity = finish_input.len,
    };
    var finish_out = r4os.abi.ProtocolBuffer{
        .data = &finish_result,
        .len = 0,
        .capacity = finish_result.len,
    };
    const finish_rc = tls12LiveFinishDispatch(&finish_in, &finish_out);
    if (finish_rc != stream_result_ok) return finish_rc;
    const finish_bytes = finish_result[0..@intCast(finish_out.len)];
    if (finish_bytes.len < tls12_live_header_len or !startsWith(finish_bytes, magic_tls12_live_finish_out)) return stream_result_malformed_record;
    const stream_state_len = readBe32(finish_bytes[4..8]);
    const server_flight_len = readBe32(finish_bytes[8..12]);
    if (stream_state_len != tls12_live_stream_state_len) return stream_result_malformed_record;
    if (finish_bytes.len != tls12_live_header_len + stream_state_len + server_flight_len) return stream_result_malformed_record;
    const stream_state = finish_bytes[tls12_live_header_len .. tls12_live_header_len + stream_state_len];
    if (!startsWith(stream_state, magic_tls12_live_stream)) return stream_result_malformed_record;
    const server_flight = finish_bytes[tls12_live_header_len + stream_state_len ..];
    if (server_flight.len < tls12_ccs_record_len + tls_record_header_len) return stream_result_malformed_record;
    if (!isChangeCipherSpecRecord(server_flight[0..tls12_ccs_record_len])) return stream_result_malformed_record;
    const finished_header = recordHeader(server_flight[tls12_ccs_record_len..]) orelse return stream_result_malformed_record;
    if (finished_header.content_type != tls_content_handshake) return stream_result_malformed_record;
    return selftestTls12ApplicationRecords(stream_state);
}

fn selftestTls12ApplicationRecords(stream_state: []const u8) i32 {
    const stream = parseTls12LiveStreamState(stream_state) orelse return stream_result_malformed_record;
    const app_plain = "R4TLS-APP-05532";

    var app_write_input: [tls12_app_io_header_len + app_plain.len]u8 = .{0} ** (tls12_app_io_header_len + app_plain.len);
    @memcpy(app_write_input[0..4], magic_tls12_app_write_in);
    @memcpy(app_write_input[4..tls12_app_io_header_len], stream_state[0..tls12_live_stream_state_len]);
    @memcpy(app_write_input[tls12_app_io_header_len..], app_plain);
    var app_write_result: [tls12_app_io_header_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + app_plain.len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls12_app_io_header_len + tls_record_header_len + tls_aes_gcm_explicit_nonce_len + app_plain.len + tls_aes_gcm_tag_len);
    var app_write_in = r4os.abi.ProtocolBuffer{
        .data = &app_write_input,
        .len = app_write_input.len,
        .capacity = app_write_input.len,
    };
    var app_write_out = r4os.abi.ProtocolBuffer{
        .data = &app_write_result,
        .len = 0,
        .capacity = app_write_result.len,
    };
    if (tls12AppWriteDispatch(&app_write_in, &app_write_out) != stream_result_ok) return stream_result_integrity_failed;
    const app_write_bytes = app_write_result[0..@intCast(app_write_out.len)];
    if (app_write_bytes.len <= tls12_app_io_header_len or !startsWith(app_write_bytes, magic_tls12_app_write_out)) return stream_result_malformed_record;
    const write_state = app_write_bytes[4..tls12_app_io_header_len];
    if (!startsWith(write_state, magic_tls12_live_stream)) return stream_result_malformed_record;
    if (readBe64(write_state[tls12_live_stream_client_seq_offset .. tls12_live_stream_client_seq_offset + 8]) != stream.client_sequence) return stream_result_malformed_record;
    if (readBe64(write_state[tls12_live_stream_server_seq_offset .. tls12_live_stream_server_seq_offset + 8]) != stream.server_sequence +% 1) return stream_result_malformed_record;
    const app_write_record = recordHeader(app_write_bytes[tls12_app_io_header_len..]) orelse return stream_result_malformed_record;
    if (app_write_record.content_type != tls_content_application_data) return stream_result_malformed_record;

    var client_protect_req: [tls12_record_protect_header_len + app_plain.len]u8 = .{0} ** (tls12_record_protect_header_len + app_plain.len);
    @memcpy(client_protect_req[0..4], magic_record_protect_in);
    writeBe64(client_protect_req[4..12], stream.client_sequence);
    client_protect_req[12] = tls_content_application_data;
    @memcpy(client_protect_req[13..17], stream.client_iv);
    @memcpy(client_protect_req[17..33], stream.client_key);
    @memcpy(client_protect_req[tls12_record_protect_header_len..], app_plain);
    var client_record: [tls_record_header_len + tls_aes_gcm_explicit_nonce_len + app_plain.len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls_record_header_len + tls_aes_gcm_explicit_nonce_len + app_plain.len + tls_aes_gcm_tag_len);
    var client_protect_in = r4os.abi.ProtocolBuffer{
        .data = &client_protect_req,
        .len = client_protect_req.len,
        .capacity = client_protect_req.len,
    };
    var client_protect_out = r4os.abi.ProtocolBuffer{
        .data = &client_record,
        .len = 0,
        .capacity = client_record.len,
    };
    if (tls12ProtectRecordDispatch(&client_protect_in, &client_protect_out) != stream_result_ok) return stream_result_integrity_failed;
    const client_record_len: usize = @intCast(client_protect_out.len);

    var app_read_input: [tls12_app_io_header_len + client_record.len]u8 = .{0} ** (tls12_app_io_header_len + client_record.len);
    @memcpy(app_read_input[0..4], magic_tls12_app_read_in);
    @memcpy(app_read_input[4..tls12_app_io_header_len], stream_state[0..tls12_live_stream_state_len]);
    @memcpy(app_read_input[tls12_app_io_header_len .. tls12_app_io_header_len + client_record_len], client_record[0..client_record_len]);
    var app_read_result: [tls12_app_io_header_len + app_plain.len]u8 = .{0} ** (tls12_app_io_header_len + app_plain.len);
    var app_read_in = r4os.abi.ProtocolBuffer{
        .data = &app_read_input,
        .len = @intCast(tls12_app_io_header_len + client_record_len),
        .capacity = app_read_input.len,
    };
    var app_read_out = r4os.abi.ProtocolBuffer{
        .data = &app_read_result,
        .len = 0,
        .capacity = app_read_result.len,
    };
    if (tls12AppReadDispatch(&app_read_in, &app_read_out) != stream_result_ok) return stream_result_integrity_failed;
    const app_read_bytes = app_read_result[0..@intCast(app_read_out.len)];
    if (app_read_bytes.len != tls12_app_io_header_len + app_plain.len or !startsWith(app_read_bytes, magic_tls12_app_read_out)) return stream_result_malformed_record;
    const read_state = app_read_bytes[4..tls12_app_io_header_len];
    if (readBe64(read_state[tls12_live_stream_client_seq_offset .. tls12_live_stream_client_seq_offset + 8]) != stream.client_sequence +% 1) return stream_result_malformed_record;
    if (readBe64(read_state[tls12_live_stream_server_seq_offset .. tls12_live_stream_server_seq_offset + 8]) != stream.server_sequence) return stream_result_malformed_record;
    if (!std.mem.eql(u8, app_read_bytes[tls12_app_io_header_len..], app_plain)) return stream_result_integrity_failed;

    var partial_read_in = app_read_in;
    partial_read_in.len = @intCast(tls12_app_io_header_len + 4);
    if (tls12AppReadDispatch(&partial_read_in, &app_read_out) != stream_result_would_block) return stream_result_malformed_record;
    return stream_result_ok;
}

fn buildTls12LiveClientFlight(state: Tls12LiveStateView, out: []u8) ?usize {
    var client_key_exchange: [64]u8 = .{0} ** 64;
    const client_key_exchange_len = buildClientKeyExchangeRecord(client_key_exchange[0..], fixture_x25519_public[0..]) orelse return null;
    const shared_secret = X25519.scalarmult(state.server_secret, fixture_x25519_public) catch return null;
    const keys = deriveTls12SessionKeys(shared_secret, state.client_random, state.server_random);

    var transcript: [tls12_live_max_transcript_len]u8 = .{0} ** tls12_live_max_transcript_len;
    var transcript_len: usize = 0;
    if (!appendBytesChecked(transcript[0..], &transcript_len, state.transcript)) return null;
    if (!appendBytesChecked(transcript[0..], &transcript_len, client_key_exchange[tls_record_header_len..client_key_exchange_len])) return null;
    var client_transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(transcript[0..transcript_len], &client_transcript_hash, .{});

    var client_finished_plain: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const client_finished_plain_len = buildTls12FinishedMessage(client_finished_plain[0..], keys.master[0..], "client finished", client_transcript_hash[0..]) orelse return null;
    var client_protect_req: [tls12_record_protect_header_len + tls12_finished_message_len]u8 = .{0} ** (tls12_record_protect_header_len + tls12_finished_message_len);
    @memcpy(client_protect_req[0..4], magic_record_protect_in);
    writeBe64(client_protect_req[4..12], 0);
    client_protect_req[12] = tls_content_handshake;
    @memcpy(client_protect_req[13..17], keys.client_iv[0..]);
    @memcpy(client_protect_req[17..33], keys.client_key[0..]);
    @memcpy(client_protect_req[tls12_record_protect_header_len .. tls12_record_protect_header_len + client_finished_plain_len], client_finished_plain[0..client_finished_plain_len]);

    var client_finished_record: [tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len]u8 = .{0} ** (tls_record_header_len + tls_aes_gcm_explicit_nonce_len + tls12_finished_message_len + tls_aes_gcm_tag_len);
    var client_protect_in = r4os.abi.ProtocolBuffer{
        .data = &client_protect_req,
        .len = @intCast(tls12_record_protect_header_len + client_finished_plain_len),
        .capacity = client_protect_req.len,
    };
    var client_protect_out = r4os.abi.ProtocolBuffer{
        .data = &client_finished_record,
        .len = 0,
        .capacity = client_finished_record.len,
    };
    if (tls12ProtectRecordDispatch(&client_protect_in, &client_protect_out) != stream_result_ok) return null;
    const client_finished_record_len: usize = @intCast(client_protect_out.len);

    var pos: usize = 0;
    const total = client_key_exchange_len + tls12_ccs_record_len + client_finished_record_len;
    if (out.len < total) return null;
    @memcpy(out[pos .. pos + client_key_exchange_len], client_key_exchange[0..client_key_exchange_len]);
    pos += client_key_exchange_len;
    const ccs_len = buildChangeCipherSpecRecord(out[pos .. pos + tls12_ccs_record_len]) orelse return null;
    pos += ccs_len;
    @memcpy(out[pos .. pos + client_finished_record_len], client_finished_record[0..client_finished_record_len]);
    pos += client_finished_record_len;
    return if (pos == total) pos else null;
}

fn deriveTls12SessionKeys(pre_master: [tls_pre_master_len]u8, client_random: [tls_random_len]u8, server_random: [tls_random_len]u8) Tls12SessionKeys {
    var master: [tls_master_secret_len]u8 = undefined;
    tls12Prf(master[0..], pre_master[0..], "master secret", client_random[0..], server_random[0..]);
    return deriveTls12TrafficKeys(master, client_random, server_random);
}

fn deriveTls12ExtendedSessionKeys(pre_master: [tls_pre_master_len]u8, session_hash: [Sha256.digest_length]u8, client_random: [tls_random_len]u8, server_random: [tls_random_len]u8) Tls12SessionKeys {
    var master: [tls_master_secret_len]u8 = undefined;
    tls12Prf(master[0..], pre_master[0..], "extended master secret", session_hash[0..], "");
    return deriveTls12TrafficKeys(master, client_random, server_random);
}

fn deriveTls12TrafficKeys(master: [tls_master_secret_len]u8, client_random: [tls_random_len]u8, server_random: [tls_random_len]u8) Tls12SessionKeys {
    var keys = Tls12SessionKeys{
        .master = .{0} ** tls_master_secret_len,
        .client_key = .{0} ** tls_aes_128_key_len,
        .server_key = .{0} ** tls_aes_128_key_len,
        .client_iv = .{0} ** tls_aes_gcm_fixed_iv_len,
        .server_iv = .{0} ** tls_aes_gcm_fixed_iv_len,
    };
    @memcpy(keys.master[0..], master[0..]);
    var key_block: [tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len + tls_aes_gcm_fixed_iv_len]u8 = undefined;
    tls12Prf(key_block[0..], keys.master[0..], "key expansion", server_random[0..], client_random[0..]);
    @memcpy(keys.client_key[0..], key_block[0..tls_aes_128_key_len]);
    @memcpy(keys.server_key[0..], key_block[tls_aes_128_key_len .. tls_aes_128_key_len + tls_aes_128_key_len]);
    @memcpy(keys.client_iv[0..], key_block[tls_aes_128_key_len + tls_aes_128_key_len .. tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len]);
    @memcpy(keys.server_iv[0..], key_block[tls_aes_128_key_len + tls_aes_128_key_len + tls_aes_gcm_fixed_iv_len .. key_block.len]);
    return keys;
}

fn writeTls12LiveState(out: []u8, client_random: [tls_random_len]u8, server_random: [tls_random_len]u8, server_secret: [X25519.secret_length]u8, transcript: []const u8) ?usize {
    if (transcript.len > tls12_live_max_transcript_len) return null;
    const total = tls12_live_state_header_len + transcript.len;
    if (out.len < total) return null;
    var pos: usize = 0;
    @memcpy(out[pos .. pos + 4], magic_tls12_live_state);
    pos += 4;
    writeBe32(out[pos .. pos + 4], @intCast(transcript.len));
    pos += 4;
    @memcpy(out[pos .. pos + tls_random_len], client_random[0..]);
    pos += tls_random_len;
    @memcpy(out[pos .. pos + tls_random_len], server_random[0..]);
    pos += tls_random_len;
    @memcpy(out[pos .. pos + X25519.secret_length], &server_secret);
    pos += X25519.secret_length;
    if (transcript.len != 0) @memcpy(out[pos .. pos + transcript.len], transcript);
    return total;
}

fn parseTls12LiveState(input: []const u8) ?Tls12LiveStateView {
    if (input.len < tls12_live_state_header_len) return null;
    if (!startsWith(input, magic_tls12_live_state)) return null;
    const transcript_len = readBe32(input[4..8]);
    if (transcript_len > tls12_live_max_transcript_len) return null;
    const total = tls12_live_state_header_len + transcript_len;
    if (input.len < total) return null;
    var client_random: [tls_random_len]u8 = undefined;
    var server_random: [tls_random_len]u8 = undefined;
    @memcpy(client_random[0..], input[8 .. 8 + tls_random_len]);
    @memcpy(server_random[0..], input[8 + tls_random_len .. 8 + tls_random_len + tls_random_len]);
    const secret_offset = 8 + tls_random_len + tls_random_len;
    const server_secret = input[secret_offset..][0..X25519.secret_length].*;
    return .{
        .total_len = total,
        .transcript = input[tls12_live_state_header_len..total],
        .client_random = client_random,
        .server_random = server_random,
        .server_secret = server_secret,
    };
}

// CredSSP binds to the ASN.1 SubjectPublicKey used by this TLS connection.
// R4LK stores a certificate fingerprint, not those public-key bytes. Keep
// certificate parsing in the TLS owner and reject material changed since
// the stream was established.
fn tls12ServerBindingKeyDispatch(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return stream_result_bad_buffer;
    if (input.len != tls12_live_stream_state_len) return stream_result_malformed_record;
    const stream = parseTls12LiveStreamState(input) orelse return stream_result_malformed_record;
    ensureSystemTlsMaterialLoaded();
    if (!system_cert_loaded or system_cert_der_len == 0) return stream_result_material_missing;
    var fingerprint: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(system_cert_der[0..system_cert_der_len], &fingerprint, .{});
    if (!std.mem.eql(u8, stream.cert_hash, &fingerprint)) return stream_result_integrity_failed;
    const certificate = Certificate{ .buffer = system_cert_der[0..system_cert_der_len], .index = 0 };
    const parsed = certificate.parse() catch return stream_result_material_invalid;
    return writeOut(out_buffer, parsed.pubKey());
}

fn writeTls12LiveStreamState(out: []u8, keys: Tls12SessionKeys) ?usize {
    if (!system_cert_loaded or system_cert_der_len == 0) return null;
    if (out.len < tls12_live_stream_state_len) return null;
    var pos: usize = 0;
    @memcpy(out[pos .. pos + 4], magic_tls12_live_stream);
    pos += 4;
    writeBe64(out[pos .. pos + 8], 1);
    pos += 8;
    writeBe64(out[pos .. pos + 8], 1);
    pos += 8;
    @memcpy(out[pos .. pos + tls_aes_128_key_len], keys.client_key[0..]);
    pos += tls_aes_128_key_len;
    @memcpy(out[pos .. pos + tls_aes_128_key_len], keys.server_key[0..]);
    pos += tls_aes_128_key_len;
    @memcpy(out[pos .. pos + tls_aes_gcm_fixed_iv_len], keys.client_iv[0..]);
    pos += tls_aes_gcm_fixed_iv_len;
    @memcpy(out[pos .. pos + tls_aes_gcm_fixed_iv_len], keys.server_iv[0..]);
    pos += tls_aes_gcm_fixed_iv_len;
    @memcpy(out[pos .. pos + tls_master_secret_len], keys.master[0..]);
    pos += tls_master_secret_len;
    var cert_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(system_cert_der[0..system_cert_der_len], &cert_hash, .{});
    @memcpy(out[pos .. pos + Sha256.digest_length], cert_hash[0..]);
    pos += Sha256.digest_length;
    return if (pos == tls12_live_stream_state_len) pos else null;
}

fn parseTls12LiveStreamState(input: []const u8) ?Tls12LiveStreamView {
    if (input.len < tls12_live_stream_state_len) return null;
    if (!startsWith(input, magic_tls12_live_stream)) return null;
    return .{
        .client_sequence = readBe64(input[tls12_live_stream_client_seq_offset .. tls12_live_stream_client_seq_offset + 8]),
        .server_sequence = readBe64(input[tls12_live_stream_server_seq_offset .. tls12_live_stream_server_seq_offset + 8]),
        .client_key = input[tls12_live_stream_client_key_offset .. tls12_live_stream_client_key_offset + tls_aes_128_key_len],
        .server_key = input[tls12_live_stream_server_key_offset .. tls12_live_stream_server_key_offset + tls_aes_128_key_len],
        .client_iv = input[tls12_live_stream_client_iv_offset .. tls12_live_stream_client_iv_offset + tls_aes_gcm_fixed_iv_len],
        .server_iv = input[tls12_live_stream_server_iv_offset .. tls12_live_stream_server_iv_offset + tls_aes_gcm_fixed_iv_len],
        .master = input[tls12_live_stream_master_offset .. tls12_live_stream_master_offset + tls_master_secret_len],
        .cert_hash = input[tls12_live_stream_cert_hash_offset .. tls12_live_stream_cert_hash_offset + Sha256.digest_length],
    };
}

fn writeUpdatedTls12LiveStreamState(out: []u8, input: []const u8, client_sequence: u64, server_sequence: u64) bool {
    if (input.len < tls12_live_stream_state_len or out.len < tls12_live_stream_state_len) return false;
    @memcpy(out[0..tls12_live_stream_state_len], input[0..tls12_live_stream_state_len]);
    writeBe64(out[tls12_live_stream_client_seq_offset .. tls12_live_stream_client_seq_offset + 8], client_sequence);
    writeBe64(out[tls12_live_stream_server_seq_offset .. tls12_live_stream_server_seq_offset + 8], server_sequence);
    return true;
}

fn buildClientKeyExchangeRecord(out: []u8, public_key: []const u8) ?usize {
    if (public_key.len != X25519.public_length and public_key.len != tls_ec_public_max_len) return null;
    const body_len: usize = 1 + public_key.len;
    const fragment_len: usize = 4 + body_len;
    const record_len = tls_record_header_len + fragment_len;
    if (out.len < record_len) return null;
    out[0] = tls_content_handshake;
    out[1] = tls_version_major;
    out[2] = tls_version_tls12_minor;
    writeBe16(out[3..5], @intCast(fragment_len));
    out[5] = tls_handshake_client_key_exchange;
    writeBe24(out[6..9], @intCast(body_len));
    out[9] = @intCast(public_key.len);
    @memcpy(out[10 .. 10 + public_key.len], public_key);
    return record_len;
}

fn parseClientKeyExchangeRecord(input: []const u8) ?[]const u8 {
    const record = recordHeader(input) orelse return null;
    if (record.content_type != tls_content_handshake or record.major != tls_version_major or record.minor != tls_version_tls12_minor) return null;
    const record_len = tls_record_header_len + record.fragment_len;
    if (input.len < record_len) return null;
    const fragment = input[tls_record_header_len..record_len];
    if (fragment.len < 5) return null;
    if (fragment[0] != tls_handshake_client_key_exchange) return null;
    const body_len = readBe24(fragment[1..4]);
    const public_len: usize = fragment[4];
    if ((public_len != X25519.public_length and public_len != tls_ec_public_max_len) or body_len != 1 + public_len or fragment.len != 5 + public_len) return null;
    return fragment[5 .. 5 + public_len];
}

fn buildChangeCipherSpecRecord(out: []u8) ?usize {
    if (out.len < tls12_ccs_record_len) return null;
    out[0] = tls_content_change_cipher_spec;
    out[1] = tls_version_major;
    out[2] = tls_version_tls12_minor;
    writeBe16(out[3..5], 1);
    out[5] = 1;
    return tls12_ccs_record_len;
}

fn isChangeCipherSpecRecord(input: []const u8) bool {
    const record = recordHeader(input) orelse return false;
    if (record.content_type != tls_content_change_cipher_spec or record.fragment_len != 1) return false;
    if (input.len < tls12_ccs_record_len) return false;
    return input[tls_record_header_len] == 1;
}

fn buildTls12FinishedMessage(out: []u8, master: []const u8, label: []const u8, transcript_hash: []const u8) ?usize {
    if (master.len != tls_master_secret_len or transcript_hash.len != Sha256.digest_length) return null;
    if (out.len < tls12_finished_message_len) return null;
    out[0] = tls_handshake_finished;
    writeBe24(out[1..4], @intCast(tls12_finished_verify_len));
    tls12Prf(out[4 .. 4 + tls12_finished_verify_len], master, label, transcript_hash, "");
    return tls12_finished_message_len;
}

fn verifyTls12Finished(message: []const u8, master: []const u8, label: []const u8, transcript_hash: []const u8) bool {
    if (message.len != tls12_finished_message_len) return false;
    if (message[0] != tls_handshake_finished) return false;
    if (readBe24(message[1..4]) != tls12_finished_verify_len) return false;
    var expected: [tls12_finished_message_len]u8 = .{0} ** tls12_finished_message_len;
    const expected_len = buildTls12FinishedMessage(expected[0..], master, label, transcript_hash) orelse return false;
    return std.mem.eql(u8, message[0..expected_len], expected[0..expected_len]);
}

fn appendBytesChecked(out: []u8, pos: *usize, bytes: []const u8) bool {
    if (pos.* + bytes.len > out.len) return false;
    if (bytes.len != 0) @memcpy(out[pos.* .. pos.* + bytes.len], bytes);
    pos.* += bytes.len;
    return true;
}

fn appendServerHello(out: []u8, pos_start: usize, plan: ServerHandshakePlan) usize {
    var pos = pos_start;
    out[pos] = tls_handshake_server_hello;
    pos += 1;
    const len_pos = pos;
    pos += 3;
    const body_start = pos;
    out[pos] = plan.selected_major;
    pos += 1;
    out[pos] = plan.selected_minor;
    pos += 1;
    @memcpy(out[pos .. pos + tls_random_len], plan.server_random[0..]);
    pos += tls_random_len;
    out[pos] = 0;
    pos += 1;
    writeBe16(out[pos .. pos + 2], plan.selected_cipher);
    pos += 2;
    out[pos] = 0;
    pos += 1;
    const extensions_len_pos = pos;
    pos += 2;
    const extensions_start = pos;
    if (plan.secure_renegotiation) pos = appendExtension(out, pos, ext_renegotiation_info, &[_]u8{0});
    writeBe16(out[extensions_len_pos .. extensions_len_pos + 2], @intCast(pos - extensions_start));
    writeBe24(out[len_pos .. len_pos + 3], @intCast(pos - body_start));
    return pos;
}

fn appendCertificate(out: []u8, pos_start: usize, cert_der: []const u8) usize {
    var pos = pos_start;
    out[pos] = tls_handshake_certificate;
    pos += 1;
    const len_pos = pos;
    pos += 3;
    const body_start = pos;
    writeBe24(out[pos .. pos + 3], @intCast(3 + cert_der.len));
    pos += 3;
    writeBe24(out[pos .. pos + 3], @intCast(cert_der.len));
    pos += 3;
    @memcpy(out[pos .. pos + cert_der.len], cert_der);
    pos += cert_der.len;
    writeBe24(out[len_pos .. len_pos + 3], @intCast(pos - body_start));
    return pos;
}

fn appendServerKeyExchangePlan(out: []u8, pos_start: usize, plan: ServerHandshakePlan, key: *const RsaKeyContext) ?usize {
    var pos = pos_start;
    out[pos] = tls_handshake_server_key_exchange;
    pos += 1;
    const len_pos = pos;
    pos += 3;
    const body_start = pos;
    const params_start = pos;
    out[pos] = 3;
    pos += 1;
    writeBe16(out[pos .. pos + 2], tls_named_group_x25519);
    pos += 2;
    out[pos] = @intCast(X25519.public_length);
    pos += 1;
    const server_public = X25519.recoverPublicKey(plan.server_secret) catch return null;
    @memcpy(out[pos .. pos + X25519.public_length], server_public[0..]);
    pos += X25519.public_length;
    const params = out[params_start..pos];
    var signed_input: [tls_random_len + tls_random_len + 64]u8 = .{0} ** (tls_random_len + tls_random_len + 64);
    if (params.len > 64) return null;
    @memcpy(signed_input[0..tls_random_len], plan.client_random[0..]);
    @memcpy(signed_input[tls_random_len .. tls_random_len + tls_random_len], plan.server_random[0..]);
    @memcpy(signed_input[tls_random_len + tls_random_len .. tls_random_len + tls_random_len + params.len], params);
    var signature: [rsa_max_modulus_bytes]u8 = .{0} ** rsa_max_modulus_bytes;
    const signature_len = rsaPkcs1Sha256Sign(signature[0..], key, signed_input[0 .. tls_random_len + tls_random_len + params.len]) catch return null;

    writeBe16(out[pos .. pos + 2], tls_signature_rsa_pkcs1_sha256);
    pos += 2;
    writeBe16(out[pos .. pos + 2], @intCast(signature_len));
    pos += 2;
    @memcpy(out[pos .. pos + signature_len], signature[0..signature_len]);
    pos += signature_len;
    writeBe24(out[len_pos .. len_pos + 3], @intCast(pos - body_start));
    return pos;
}

fn appendServerHelloDone(out: []u8, pos_start: usize) usize {
    var pos = pos_start;
    out[pos] = tls_handshake_server_hello_done;
    pos += 1;
    writeBe24(out[pos .. pos + 3], 0);
    pos += 3;
    return pos;
}

fn selftest(out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const sample = [_]u8{ tls_content_handshake, tls_version_major, tls_version_tls12_minor, 0, 42 };
    var result: [96]u8 = .{0} ** 96;
    var out = r4os.abi.ProtocolBuffer{
        .data = &result,
        .len = 0,
        .capacity = result.len,
    };
    const in = r4os.abi.ProtocolBuffer{
        .data = @constCast(&sample),
        .len = sample.len,
        .capacity = sample.len,
    };
    const rc = classifyRecord(&in, &out);
    if (rc != 0) return rc;
    const got = result[0..@intCast(out.len)];
    if (!contains(got, "hint=tls12-handshake")) return -6;

    var client_hello: [192]u8 = .{0} ** 192;
    const client_hello_len = buildClientHelloFixture(client_hello[0..]);
    var hello_result: [256]u8 = .{0} ** 256;
    var hello_out = r4os.abi.ProtocolBuffer{
        .data = &hello_result,
        .len = 0,
        .capacity = hello_result.len,
    };
    const hello_in = r4os.abi.ProtocolBuffer{
        .data = &client_hello,
        .len = @intCast(client_hello_len),
        .capacity = client_hello.len,
    };
    const hello_rc = parseClientHello(&hello_in, &hello_out);
    if (hello_rc != 0) return hello_rc;
    const hello_text = hello_result[0..@intCast(hello_out.len)];
    if (!contains(hello_text, "ciphers=2")) return -6;
    if (!contains(hello_text, "vers=yes")) return -6;
    if (!contains(hello_text, "keyshare=yes")) return -6;
    if (!contains(hello_text, "x25519_key=yes")) return -6;
    if (!contains(hello_text, "c02f=yes")) return -6;
    if (!contains(hello_text, "rsa_pkcs1=yes")) return -6;

    const client_info = parseClientHelloInfo(client_hello[0..client_hello_len]) orelse return -6;
    var plan = planServerHandshakeInfo(client_info) catch |err| return serverPlanErrorCode(err);
    defer std.crypto.secureZero(u8, &plan.server_secret);
    if (plan.selected_cipher != tls_cipher_ecdhe_rsa_aes_128_gcm_sha256) return -6;
    var plan_text_buf: [640]u8 = .{0} ** 640;
    var plan_out = r4os.abi.ProtocolBuffer{
        .data = &plan_text_buf,
        .len = 0,
        .capacity = plan_text_buf.len,
    };
    const plan_rc = planServerHandshake(&hello_in, &plan_out);
    if (plan_rc != 0) return plan_rc;
    const plan_text = plan_text_buf[0..@intCast(plan_out.len)];
    if (!contains(plan_text, "serverhandshake;mode=tls12")) return -6;
    if (!contains(plan_text, "stream_ready=no")) return -6;

    var server_fixture: [4096]u8 = .{0} ** 4096;
    var server_out = r4os.abi.ProtocolBuffer{
        .data = &server_fixture,
        .len = 0,
        .capacity = server_fixture.len,
    };
    const selftest_material = getSystemTlsMaterial() orelse return stream_result_material_missing;
    const server_len = buildServerHandshakeRecord(&server_fixture, plan, selftest_material) orelse return stream_result_buffer_small;
    server_out.len = @intCast(server_len);
    if (server_out.len == 0) return -6;
    const server_record = recordHeader(server_fixture[0..@intCast(server_out.len)]) orelse return -6;
    if (server_record.content_type != tls_content_handshake or server_record.fragment_len + tls_record_header_len != server_out.len) return -6;
    const server_fragment = server_fixture[tls_record_header_len..@intCast(server_out.len)];
    if (!hasHandshakeMessage(server_fragment, tls_handshake_server_hello)) return -6;
    if (!hasHandshakeMessage(server_fragment, tls_handshake_certificate)) return -6;
    if (!hasHandshakeMessage(server_fragment, tls_handshake_server_key_exchange)) return -6;
    if (!hasHandshakeMessage(server_fragment, tls_handshake_server_hello_done)) return -6;
    const ske_public = serverKeyExchangePublicKey(server_fragment) orelse return -6;
    const expected_server_public = X25519.recoverPublicKey(plan.server_secret) catch return -6;
    if (!std.mem.eql(u8, ske_public, expected_server_public[0..])) return -6;
    if (isLegacyServerKeyPlaceholder(ske_public)) return -6;
    const ske_signature_len = serverKeyExchangeSignatureLen(server_fragment) orelse return -6;
    if (!system_key_context.valid or ske_signature_len != system_key_context.modulus_len or ske_signature_len == 0) return -6;

    var contract_text_buf: [640]u8 = .{0} ** 640;
    var contract_out = r4os.abi.ProtocolBuffer{
        .data = &contract_text_buf,
        .len = 0,
        .capacity = contract_text_buf.len,
    };
    const contract_rc = describeStreamContract(&hello_in, &contract_out);
    if (contract_rc != 0) return contract_rc;
    const contract_text = contract_text_buf[0..@intCast(contract_out.len)];
    if (!contains(contract_text, "ops=read,write,flush,close,alert")) return -6;
    if (!contains(contract_text, "cipher_ready=yes")) return -6;
    if (!contains(contract_text, "fixture_ops=diagnostic-only")) return -6;
    if (!contains(contract_text, "r4lk_app_write=op24:R4AW->R4WX")) return -6;
    if (!contains(contract_text, "r4lk_app_read=op25:R4AR->R4RX")) return -6;

    var productive_text_buf: [1024]u8 = .{0} ** 1024;
    var productive_out = r4os.abi.ProtocolBuffer{
        .data = &productive_text_buf,
        .len = 0,
        .capacity = productive_text_buf.len,
    };
    const productive_rc = describeProductiveContract(&hello_in, &productive_out);
    if (productive_rc != 0) return productive_rc;
    const productive_text = productive_text_buf[0..@intCast(productive_out.len)];
    if (!contains(productive_text, "record_protect=op14:R4RP")) return -6;
    if (!contains(productive_text, "file_io=r4p-protocol-api")) return -6;
    if (!contains(productive_text, "rsa_sign=op19:R4SG->R4SR")) return -6;
    if (!contains(productive_text, "session_contract=op20")) return -6;
    if (!contains(productive_text, "app_write=op24:R4AW->R4WX")) return -6;
    if (!contains(productive_text, "app_read=op25:R4AR->R4RX")) return -6;

    var session_contract_text_buf: [768]u8 = .{0} ** 768;
    var session_contract_out = r4os.abi.ProtocolBuffer{
        .data = &session_contract_text_buf,
        .len = 0,
        .capacity = session_contract_text_buf.len,
    };
    const session_contract_rc = describeTls12SessionContract(&hello_in, &session_contract_out);
    if (session_contract_rc != 0) return session_contract_rc;
    const session_contract_text = session_contract_text_buf[0..@intCast(session_contract_out.len)];
    if (!contains(session_contract_text, "tls12-session-contract")) return -6;
    if (!contains(session_contract_text, "clientkeyexchange+ccs+finished")) return -6;
    if (!contains(session_contract_text, "rdpsvc=consumer-only")) return -6;

    var session_text_buf: [1024]u8 = .{0} ** 1024;
    var session_out = r4os.abi.ProtocolBuffer{
        .data = &session_text_buf,
        .len = 0,
        .capacity = session_text_buf.len,
    };
    const session_rc = tls12SessionHarnessDispatch(&hello_in, &session_out);
    if (session_rc != 0) return session_rc;
    const session_text = session_text_buf[0..@intCast(session_out.len)];
    if (!contains(session_text, "client_finished=ok")) return -6;
    if (!contains(session_text, "server_finished=ok")) return -6;
    if (!contains(session_text, "negative=bad-clientkeyexchange,bad-finished-tag,bad-transcript")) return -6;
    if (!contains(session_text, "next=credssp")) return -6;
    if (selftestLiveSession(client_hello[0..client_hello_len]) != 0) return -6;

    const sign_payload = "R4TLS SIGN SELFTEST 05524";
    var sign_req: [tls12_rsa_sign_header_len + sign_payload.len]u8 = .{0} ** (tls12_rsa_sign_header_len + sign_payload.len);
    @memcpy(sign_req[0..4], magic_rsa_sign_in);
    @memcpy(sign_req[4..], sign_payload);
    var sign_result: [tls12_rsa_sign_out_header_len + rsa_max_modulus_bytes]u8 = .{0} ** (tls12_rsa_sign_out_header_len + rsa_max_modulus_bytes);
    var sign_in = r4os.abi.ProtocolBuffer{
        .data = &sign_req,
        .len = sign_req.len,
        .capacity = sign_req.len,
    };
    var sign_out = r4os.abi.ProtocolBuffer{
        .data = &sign_result,
        .len = 0,
        .capacity = sign_result.len,
    };
    if (tls12SignServerKeyExchangeDispatch(&sign_in, &sign_out) != 0) return -6;
    if (sign_out.len != tls12_rsa_sign_out_header_len + system_key_context.modulus_len) return -6;
    if (!startsWith(sign_result[0..], magic_rsa_sign_out)) return -6;
    if (readBe16(sign_result[4..6]) != tls_signature_rsa_pkcs1_sha256) return -6;
    if (readBe16(sign_result[6..8]) != system_key_context.modulus_len) return -6;

    var transcript_hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(client_hello[0..client_hello_len], &transcript_hash, .{});
    if (allZero(transcript_hash[0..])) return -6;

    var x25519_req: [tls12_x25519_in_len]u8 = .{0} ** tls12_x25519_in_len;
    @memcpy(x25519_req[0..4], magic_x25519_in);
    @memcpy(x25519_req[4 .. 4 + X25519.secret_length], fixture_x25519_secret[0..]);
    @memcpy(x25519_req[4 + X25519.secret_length ..], fixture_x25519_public[0..]);
    var x25519_result: [tls12_x25519_out_len]u8 = .{0} ** tls12_x25519_out_len;
    var x25519_in = r4os.abi.ProtocolBuffer{
        .data = &x25519_req,
        .len = x25519_req.len,
        .capacity = x25519_req.len,
    };
    var x25519_out = r4os.abi.ProtocolBuffer{
        .data = &x25519_result,
        .len = 0,
        .capacity = x25519_result.len,
    };
    if (tls12X25519Dispatch(&x25519_in, &x25519_out) != 0) return -6;
    if (x25519_out.len != tls12_x25519_out_len or !startsWith(x25519_result[0..], magic_x25519_out)) return -6;
    if (allZero(x25519_result[4 + X25519.public_length .. tls12_x25519_out_len])) return -6;

    var key_schedule_req: [tls12_key_schedule_in_len]u8 = .{0} ** tls12_key_schedule_in_len;
    @memcpy(key_schedule_req[0..4], magic_key_schedule_in);
    @memcpy(key_schedule_req[4 .. 4 + tls_pre_master_len], x25519_result[4 + X25519.public_length .. tls12_x25519_out_len]);
    fillSequence(key_schedule_req[4 + tls_pre_master_len .. 4 + tls_pre_master_len + tls_random_len], 0x11);
    fillSequence(key_schedule_req[4 + tls_pre_master_len + tls_random_len ..], 0xA1);
    var key_schedule_result: [tls12_key_schedule_out_len]u8 = .{0} ** tls12_key_schedule_out_len;
    var key_schedule_in = r4os.abi.ProtocolBuffer{
        .data = &key_schedule_req,
        .len = key_schedule_req.len,
        .capacity = key_schedule_req.len,
    };
    var key_schedule_out = r4os.abi.ProtocolBuffer{
        .data = &key_schedule_result,
        .len = 0,
        .capacity = key_schedule_result.len,
    };
    if (tls12KeyScheduleDispatch(&key_schedule_in, &key_schedule_out) != 0) return -6;
    if (key_schedule_out.len != tls12_key_schedule_out_len or !startsWith(key_schedule_result[0..], magic_key_schedule_out)) return -6;
    if (allZero(key_schedule_result[tls12_key_schedule_client_key_offset .. tls12_key_schedule_client_key_offset + tls_aes_128_key_len])) return -6;

    const protected_plain = "R4TLS AESGCM 05523";
    var protect_req: [tls12_record_protect_header_len + protected_plain.len]u8 = .{0} ** (tls12_record_protect_header_len + protected_plain.len);
    @memcpy(protect_req[0..4], magic_record_protect_in);
    writeBe64(protect_req[4..12], 1);
    protect_req[12] = tls_content_application_data;
    @memcpy(protect_req[13..17], key_schedule_result[tls12_key_schedule_server_iv_offset .. tls12_key_schedule_server_iv_offset + tls_aes_gcm_fixed_iv_len]);
    @memcpy(protect_req[17..33], key_schedule_result[tls12_key_schedule_server_key_offset .. tls12_key_schedule_server_key_offset + tls_aes_128_key_len]);
    @memcpy(protect_req[tls12_record_protect_header_len..], protected_plain);
    var protected_record: [128]u8 = .{0} ** 128;
    var protect_in = r4os.abi.ProtocolBuffer{
        .data = &protect_req,
        .len = protect_req.len,
        .capacity = protect_req.len,
    };
    var protect_out = r4os.abi.ProtocolBuffer{
        .data = &protected_record,
        .len = 0,
        .capacity = protected_record.len,
    };
    if (tls12ProtectRecordDispatch(&protect_in, &protect_out) != 0) return -6;
    const protected_header = recordHeader(protected_record[0..@intCast(protect_out.len)]) orelse return -6;
    if (protected_header.content_type != tls_content_application_data) return -6;
    if (protected_header.fragment_len != tls_aes_gcm_explicit_nonce_len + protected_plain.len + tls_aes_gcm_tag_len) return -6;

    var open_req: [tls12_record_open_header_len + protected_record.len]u8 = .{0} ** (tls12_record_open_header_len + protected_record.len);
    @memcpy(open_req[0..4], magic_record_open_in);
    writeBe64(open_req[4..12], 1);
    @memcpy(open_req[12..16], key_schedule_result[tls12_key_schedule_server_iv_offset .. tls12_key_schedule_server_iv_offset + tls_aes_gcm_fixed_iv_len]);
    @memcpy(open_req[16..32], key_schedule_result[tls12_key_schedule_server_key_offset .. tls12_key_schedule_server_key_offset + tls_aes_128_key_len]);
    @memcpy(open_req[tls12_record_open_header_len .. tls12_record_open_header_len + @as(usize, @intCast(protect_out.len))], protected_record[0..@intCast(protect_out.len)]);
    var open_plain: [64]u8 = .{0} ** 64;
    var open_in = r4os.abi.ProtocolBuffer{
        .data = &open_req,
        .len = @intCast(tls12_record_open_header_len + protect_out.len),
        .capacity = open_req.len,
    };
    var open_out = r4os.abi.ProtocolBuffer{
        .data = &open_plain,
        .len = 0,
        .capacity = open_plain.len,
    };
    if (tls12OpenRecordDispatch(&open_in, &open_out) != 0) return -6;
    if (open_out.len != protected_plain.len or !contains(open_plain[0..@intCast(open_out.len)], protected_plain)) return -6;
    open_req[tls12_record_open_header_len + @as(usize, @intCast(protect_out.len)) - 1] ^= 0x55;
    if (tls12OpenRecordDispatch(&open_in, &open_out) != stream_result_integrity_failed) return -6;

    const app_plain = "R4TLS STREAM 05519";
    const app_in = r4os.abi.ProtocolBuffer{
        .data = @constCast(app_plain.ptr),
        .len = app_plain.len,
        .capacity = app_plain.len,
    };
    var app_record: [96]u8 = .{0} ** 96;
    var app_record_out = r4os.abi.ProtocolBuffer{
        .data = &app_record,
        .len = 0,
        .capacity = app_record.len,
    };
    const app_write_rc = streamWriteRecord(&app_in, &app_record_out);
    if (app_write_rc != 0) return app_write_rc;
    const app_record_header = recordHeader(app_record[0..@intCast(app_record_out.len)]) orelse return -6;
    if (app_record_header.content_type != tls_content_application_data) return -6;
    if (app_record_header.fragment_len != app_plain.len + tls_stream_fixture_tag_len) return -6;

    var app_plain_out_buf: [96]u8 = .{0} ** 96;
    var app_plain_out = r4os.abi.ProtocolBuffer{
        .data = &app_plain_out_buf,
        .len = 0,
        .capacity = app_plain_out_buf.len,
    };
    const app_record_in = r4os.abi.ProtocolBuffer{
        .data = &app_record,
        .len = app_record_out.len,
        .capacity = app_record.len,
    };
    const app_read_rc = streamReadRecord(&app_record_in, &app_plain_out);
    if (app_read_rc != 0) return app_read_rc;
    if (app_plain_out.len != app_plain.len) return -6;
    const recovered = app_plain_out_buf[0..@intCast(app_plain_out.len)];
    if (!contains(recovered, app_plain)) return -6;

    app_record[@intCast(app_record_out.len - 1)] ^= 0x7F;
    if (streamReadRecord(&app_record_in, &app_plain_out) != stream_result_integrity_failed) return -6;

    const alert_input = [_]u8{ 2, 40 };
    const alert_in = r4os.abi.ProtocolBuffer{
        .data = @constCast(&alert_input),
        .len = alert_input.len,
        .capacity = alert_input.len,
    };
    var alert_record: [8]u8 = .{0} ** 8;
    var alert_out = r4os.abi.ProtocolBuffer{
        .data = &alert_record,
        .len = 0,
        .capacity = alert_record.len,
    };
    const alert_rc = streamAlertRecord(&alert_in, &alert_out);
    if (alert_rc != 0) return alert_rc;
    const alert_header = recordHeader(alert_record[0..@intCast(alert_out.len)]) orelse return -6;
    if (alert_header.content_type != tls_content_alert or alert_header.fragment_len != 2) return -6;

    var tcp_result = r4os.abi.NetServiceTcpResult{
        .result = r4os.abi.net_service_result_ok,
        .flags = withTcpServiceStatus(
            r4os.abi.net_service_tcp_flag_handle_valid |
                r4os.abi.net_service_tcp_flag_conn_valid |
                r4os.abi.net_service_tcp_flag_lifecycle_valid,
            r4os.abi.net_service_status_would_block,
        ),
        .handle = 7,
        .conn_id = 11,
        .pending_rx = 0,
        .rx_window = 4096,
        .tx_window = 0,
        .lifecycle_cause = r4os.abi.net_service_socket_lifecycle_would_block,
        .service_status = r4os.abi.net_service_status_would_block,
    };
    const tcp_in = r4os.abi.ProtocolBuffer{
        .data = &tcp_result,
        .len = @sizeOf(r4os.abi.NetServiceTcpResult),
        .capacity = @sizeOf(r4os.abi.NetServiceTcpResult),
    };
    var tcp_status_text_buf: [512]u8 = .{0} ** 512;
    var tcp_status_out = r4os.abi.ProtocolBuffer{
        .data = &tcp_status_text_buf,
        .len = 0,
        .capacity = tcp_status_text_buf.len,
    };
    const tcp_status_rc = describeTransportStatus(&tcp_in, &tcp_status_out);
    if (tcp_status_rc != 0) return tcp_status_rc;
    const tcp_status_text = tcp_status_text_buf[0..@intCast(tcp_status_out.len)];
    if (!contains(tcp_status_text, "would_block=yes")) return -6;
    if (!contains(tcp_status_text, "backpressure=yes")) return -6;
    if (!contains(tcp_status_text, "disconnect=no")) return -6;

    var bad_cipher_hello: [192]u8 = .{0} ** 192;
    const bad_cipher_len = buildClientHelloFixtureVariant(bad_cipher_hello[0..], false, true);
    const bad_cipher_info = parseClientHelloInfo(bad_cipher_hello[0..bad_cipher_len]) orelse return -6;
    if (planServerHandshakeInfo(bad_cipher_info)) |_| {
        return -6;
    } else |err| {
        if (err != error.Unsupported) return -6;
    }

    var bad_version_hello: [192]u8 = .{0} ** 192;
    const bad_version_len = buildClientHelloFixtureVariant(bad_version_hello[0..], true, false);
    const bad_version_info = parseClientHelloInfo(bad_version_hello[0..bad_version_len]) orelse return -6;
    if (planServerHandshakeInfo(bad_version_info)) |_| {
        return -6;
    } else |err| {
        if (err != error.Unsupported) return -6;
    }
    if (runTls12ClientHarness() != stream_result_ok) return -6;

    client_hello[4] = 127;
    const bad_in = r4os.abi.ProtocolBuffer{
        .data = &client_hello,
        .len = @intCast(client_hello_len),
        .capacity = client_hello.len,
    };
    if (parseClientHello(&bad_in, &hello_out) == 0) return -6;
    return writeOut(out_buffer, "R4TLS selftest OK;live=ok;client=ok;x509=ok;app_write=ok;app_read=ok");
}

fn buildClientHelloFixture(out: []u8) usize {
    return buildClientHelloFixtureVariant(out, true, true);
}

fn buildClientHelloFixtureVariant(out: []u8, include_supported_cipher: bool, include_tls12_version: bool) usize {
    var pos: usize = 0;
    out[pos] = tls_content_handshake;
    pos += 1;
    out[pos] = tls_version_major;
    pos += 1;
    out[pos] = tls_version_tls12_minor;
    pos += 1;
    const record_len_pos = pos;
    pos += 2;
    const handshake_start = pos;
    out[pos] = tls_handshake_client_hello;
    pos += 1;
    const handshake_len_pos = pos;
    pos += 3;
    const body_start = pos;

    writeBe16(out[pos .. pos + 2], 0x0303);
    pos += 2;
    var random_i: u8 = 0;
    while (random_i < 32) : (random_i += 1) {
        out[pos] = random_i;
        pos += 1;
    }
    out[pos] = 0;
    pos += 1;
    writeBe16(out[pos .. pos + 2], 4);
    pos += 2;
    writeBe16(out[pos .. pos + 2], 0x1301);
    pos += 2;
    writeBe16(out[pos .. pos + 2], if (include_supported_cipher) tls_cipher_ecdhe_rsa_aes_128_gcm_sha256 else 0x00FF);
    pos += 2;
    out[pos] = 1;
    pos += 1;
    out[pos] = 0;
    pos += 1;

    const extensions_len_pos = pos;
    pos += 2;
    const extensions_start = pos;
    if (include_tls12_version) {
        pos = appendExtension(out, pos, ext_supported_versions, &[_]u8{ 4, 3, 4, 3, 3 });
    } else {
        pos = appendExtension(out, pos, ext_supported_versions, &[_]u8{ 2, 3, 4 });
    }
    pos = appendExtension(out, pos, ext_supported_groups, &[_]u8{ 0, 4, 0, 29, 0, 23 });
    pos = appendExtension(out, pos, ext_signature_algorithms, &[_]u8{ 0, 4, 8, 4, 4, 1 });
    var key_share: [2 + 2 + 2 + X25519.public_length]u8 = .{0} ** (2 + 2 + 2 + X25519.public_length);
    writeBe16(key_share[0..2], @intCast(2 + 2 + X25519.public_length));
    writeBe16(key_share[2..4], tls_named_group_x25519);
    writeBe16(key_share[4..6], X25519.public_length);
    @memcpy(key_share[6..], fixture_x25519_public[0..]);
    pos = appendExtension(out, pos, ext_key_share, key_share[0..]);
    pos = appendExtension(out, pos, ext_server_name, &[_]u8{ 0, 3, 0, 0, 0 });
    writeBe16(out[extensions_len_pos .. extensions_len_pos + 2], @intCast(pos - extensions_start));

    const body_len = pos - body_start;
    writeBe24(out[handshake_len_pos .. handshake_len_pos + 3], @intCast(body_len));
    writeBe16(out[record_len_pos .. record_len_pos + 2], @intCast(pos - handshake_start));
    return pos;
}

fn appendExtension(out: []u8, pos_start: usize, ext_type: u16, data: []const u8) usize {
    var pos = pos_start;
    writeBe16(out[pos .. pos + 2], ext_type);
    pos += 2;
    writeBe16(out[pos .. pos + 2], @intCast(data.len));
    pos += 2;
    if (data.len != 0) @memcpy(out[pos .. pos + data.len], data);
    pos += data.len;
    return pos;
}

fn tls12Prf(out: []u8, secret: []const u8, label: []const u8, seed_a: []const u8, seed_b: []const u8) void {
    var seed: [128]u8 = undefined;
    var seed_len: usize = 0;
    @memcpy(seed[seed_len .. seed_len + label.len], label);
    seed_len += label.len;
    @memcpy(seed[seed_len .. seed_len + seed_a.len], seed_a);
    seed_len += seed_a.len;
    @memcpy(seed[seed_len .. seed_len + seed_b.len], seed_b);
    seed_len += seed_b.len;

    var a: [HmacSha256.mac_length]u8 = undefined;
    HmacSha256.create(&a, seed[0..seed_len], secret);
    var pos: usize = 0;
    while (pos < out.len) {
        var hmac_input: [HmacSha256.mac_length + 128]u8 = undefined;
        @memcpy(hmac_input[0..HmacSha256.mac_length], a[0..]);
        @memcpy(hmac_input[HmacSha256.mac_length .. HmacSha256.mac_length + seed_len], seed[0..seed_len]);
        var block: [HmacSha256.mac_length]u8 = undefined;
        HmacSha256.create(&block, hmac_input[0 .. HmacSha256.mac_length + seed_len], secret);
        const copy_len = @min(block.len, out.len - pos);
        @memcpy(out[pos .. pos + copy_len], block[0..copy_len]);
        pos += copy_len;
        HmacSha256.create(&a, a[0..], secret);
    }
}

fn buildTls12Aad(out: *[13]u8, sequence: u64, content_type: u8, plain_len: usize) void {
    writeBe64(out[0..8], sequence);
    out[8] = content_type;
    out[9] = tls_version_major;
    out[10] = tls_version_tls12_minor;
    writeBe16(out[11..13], @intCast(plain_len));
}

fn isProtectableContentType(content_type: u8) bool {
    return switch (content_type) {
        tls_content_alert,
        tls_content_handshake,
        tls_content_application_data,
        => true,
        else => false,
    };
}

fn inputBytes(buffer: *const r4os.abi.ProtocolBuffer) ?[]const u8 {
    if (buffer.data == null) return null;
    const ptr: [*]const u8 = @ptrCast(buffer.data.?);
    return ptr[0..@intCast(buffer.len)];
}

fn outputBytes(buffer: *r4os.abi.ProtocolBuffer) ?[]u8 {
    if (buffer.data == null) return null;
    const ptr: [*]u8 = @ptrCast(buffer.data.?);
    return ptr[0..@intCast(buffer.capacity)];
}

fn tcpResultFromBuffer(buffer: *const r4os.abi.ProtocolBuffer) ?*const r4os.abi.NetServiceTcpResult {
    if (buffer.data == null) return null;
    if (buffer.len < @sizeOf(r4os.abi.NetServiceTcpResult)) return null;
    return @ptrCast(@alignCast(buffer.data.?));
}

fn streamFixtureProtectByte(value: u8, index: usize) u8 {
    return value ^ (@as(u8, @intCast((index * 31) & 0xFF)) ^ 0x5A);
}

fn streamFixtureChecksum(data: []const u8) u8 {
    var acc: u8 = 0xA5;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        acc = acc ^ data[i] ^ @as(u8, @intCast((i * 13) & 0xFF));
    }
    return acc;
}

fn streamFixtureTagByte(protected: []const u8, index: usize) u8 {
    const seed: []const u8 = stream_fixture_tag_seed;
    return seed[index] ^ streamFixtureChecksum(protected) ^ @as(u8, @intCast(index * 17));
}

fn appendStreamFixtureTag(out: []u8, protected: []const u8) void {
    var i: usize = 0;
    while (i < tls_stream_fixture_tag_len) : (i += 1) out[i] = streamFixtureTagByte(protected, i);
}

fn verifyStreamFixtureTag(tag: []const u8, protected: []const u8) bool {
    if (tag.len != tls_stream_fixture_tag_len) return false;
    var i: usize = 0;
    while (i < tls_stream_fixture_tag_len) : (i += 1) {
        if (tag[i] != streamFixtureTagByte(protected, i)) return false;
    }
    return true;
}

fn tcpServiceStatusCode(result: *const r4os.abi.NetServiceTcpResult) u32 {
    if (result.service_status != 0) return result.service_status;
    return (result.flags & r4os.abi.net_service_status_mask) >> r4os.abi.net_service_status_shift;
}

fn tcpServiceStatusName(status: u32) []const u8 {
    return switch (status) {
        r4os.abi.net_service_status_idle => "idle",
        r4os.abi.net_service_status_pending => "pending",
        r4os.abi.net_service_status_ok => "ok",
        r4os.abi.net_service_status_timeout => "timeout",
        r4os.abi.net_service_status_failed => "failed",
        r4os.abi.net_service_status_cancelled => "cancelled",
        r4os.abi.net_service_status_would_block => "would-block",
        else => "unknown",
    };
}

fn tcpLifecycleDisconnect(lifecycle: u32) bool {
    return switch (lifecycle) {
        r4os.abi.net_service_socket_lifecycle_closed,
        r4os.abi.net_service_socket_lifecycle_reset,
        r4os.abi.net_service_socket_lifecycle_timeout,
        r4os.abi.net_service_socket_lifecycle_peer_gone,
        r4os.abi.net_service_socket_lifecycle_local_abort,
        r4os.abi.net_service_socket_lifecycle_local_close,
        r4os.abi.net_service_socket_lifecycle_bad_handle,
        r4os.abi.net_service_socket_lifecycle_owner_mismatch,
        r4os.abi.net_service_socket_lifecycle_dropped,
        => true,
        else => false,
    };
}

fn tcpLifecycleName(lifecycle: u32) []const u8 {
    return switch (lifecycle) {
        r4os.abi.net_service_socket_lifecycle_unknown => "unknown",
        r4os.abi.net_service_socket_lifecycle_active => "active",
        r4os.abi.net_service_socket_lifecycle_closed => "closed",
        r4os.abi.net_service_socket_lifecycle_reset => "reset",
        r4os.abi.net_service_socket_lifecycle_timeout => "timeout",
        r4os.abi.net_service_socket_lifecycle_peer_gone => "peer-gone",
        r4os.abi.net_service_socket_lifecycle_local_abort => "local-abort",
        r4os.abi.net_service_socket_lifecycle_local_close => "local-close",
        r4os.abi.net_service_socket_lifecycle_pending_close => "pending-close",
        r4os.abi.net_service_socket_lifecycle_would_block => "would-block",
        r4os.abi.net_service_socket_lifecycle_bad_handle => "bad-handle",
        r4os.abi.net_service_socket_lifecycle_owner_mismatch => "owner-mismatch",
        r4os.abi.net_service_socket_lifecycle_listener => "listener",
        r4os.abi.net_service_socket_lifecycle_dropped => "dropped",
        else => "unknown",
    };
}

fn withTcpServiceStatus(flags: u32, status: u32) u32 {
    return (flags & ~r4os.abi.net_service_status_mask) | (status << r4os.abi.net_service_status_shift);
}

fn writeOut(buffer: *r4os.abi.ProtocolBuffer, text: []const u8) i32 {
    const out = outputBytes(buffer) orelse return -2;
    if (text.len > out.len) return -5;
    if (text.len != 0) @memcpy(out[0..text.len], text);
    buffer.len = @intCast(text.len);
    return 0;
}

fn recordKind(content_type: u8) []const u8 {
    return switch (content_type) {
        tls_content_change_cipher_spec => "change-cipher-spec",
        tls_content_alert => "alert",
        tls_content_handshake => "handshake",
        tls_content_application_data => "application-data",
        else => "unknown",
    };
}

fn boolText(value: bool) []const u8 {
    return if (value) "yes" else "no";
}

fn cipherName(cipher: u16) []const u8 {
    return switch (cipher) {
        tls_cipher_ecdhe_rsa_aes_128_gcm_sha256 => "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
        tls_cipher_tls13_aes_128_gcm_sha256 => "TLS_AES_128_GCM_SHA256",
        else => "unknown",
    };
}

fn readBe16(bytes: []const u8) usize {
    return (@as(usize, bytes[0]) << 8) | bytes[1];
}

fn readBe24(bytes: []const u8) usize {
    return (@as(usize, bytes[0]) << 16) | (@as(usize, bytes[1]) << 8) | bytes[2];
}

fn readBe32(bytes: []const u8) usize {
    return (@as(usize, bytes[0]) << 24) | (@as(usize, bytes[1]) << 16) | (@as(usize, bytes[2]) << 8) | bytes[3];
}

fn readBe64(bytes: []const u8) u64 {
    var out: u64 = 0;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        out = (out << 8) | bytes[i];
    }
    return out;
}

fn writeBe16(out: []u8, value: u16) void {
    out[0] = @intCast(value >> 8);
    out[1] = @intCast(value & 0xFF);
}

fn writeBe24(out: []u8, value: u24) void {
    out[0] = @intCast((value >> 16) & 0xFF);
    out[1] = @intCast((value >> 8) & 0xFF);
    out[2] = @intCast(value & 0xFF);
}

fn writeBe32(out: []u8, value: u32) void {
    out[0] = @intCast((value >> 24) & 0xFF);
    out[1] = @intCast((value >> 16) & 0xFF);
    out[2] = @intCast((value >> 8) & 0xFF);
    out[3] = @intCast(value & 0xFF);
}

fn writeBe64(out: []u8, value: u64) void {
    var shift: u6 = 56;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        out[i] = @intCast((value >> shift) & 0xFF);
        if (shift == 0) break;
        shift -= 8;
    }
}

fn appendText(out: []u8, pos: *usize, text: []const u8) void {
    const room = if (out.len > pos.*) out.len - pos.* else 0;
    const n = @min(room, text.len);
    if (n != 0) @memcpy(out[pos.* .. pos.* + n], text[0..n]);
    pos.* += n;
}

fn appendU64(out: []u8, pos: *usize, value: u64) void {
    var buf: [20]u8 = undefined;
    var len: usize = 0;
    var n = value;
    if (n == 0) {
        buf[0] = '0';
        len = 1;
    } else {
        while (n != 0 and len < buf.len) : (len += 1) {
            buf[len] = @intCast('0' + (n % 10));
            n /= 10;
        }
    }
    while (len != 0) {
        len -= 1;
        appendText(out, pos, buf[len .. len + 1]);
    }
}

fn appendHex16(out: []u8, pos: *usize, value: u16) void {
    appendText(out, pos, "0x");
    var shift: u4 = 12;
    while (true) {
        const nibble: u8 = @intCast((value >> shift) & 0xF);
        const ch: u8 = if (nibble < 10) '0' + nibble else 'A' + (nibble - 10);
        appendText(out, pos, (&[_]u8{ch})[0..]);
        if (shift == 0) break;
        shift -= 4;
    }
}

fn hasHandshakeMessage(fragment: []const u8, msg_type: u8) bool {
    var pos: usize = 0;
    while (pos < fragment.len) {
        if (pos + 4 > fragment.len) return false;
        const current = fragment[pos];
        const len = readBe24(fragment[pos + 1 .. pos + 4]);
        pos += 4;
        if (pos + len > fragment.len) return false;
        if (current == msg_type) return true;
        pos += len;
    }
    return false;
}

fn serverKeyExchangeSignatureLen(fragment: []const u8) ?usize {
    var pos: usize = 0;
    while (pos < fragment.len) {
        if (pos + 4 > fragment.len) return null;
        const current = fragment[pos];
        const len = readBe24(fragment[pos + 1 .. pos + 4]);
        pos += 4;
        if (pos + len > fragment.len) return null;
        if (current == tls_handshake_server_key_exchange) {
            const body = fragment[pos .. pos + len];
            if (body.len < 1 + 2 + 1) return null;
            var body_pos: usize = 0;
            body_pos += 1;
            body_pos += 2;
            const key_len: usize = body[body_pos];
            body_pos += 1;
            if (body_pos + key_len + 4 > body.len) return null;
            body_pos += key_len;
            const scheme = readBe16(body[body_pos .. body_pos + 2]);
            body_pos += 2;
            if (scheme != tls_signature_rsa_pkcs1_sha256) return null;
            const sig_len = readBe16(body[body_pos .. body_pos + 2]);
            body_pos += 2;
            if (body_pos + sig_len != body.len) return null;
            return sig_len;
        }
        pos += len;
    }
    return null;
}

fn serverKeyExchangePublicKey(fragment: []const u8) ?[]const u8 {
    var pos: usize = 0;
    while (pos < fragment.len) {
        if (pos + 4 > fragment.len) return null;
        const current = fragment[pos];
        const len = readBe24(fragment[pos + 1 .. pos + 4]);
        pos += 4;
        if (pos + len > fragment.len) return null;
        if (current == tls_handshake_server_key_exchange) {
            const body = fragment[pos .. pos + len];
            if (body.len < 1 + 2 + 1) return null;
            var body_pos: usize = 0;
            const curve_type = body[body_pos];
            body_pos += 1;
            const named_group = readBe16(body[body_pos .. body_pos + 2]);
            body_pos += 2;
            const key_len: usize = body[body_pos];
            body_pos += 1;
            if (curve_type != 3 or named_group != tls_named_group_x25519 or key_len != X25519.public_length) return null;
            if (body_pos + key_len + 4 > body.len) return null;
            return body[body_pos .. body_pos + key_len];
        }
        pos += len;
    }
    return null;
}

fn isLegacyServerKeyPlaceholder(bytes: []const u8) bool {
    if (bytes.len != X25519.public_length) return false;
    var i: usize = 0;
    while (i < bytes.len) : (i += 1) {
        if (bytes[i] != 0x40 + @as(u8, @intCast(i))) return false;
    }
    return true;
}

fn contains(haystack: []const u8, needle: []const u8) bool {
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

fn allZero(bytes: []const u8) bool {
    var i: usize = 0;
    while (i < bytes.len) : (i += 1) {
        if (bytes[i] != 0) return false;
    }
    return true;
}

fn fillSequence(out: []u8, start: u8) void {
    var i: usize = 0;
    while (i < out.len) : (i += 1) {
        out[i] = start +% @as(u8, @intCast(i & 0xFF));
    }
}

fn startsWith(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i < needle.len) : (i += 1) {
        if (haystack[i] != needle[i]) return false;
    }
    return true;
}

fn note(comptime text: []const u8) [64]u8 {
    var out: [64]u8 = .{0} ** 64;
    @memcpy(out[0..text.len], text);
    return out;
}
