#!/usr/bin/python
# -*- coding:utf-8 -*-
import sys
import os
import time
from PIL import Image, ImageDraw, ImageFont
import traceback

# Ellenőrizzük, hogy a megfelelő könyvtárban vagyunk-e
libdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'lib')
if os.path.exists(libdir):
    sys.path.append(libdir)

# Importáljuk a Waveshare e-Paper könyvtárat
# Ha a könyvtár még nem található, telepítsd a példák és könyvtárak letöltésével a Waveshare oldalról
from waveshare_epd import epd3in01f

try:
    # Inicializáljuk a kijelzőt
    epd = epd3in01f.EPD()
    print("Kijelző inicializálása...")
    epd.init()
    
    # Töröljük a kijelzőt (fehérre állítjuk)
    print("Kijelző törlése...")
    epd.Clear()
    time.sleep(1)
    
    # Létrehozunk egy új képet a kijelző méretével
    print("Kép létrehozása...")
    width = epd.width
    height = epd.height
    image = Image.new('RGB', (width, height), 0xFFFFFF)  # 255: fehér
    
    # Inicializáljuk a rajzoló objektumot
    draw = ImageDraw.Draw(image)
    
    # Font betöltése
    font24 = ImageFont.truetype('Font.ttc', 24)
    font18 = ImageFont.truetype('Font.ttc', 18)
    
    # Rajzolunk különböző színeket (ezt a kijelző támogatja)
    # Színek: fekete, fehér, piros, sárga, kék
    print("Rajzolás a kijelzőre...")
    
    # Szöveg kiírása
    draw.text((10, 10), 'Waveshare E-Paper Teszt', font=font24, fill=0x000000)  # fekete
    draw.text((10, 40), 'Minden működik!', font=font18, fill=0xFF0000)  # piros
    
    # Vonalak rajzolása
    draw.line([(10, 90), (width-10, 90)], fill=0x0000FF, width=3)  # kék vonal
    
    # Négyzet rajzolása
    draw.rectangle([(10, 100), (110, 200)], outline=0xFF0000, width=2)  # piros keret
    
    # Kitöltött kör rajzolása
    draw.ellipse([(150, 100), (250, 200)], fill=0xFFFF00)  # sárga kör
    
    # Kiírjuk a dátumot és időt
    draw.text((10, height-30), time.strftime("%Y-%m-%d %H:%M:%S"), font=font18, fill=0x000000)
    
    # Kép megjelenítése a kijelzőn
    print("Kép frissítése a kijelzőn...")
    epd.display(epd.getbuffer(image))
    print("Kész!")
    
    # Alvó módba kapcsoljuk a kijelzőt az energiatakarékosság érdekében
    print("Alvó mód bekapcsolása...")
    epd.sleep()
    
except Exception as e:
    print('Hiba:')
    print(e)
    traceback.print_exc()
    exit()
