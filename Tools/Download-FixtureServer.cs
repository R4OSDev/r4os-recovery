// Local, bounded HTTP responses for the shared guest streaming implementation.
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Collections.Concurrent;

public sealed class RecoveryDownloadFixtureServer : IDisposable {
    readonly TcpListener listener;
    readonly string root;
    readonly Thread thread;
    volatile bool stopped;
    public readonly ConcurrentQueue<string> Requests = new ConcurrentQueue<string>();
    public int Retry3Count;
    public int Retry4Count;
    public int Port { get; }
    public RecoveryDownloadFixtureServer(string directory) {
        root = Path.GetFullPath(directory);
        listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start(); Port = ((IPEndPoint)listener.LocalEndpoint).Port;
        thread = new Thread(Accept) { IsBackground = true }; thread.Start();
    }
    void Accept() {
        while (!stopped) {
            try { var client = listener.AcceptTcpClient(); ThreadPool.QueueUserWorkItem(_ => Serve(client)); }
            catch (SocketException) { if (!stopped) throw; }
        }
    }
    static void Header(Stream stream, int status, long bytes, string extra = "") {
        var text = Encoding.ASCII.GetBytes("HTTP/1.1 " + status + " Fixture\r\nContent-Length: " + bytes + "\r\nConnection: close\r\n" + extra + "\r\n");
        stream.Write(text, 0, text.Length);
    }
    void Serve(TcpClient client) {
        using (client) {
            try {
                using (var stream = client.GetStream()) {
                    stream.ReadTimeout = 15000; stream.WriteTimeout = 15000;
                    var header = new byte[16384]; int count = 0;
                    while (count < header.Length) {
                        int next = stream.ReadByte(); if (next < 0) return; header[count++] = (byte)next;
                        if (count >= 4 && header[count-4] == 13 && header[count-3] == 10 && header[count-2] == 13 && header[count-1] == 10) break;
                    }
                    if (count == header.Length) return;
                    string request = Encoding.ASCII.GetString(header, 0, count);
                    string[] first = request.Split('\n')[0].Trim().Split(' ');
                    if (first.Length != 3 || first[0] != "GET") { Header(stream, 400, 0); return; }
                    string name = first[1].TrimStart('/');
                    if (name.IndexOfAny(new [] {'/', '\\', '?', '%', ':'}) >= 0 || name.Contains("..")) { Header(stream, 400, 0); return; }
                    Requests.Enqueue(request.Trim());
                    if (name == "redirect.zip") { Header(stream, 302, 0, "Location: /good.zip\r\n"); return; }
                    bool truncated = name == "truncated.zip";
                    bool corrupt = name == "wrong.zip";
                    bool retry3 = name == "retry3.zip";
                    bool retry4 = name == "retry4.zip";
                    string path = Path.Combine(root, truncated || corrupt || retry3 || retry4 ? "good.zip" : name);
                    if (!File.Exists(path)) { Header(stream, 404, 0); return; }
                    using (var file = File.OpenRead(path)) {
                        long start = 0;
                        if (retry3 || retry4) {
                            foreach (string line in request.Split('\n')) {
                                if (!line.StartsWith("Range:", StringComparison.OrdinalIgnoreCase)) continue;
                                string value = line.Substring(6).Trim();
                                if (!value.StartsWith("bytes=", StringComparison.OrdinalIgnoreCase) || !value.EndsWith("-") ||
                                    !long.TryParse(value.Substring(6, value.Length - 7), out start) || start <= 0 || start >= file.Length) {
                                    Header(stream, 416, 0); return;
                                }
                            }
                        }
                        string extra = "Content-Type: application/octet-stream\r\n";
                        if (start != 0) extra += "Content-Range: bytes " + start + "-" + (file.Length - 1) + "/" + file.Length + "\r\n";
                        Header(stream, start == 0 ? 200 : 206, file.Length - start, extra);
                        file.Position = start;
                        int attempt = retry3 ? Interlocked.Increment(ref Retry3Count) : retry4 ? Interlocked.Increment(ref Retry4Count) : 0;
                        bool drop = (retry3 && attempt <= 3) || (retry4 && attempt <= 4);
                        var buffer = new byte[65536]; long sent = 0;
                        while (!stopped) {
                            int amount = file.Read(buffer, 0, truncated || drop ? 4096 : buffer.Length);
                            if (amount == 0) break;
                            if (corrupt && sent == 0) buffer[0] ^= 1;
                            stream.Write(buffer, 0, amount); sent += amount;
                            if (truncated || drop) break;
                        }
                        stream.Flush();
                    }
                }
            } catch (IOException) { } catch (SocketException) { } catch (ObjectDisposedException) { }
        }
    }
    public void Dispose() { stopped = true; listener.Stop(); thread.Join(2000); }
}
