#!/usr/bin/env python3
"""Draws the fork's neutral app icon (no third-party deps) and writes
fork/overlay/Resources/AppIcon.png, AppIcon.icns and logo-white.png.

A dark rounded square with a notch cut out of the top edge and three white
equalizer bars, matching fork/overlay/Sources/Lenotch/UI/LogoShape.swift.

    python3 fork/make_icon.py
"""
import pathlib
import struct
import zlib

OUT = pathlib.Path(__file__).resolve().parent / "overlay" / "Resources"
SIZE = 1024
SS = 2  # supersampling per axis


def rounded_rect(px, py, x0, y0, x1, y1, r):
    if px < x0 or px > x1 or py < y0 or py > y1:
        return False
    cx = min(max(px, x0 + r), x1 - r)
    cy = min(max(py, y0 + r), y1 - r)
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r


# Icon body (Apple's grid: 824pt square centred in 1024, ~185 radius).
BODY = (100, 100, 924, 924, 185)
# Notch cut into the top edge, with rounded bottom corners.
NOTCH = (340, 60, 684, 195, 45)
# Equalizer bars: same proportions as LogoShape (aspect 223/256), 380 tall.
BAR_H = 380
BAR_W_TOTAL = BAR_H * 223 / 256
BAR_X0 = 512 - BAR_W_TOTAL / 2
BAR_BOTTOM = 512 + BAR_H / 2 + 40
BARS = [(0, 0.26, 0.55), (0.37, 0.26, 1), (0.74, 0.26, 0.75)]


def sample(px, py):
    """Returns (r, g, b, a) floats for one sample point."""
    if not rounded_rect(px, py, *BODY) or rounded_rect(px, py, *NOTCH):
        return (0, 0, 0, 0)
    for x, w, h in BARS:
        bx0 = BAR_X0 + x * BAR_W_TOTAL
        bw = w * BAR_W_TOTAL
        bh = h * BAR_H
        if rounded_rect(px, py, bx0, BAR_BOTTOM - bh, bx0 + bw, BAR_BOTTOM, bw / 2):
            shade = 1 - 0.12 * (py - (BAR_BOTTOM - BAR_H)) / BAR_H
            return (255 * shade, 255 * shade, 255 * shade, 255)
    t = (py - 100) / 824
    return (30 - 12 * t, 35 - 13 * t, 48 - 18 * t, 255)


def render(size):
    scale = SIZE / size
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            acc = [0.0, 0.0, 0.0, 0.0]
            for sy in range(SS):
                for sx in range(SS):
                    r, g, b, a = sample((x + (sx + 0.5) / SS) * scale, (y + (sy + 0.5) / SS) * scale)
                    acc[0] += r * a
                    acc[1] += g * a
                    acc[2] += b * a
                    acc[3] += a
            n = SS * SS
            alpha = acc[3] / n
            if alpha:
                row += bytes(round(c / acc[3]) for c in acc[:3]) + bytes([round(alpha)])
            else:
                row += b"\0\0\0\0"
        rows.append(bytes(row))
    return rows


def png(rows, width, height):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    raw = b"".join(b"\0" + row for row in rows)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def white_glyph(height):
    """logo-white.png: the bars alone, white on transparent."""
    width = round(height * 223 / 256)
    rows = []
    for y in range(height):
        row = bytearray()
        for x in range(width):
            hits = 0
            for sy in range(4):
                for sx in range(4):
                    px = x + (sx + 0.5) / 4
                    py = y + (sy + 0.5) / 4
                    for bx, bw, bh in BARS:
                        x0, w, h = bx * width, bw * width, bh * height
                        if rounded_rect(px, py, x0, height - h, x0 + w, height, w / 2):
                            hits += 1
                            break
            row += bytes([255, 255, 255, round(255 * hits / 16)])
        rows.append(bytes(row))
    return rows, width


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for kind, size in [(b"ic10", 1024), (b"ic09", 512), (b"ic08", 256), (b"ic07", 128), (b"ic14", 512),
                       (b"ic13", 256), (b"ic12", 64), (b"ic11", 32)]:
        data = png(render(size), size, size)
        if size == 1024:
            (OUT / "AppIcon.png").write_bytes(data)
        entries.append(kind + struct.pack(">I", len(data) + 8) + data)
        print("rendered", kind.decode(), size)
    body = b"".join(entries)
    (OUT / "AppIcon.icns").write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
    rows, width = white_glyph(256)
    (OUT / "logo-white.png").write_bytes(png(rows, width, 256))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
