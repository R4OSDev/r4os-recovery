// Pixel assertions for QEMU P6 screendumps. No desktop/image framework needed.
using System;
using System.IO;
using System.Text;

public sealed class RecoveryFrame {
    public readonly int Width, Height, Left, Top, Right, Bottom;
    private readonly byte[] pixels;
    private readonly int imageX, imageY, imageWidth, imageHeight;

    private static string Token(byte[] data, ref int at) {
        while (at < data.Length) {
            if (data[at] == '#') { while (at < data.Length && data[at] != 10) at++; }
            else if (data[at] <= 32) at++;
            else break;
        }
        int start = at;
        while (at < data.Length && data[at] > 32) at++;
        return Encoding.ASCII.GetString(data, start, at - start);
    }

    public RecoveryFrame(string path) {
        byte[] data = File.ReadAllBytes(path);
        int at = 0;
        if (Token(data, ref at) != "P6") throw new Exception("Expected a P6 screendump.");
        Width = int.Parse(Token(data, ref at)); Height = int.Parse(Token(data, ref at));
        if (Token(data, ref at) != "255" || at >= data.Length) throw new Exception("Invalid PPM header.");
        if (data[at++] == 13 && at < data.Length && data[at] == 10) at++;
        int count = checked(Width * Height * 3);
        if (Width < 1 || Height < 1 || data.Length - at != count) throw new Exception("Invalid PPM dimensions.");
        pixels = new byte[count]; Array.Copy(data, at, pixels, 0, count);
        imageWidth = (int)Math.Min(Width, (long)Height * 1672 / 941);
        imageHeight = imageWidth * 941 / 1672;
        imageX = (Width - imageWidth) / 2; imageY = (Height - imageHeight) / 2;
        Left = imageX + (imageWidth * 391 + 1671) / 1672;
        Top = imageY + (imageHeight * 223 + 940) / 941;
        Right = imageX + imageWidth * 1284 / 1672;
        Bottom = imageY + imageHeight * 680 / 941;
    }

    private bool Inside(int x, int y) { return x >= Left && x < Right && y >= Top && y < Bottom; }

    public void RequireArtwork(string bmp) {
        byte[] source = File.ReadAllBytes(bmp);
        if (source.Length != 4720110 || source[0] != 'B' || source[1] != 'M') throw new Exception("Unexpected Recovery artwork.");
        int offset = BitConverter.ToInt32(source, 10), stride = (1672 * 3 + 3) & ~3;
        for (int y = 0; y < Height; y++) for (int x = 0; x < Width; x++) {
            if (Inside(x, y)) continue;
            int rgb = (y * Width + x) * 3;
            bool image = x >= imageX && x < imageX + imageWidth && y >= imageY && y < imageY + imageHeight;
            int sourcePixel = image ? offset + (940 - (y - imageY) * 941 / imageHeight) * stride + (x - imageX) * 1672 / imageWidth * 3 : 0;
            for (int c = 0; c < 3; c++) if (pixels[rgb + c] != (image ? source[sourcePixel + 2 - c] : 0))
                throw new Exception("Artwork differs outside monitor at " + x + "," + y + ".");
        }
    }

    public void RequireOutsideUnchanged(RecoveryFrame baseline) {
        if (Width != baseline.Width || Height != baseline.Height) throw new Exception("Framebuffer dimensions changed.");
        for (int y = 0; y < Height; y++) for (int x = 0; x < Width; x++) {
            if (Inside(x, y)) continue;
            int at = (y * Width + x) * 3;
            for (int c = 0; c < 3; c++) if (pixels[at + c] != baseline.pixels[at + c])
                throw new Exception("Console escaped monitor at " + x + "," + y + ".");
        }
    }

    public int RedRow() {
        for (int y = Top; y < Bottom; y++) {
            int count = 0;
            for (int x = Left; x < Right; x++) {
                int at = (y * Width + x) * 3;
                if (pixels[at] == 0xd9 && pixels[at + 1] == 0x35 && pixels[at + 2] == 0x2d) count++;
            }
            if (count > (Right - Left) / 2) return y;
        }
        throw new Exception("No red selection bar in monitor.");
    }

    public void RequireContentChanged(RecoveryFrame previous) {
        int count = 0;
        for (int y = Top; y < Bottom; y++) for (int x = Left; x < Right; x++) {
            int at = (y * Width + x) * 3;
            if (pixels[at] != previous.pixels[at] || pixels[at + 1] != previous.pixels[at + 1] || pixels[at + 2] != previous.pixels[at + 2]) count++;
        }
        if (count < 30) throw new Exception("Expected console content did not change.");
    }
}
