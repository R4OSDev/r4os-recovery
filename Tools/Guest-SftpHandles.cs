// Host-side, bounded SFTP-v3 handle witness over the installed OpenSSH client.
// Keeps real server handles open while a second session exercises storage.
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;

public sealed class RecoverySftpHandles : IDisposable {
    readonly Process process;
    readonly Task<string> errors;
    readonly Stream input, output;
    uint sequence;
    byte[] handle;
    public RecoverySftpHandles(string ssh, string[] arguments, string askpass) {
        var start = new ProcessStartInfo(ssh) { UseShellExecute = false, RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true };
        start.Environment["SSH_ASKPASS"] = askpass;
        start.Environment["SSH_ASKPASS_REQUIRE"] = "force";
        start.Environment["DISPLAY"] = "recovery-storage-acceptance";
        foreach (var argument in arguments) start.ArgumentList.Add(argument);
        process = Process.Start(start) ?? throw new IOException("SSH did not start");
        input = process.StandardInput.BaseStream; output = process.StandardOutput.BaseStream;
        errors = process.StandardError.ReadToEndAsync();
        try {
            Send(new byte[] { 1, 0, 0, 0, 3 });
            var version = Receive();
            if (version.Length < 5 || version[0] != 2 || U32(version, 1) != 3) throw new IOException("SFTP v3 was not negotiated");
        } catch { Dispose(); throw; }
    }
    static uint U32(byte[] data, int offset) {
        if (offset < 0 || offset + 4 > data.Length) throw new IOException("Truncated SFTP integer");
        return ((uint)data[offset] << 24) | ((uint)data[offset+1] << 16) | ((uint)data[offset+2] << 8) | data[offset+3];
    }
    static void Put32(Stream stream, uint value) {
        stream.WriteByte((byte)(value >> 24)); stream.WriteByte((byte)(value >> 16)); stream.WriteByte((byte)(value >> 8)); stream.WriteByte((byte)value);
    }
    static void PutString(Stream stream, byte[] value) { Put32(stream, (uint)value.Length); stream.Write(value, 0, value.Length); }
    void Send(byte[] packet) { Put32(input, (uint)packet.Length); input.Write(packet, 0, packet.Length); input.Flush(); }
    void ReadExactly(byte[] data) {
        int offset = 0;
        while (offset < data.Length) {
            var pending = output.ReadAsync(data, offset, data.Length-offset);
            if (!pending.Wait(10000)) throw new IOException("SFTP reply timed out");
            int got = pending.GetAwaiter().GetResult();
            if (got == 0) throw new IOException("SFTP channel closed before reply");
            offset += got;
        }
    }
    byte[] Receive() {
        var size = new byte[4]; ReadExactly(size); uint count = U32(size, 0);
        if (count < 1 || count > 65536) throw new IOException("Invalid SFTP packet size");
        var packet = new byte[(int)count]; ReadExactly(packet); return packet;
    }
    byte[] Reply(MemoryStream request, uint id) {
        Send(request.ToArray()); var response = Receive();
        if (response.Length < 5 || U32(response, 1) != id) throw new IOException("SFTP reply ID mismatch");
        return response;
    }
    public uint Open(string path, bool write, bool directory) {
        if (handle != null) throw new InvalidOperationException("Handle already open");
        using var request = new MemoryStream(); uint id = ++sequence;
        request.WriteByte(directory ? (byte)11 : (byte)3); Put32(request, id); PutString(request, Encoding.UTF8.GetBytes(path));
        if (!directory) { Put32(request, write ? 26u : 1u); Put32(request, 0); }
        var response = Reply(request, id);
        if (response[0] == 101) return U32(response, 5);
        if (response[0] != 102) throw new IOException("Expected a real SFTP handle");
        uint len = U32(response, 5);
        if (len == 0 || len > 256 || response.Length != 9+len) throw new IOException("Invalid SFTP handle");
        handle = new byte[(int)len]; Array.Copy(response, 9, handle, 0, (int)len); return 0;
    }
    public uint CloseHandle() {
        if (handle == null) throw new InvalidOperationException("No open handle");
        using var request = new MemoryStream(); uint id = ++sequence;
        request.WriteByte(4); Put32(request, id); PutString(request, handle);
        var response = Reply(request, id);
        if (response[0] != 101) throw new IOException("Expected close status");
        uint status = U32(response, 5); if (status == 0) handle = null; return status;
    }
    public void Dispose() {
        try { if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); } }
        finally { process.Dispose(); }
    }
}
