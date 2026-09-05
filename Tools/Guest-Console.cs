using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

// Paced real-console acceptance. Output is drained while the guest waits for
// input; each wait has its own deadline and retains the transcript on failure.
public sealed class RecoveryConsole : IDisposable {
    readonly Process process = new Process();
    readonly StringBuilder output = new StringBuilder();
    readonly object gate = new object();
    readonly Task stdout, stderr;
    public RecoveryConsole(string executable, string[] arguments, string askpass) {
        var start = new ProcessStartInfo(executable) {
            UseShellExecute = false, RedirectStandardInput = true,
            RedirectStandardOutput = true, RedirectStandardError = true
        };
        start.Environment["SSH_ASKPASS"] = askpass;
        start.Environment["SSH_ASKPASS_REQUIRE"] = "force";
        start.Environment["DISPLAY"] = "r4part-acceptance";
        foreach (var argument in arguments) start.ArgumentList.Add(argument);
        process.StartInfo = start;
        if (!process.Start()) throw new IOException("Console client did not start.");
        stdout = Drain(process.StandardOutput);
        stderr = Drain(process.StandardError);
    }
    async Task Drain(StreamReader reader) {
        var buffer = new char[4096];
        for (;;) {
            int count = await reader.ReadAsync(buffer, 0, buffer.Length);
            if (count == 0) return;
            lock (gate) {
                if (output.Length + count > 16 * 1024 * 1024)
                    throw new IOException("Console transcript exceeded its bound.");
                output.Append(buffer, 0, count);
            }
        }
    }
    public string Output { get { lock (gate) return output.ToString(); } }
    public void Send(string input) { process.StandardInput.Write(input); process.StandardInput.Flush(); }
    public string Wait(string pattern, int start, int timeoutMilliseconds) {
        var watch = Stopwatch.StartNew();
        for (;;) {
            var text = Output;
            if (Regex.IsMatch(text.Substring(Math.Min(start, text.Length)), pattern)) return text;
            if (process.HasExited || watch.ElapsedMilliseconds >= timeoutMilliseconds)
                throw new IOException("Missing console output: " + pattern + "\n" + text);
            Thread.Sleep(20);
        }
    }
    public int Finish(int timeoutMilliseconds) {
        process.StandardInput.Close();
        if (!process.WaitForExit(timeoutMilliseconds)) throw new IOException("Console did not exit.\n" + Output);
        Task.WaitAll(stdout, stderr);
        return process.ExitCode;
    }
    public void Dispose() {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(); }
        Task.WaitAll(stdout, stderr);
        process.Dispose();
    }
}
