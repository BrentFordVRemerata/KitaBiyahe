"""Export native icon formats from the checked-in, generated transparent mark.

Requires Pillow. Does not redraw or retouch the generated symbol.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
MARK = ROOT / 'assets/brand/mark.png'


def launcher_tile(size):
    canvas = Image.new('RGBA', (size, size))
    inset = round(size * .075)
    ImageDraw.Draw(canvas).rounded_rectangle(
        (inset, inset, size - inset - 1, size - inset - 1),
        radius=round(size * .19), fill='#F8F8F1')
    mark = Image.open(MARK).convert('RGBA').resize((size, size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark)
    return canvas


def main():
    tile = launcher_tile(1024)
    tile.save(ROOT / 'windows/runner/resources/app_icon.ico', format='ICO',
              sizes=[(n, n) for n in (16, 20, 24, 32, 40, 48, 64, 128, 256)])
    res = ROOT / 'android/app/src/main/res'
    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        folder = res / f'mipmap-{density}'
        folder.mkdir(exist_ok=True)
        tile.resize((size, size), Image.Resampling.LANCZOS).save(folder / 'ic_launcher.png')
    folder = res / 'drawable-nodpi'
    folder.mkdir(exist_ok=True)
    Image.open(MARK).resize((512, 512), Image.Resampling.LANCZOS).save(folder / 'kitabiyahe_mark.png')
    print('Exported Windows ICO and Android launcher PNGs from the generated mark.')


if __name__ == '__main__':
    main()
