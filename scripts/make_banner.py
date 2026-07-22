#!/usr/bin/env python3
"""
Generate YouTube channel banner.
Adjust the PARAMS dict, then run:  python3 scripts/make_banner.py
Output: ~/Desktop/channel-banner.png  (2048x1152)
"""

from PIL import Image, ImageDraw, ImageFont
import subprocess, os

# ─── ADJUST THESE NUMBERS ─────────────────────────────────
# These come from the mockup: https://catchtales.com/banner-mockup.html
PARAMS = {
    # Logo
    'logo_height': 192,     # Logo height in mockup (px)
    'logo_x': 203,          # Logo X position in mockup (px from left)
    'logo_y': 180,          # Logo Y position in mockup (px from top)
    # Text
    'text_x': 700,          # Text right edge X in mockup (px from left)
    'text_y': 225,          # Text Y position in mockup (px from top)
    # Font sizes (original sizes, not mockup scale)
    'font_size_1': 48,      # "For Bragging Rights!"
    'font_size_2': 30,      # "Canada & United States"
    'font_size_3': 40,      # "catchtales.com"
    # Text content
    'line1': 'For Bragging Rights!',
    'line2': 'Canada & United States',
    'line3': 'catchtales.com',
    # Colors
    'color1': '#B0C4DE',   # Line 1
    'color2': '#00BCD4',   # Line 2
    'color3': '#FFFFFF',   # Line 3
    # Overlay
    'overlay_opacity': '0.55',
}
# ───────────────────────────────────────────────────────────

def banner(params):
    S = 2048 / 960  # scale from mockup (960) to banner (2048)
    W, H = 2048, 1152

    logo_h = round(params['logo_height'] * S)
    logo_x = round(params['logo_x'] * S)
    logo_y = round(params['logo_y'] * S)
    text_right_x = W - round((960 - params['text_x']) * S)
    text_y = round(params['text_y'] * S)

    print(f"Logo: {logo_h}h at ({logo_x}, {logo_y})")
    print(f"Text: right edge at x={text_right_x}, y={text_y}")
    print(f"Font sizes: {params['font_size_1']}/{params['font_size_2']}/{params['font_size_3']}")

    # Background
    subprocess.run([
        'convert', '/home/louis/catchtales-site/underwater.webp',
        '-resize', f'{W}x{H}^', '-gravity', 'Center', '-extent', f'{W}x{H}',
        '-fill', f'rgba(10,22,40,{params["overlay_opacity"]})',
        '-draw', 'rectangle 0,0 2048,1152',
        '/tmp/ct-banner-bg.png'
    ], check=True, capture_output=True)

    # Logo
    subprocess.run([
        'convert', '/home/louis/CatchTales/assets/catchtales.png',
        '-trim', '+repage', '-resize', f'x{logo_h}',
        '/tmp/ct-banner-logo.png'
    ], check=True, capture_output=True)

    subprocess.run([
        'convert', '/tmp/ct-banner-bg.png',
        '/tmp/ct-banner-logo.png', '-geometry', f'+{logo_x}+{logo_y}',
        '-composite', '/tmp/ct-banner-bg.png'
    ], check=True, capture_output=True)

    # Text with Pillow
    img = Image.open('/tmp/ct-banner-bg.png').convert('RGBA')
    draw = ImageDraw.Draw(img)

    font1 = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', params['font_size_1'])
    font2 = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', params['font_size_2'])
    font3 = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', params['font_size_3'])

    lines = [
        (params['line1'], font1, params['color1'], 0),
        (params['line2'], font2, params['color2'], 55),
        (params['line3'], font3, params['color3'], 105),
    ]

    for text, fnt, color, y_off in lines:
        bbox = draw.textbbox((0, 0), text, font=fnt)
        w = bbox[2] - bbox[0]
        x = text_right_x - w
        draw.text((x, text_y + y_off), text, fill=color, font=fnt)
        print(f"  '{text}' at ({x}, {text_y + y_off})")

    out = '/home/louis/Desktop/channel-banner.png'
    img.save(out, 'PNG')
    print(f"\nSaved: {out} ({img.size})")

    # Cleanup
    for f in ['/tmp/ct-banner-bg.png', '/tmp/ct-banner-logo.png']:
        if os.path.exists(f): os.remove(f)

if __name__ == '__main__':
    banner(PARAMS)
