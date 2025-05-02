#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os
from waveshare_epd import epd3in01f  # illesztőmodul
from PIL import Image, ImageDraw, ImageFont
import time

def main():
    # 1. Inicializálás
    epd = epd3in01f.EPD()
    epd.init(epd.FULL_UPDATE)
    epd.Clear(0xFF)  # fehér háttér

    # 2. Kép létrehozása
    width, height = epd.height, epd.width  # elforgatott felbontás (128×296)
    image = Image.new('1', (width, height), 255)  # 1 bit/pixel, fehér
    draw = ImageDraw.Draw(image)

    # 3. Szöveg rajzolása
    font = ImageFont.load_default()
    text = "Hello, World!"
    # középre igazítás
    (w, h) = draw.textsize(text, font=font)
    x = (width - w) // 2
    y = (height - h) // 2
    draw.text((x, y), text, font=font, fill=0)  # fekete szöveg

    # 4. Kirajzolás a kijelzőre
    epd.display(epd.getbuffer(image))
    time.sleep(5)

    # 5. Várakozás majd beállítás alvó módba
    epd.sleep()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit()

