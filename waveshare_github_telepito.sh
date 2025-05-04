#!/bin/bash

# Waveshare e-Paper GitHub Telepítő
echo "==== Waveshare e-Paper GitHub Telepítő ===="

# Aktuális felhasználó és könyvtárak meghatározása
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/waveshare-epaper"

echo "Telepítés felhasználó: $CURRENT_USER"
echo "Telepítési könyvtár: $INSTALL_DIR"

# Csomagkezelő frissítése
echo "Csomagkezelő frissítése..."
sudo apt-get update

# Szükséges csomagok telepítése
echo "Szükséges csomagok telepítése..."
sudo apt-get install -y python3-pip python3-pil python3-numpy git python3-rpi.gpio python3-spidev

# SPI interfész engedélyezése
echo "SPI interfész ellenőrzése és engedélyezése..."
if ! grep -q "^dtparam=spi=on" /boot/config.txt; then
    echo "SPI interfész engedélyezése..."
    sudo bash -c "echo 'dtparam=spi=on' >> /boot/config.txt"
    REBOOT_NEEDED=true
else
    echo "Az SPI interfész már engedélyezve van."
fi

# Telepítési könyvtár létrehozása
echo "Telepítési könyvtár létrehozása..."
sudo rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

# Waveshare GitHub repo klónozása
echo "Waveshare GitHub repo klónozása..."
cd /tmp
sudo rm -rf e-Paper
git clone https://github.com/waveshare/e-Paper.git

# Szükséges könyvtárak másolása
echo "Szükséges könyvtárak másolása..."
cp -r e-Paper/RaspberryPi_JetsonNano/python/lib/waveshare_epd $INSTALL_DIR/
cp -r e-Paper/RaspberryPi_JetsonNano/python/examples $INSTALL_DIR/
cp -r e-Paper/RaspberryPi_JetsonNano/python/pic $INSTALL_DIR/

# Jogosultságok beállítása
echo "Jogosultságok beállítása..."
sudo chown -R $CURRENT_USER:$CURRENT_GROUP $INSTALL_DIR

# Teszt program létrehozása
echo "Teszt program létrehozása..."
cat > $INSTALL_DIR/epaper_test.py << 'EOL'
#!/usr/bin/env python3
import os
import sys
import time
import logging
from PIL import Image, ImageDraw, ImageFont

# Az aktuális könyvtárat adjuk hozzá az elérési úthoz
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Logging beállítása
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger()

try:
    # Waveshare könyvtár betöltése
    logger.info("Waveshare e-Paper könyvtár betöltése...")
    from waveshare_epd import epd4in01f
    logger.info("Könyvtár sikeresen betöltve!")

    logger.info("E-Paper kijelző inicializálása...")
    epd = epd4in01f.EPD()
    epd.init()
    
    logger.info("Képernyő törlése...")
    epd.Clear()
    
    # Teszt kép létrehozása
    logger.info("Teszt kép létrehozása...")
    image = Image.new('RGB', (epd.width, epd.height), 'white')
    draw = ImageDraw.Draw(image)
    
    # Keretek rajzolása
    draw.rectangle((0, 0, epd.width, epd.height), outline='black')
    draw.rectangle((10, 10, epd.width-10, epd.height-10), outline='red')
    
    # Betűtípus beállítása
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 36)
    except:
        font = ImageFont.load_default()
    
    # Szöveg kiírása
    draw.text((120, 80), 'Waveshare', font=font, fill='black')
    draw.text((120, 150), 'e-Paper Kijelző', font=font, fill='red')
    draw.text((120, 220), 'GitHub Telepítés', font=font, fill='blue')
    draw.text((120, 290), f'Idő: {time.strftime("%Y-%m-%d %H:%M:%S")}', font=font, fill='green')
    
    # Kép megjelenítése
    logger.info("Kép megjelenítése...")
    epd.display(epd.getbuffer(image))
    logger.info("Kész! A teszt sikeresen lefutott.")
    
except Exception as e:
    logger.error(f"Hiba: {e}")
    import traceback
    logger.error(traceback.format_exc())
EOL

# Naptár alkalmazás létrehozása
echo "Naptár alkalmazás létrehozása..."
cat > $INSTALL_DIR/calendar_display.py << 'EOL'
#!/usr/bin/env python3
import os
import sys
import time
import logging
import locale
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Az aktuális könyvtárat adjuk hozzá az elérési úthoz
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Logging beállítása
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(os.path.dirname(os.path.abspath(__file__)), "calendar.log")),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger()

# Frissítési intervallum (percben)
REFRESH_INTERVAL = 5

# Magyar lokalizáció beállítása
try:
    locale.setlocale(locale.LC_TIME, "hu_HU.UTF-8")
except:
    try:
        locale.setlocale(locale.LC_TIME, "hu_HU")
    except:
        logger.warning("Nem sikerült beállítani a magyar lokalizációt")

def create_calendar_image(width, height):
    """Naptár kép létrehozása"""
    try:
        # Kép létrehozása
        image = Image.new('RGB', (width, height), 'white')
        draw = ImageDraw.Draw(image)
        
        # Betűtípusok beállítása
        try:
            font_large = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 48)
            font_medium = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 36)
            font_small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 24)
        except:
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
            font_small = ImageFont.load_default()
        
        # Keret rajzolása
        draw.rectangle((0, a0, width, height), outline='black')
        
        # Aktuális dátum és idő
        now = datetime.now()
        date_str = now.strftime("%Y. %B %d.")
        day_str = now.strftime("%A")
        time_str = now.strftime("%H:%M:%S")
        
        # Fejléc
        draw.rectangle((0, 0, width, 60), fill='blue')
        draw.text((width//2, 30), "NAPTÁR", font=font_large, fill='white', anchor="mm")
        
        # Dátum és idő
        draw.text((width//2, 100), time_str, font=font_large, fill='black', anchor="mm")
        draw.text((width//2, 160), date_str, font=font_medium, fill='black', anchor="mm")
        draw.text((width//2, 210), day_str, font=font_medium, fill='black', anchor="mm")
        
        # Vonal
        draw.line((50, 250, width-50, 250), fill='red', width=3)
        
        # Mai nap információ
        month_days = {
            1: 31, 2: 29 if now.year % 4 == 0 else 28, 3: 31, 4: 30, 5: 31, 6: 30,
            7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
        }
        day_of_year = now.timetuple().tm_yday
        days_left = 366 if now.year % 4 == 0 else 365
        days_left -= day_of_year
        
        draw.text((width//2, 280), f"Az év {day_of_year}. napja", font=font_small, fill='blue', anchor="mm")
        draw.text((width//2, 320), f"Még {days_left} nap van hátra az évből", font=font_small, fill='blue', anchor="mm")
        
        # Következő frissítés
        draw.text((width//2, height-50), f"Következő frissítés: {REFRESH_INTERVAL} perc múlva", 
                 font=font_small, fill='gray', anchor="mm")
        
        return image
    except Exception as e:
        logger.error(f"Hiba a naptár kép létrehozásakor: {e}")
        return None

def main():
    """Fő program"""
    try:
        # Waveshare könyvtár betöltése
        logger.info("Waveshare e-Paper könyvtár betöltése...")
        from waveshare_epd import epd4in01f
        
        # E-Paper inicializálása
        logger.info("E-Paper inicializálása...")
        epd = epd4in01f.EPD()
        epd.init()
        
        # Végtelen ciklus a kijelző frissítéséhez
        while True:
            try:
                # Naptár kép létrehozása
                logger.info("Naptár kép létrehozása...")
                image = create_calendar_image(epd.width, epd.height)
                
                # Kép megjelenítése
                logger.info("Kép megjelenítése...")
                epd.display(epd.getbuffer(image))
                
                # Várakozás a következő frissítésig
                logger.info(f"Várakozás {REFRESH_INTERVAL} percet...")
                time.sleep(REFRESH_INTERVAL * 60)
                
            except KeyboardInterrupt:
                logger.info("Program leállítva")
                break
            except Exception as e:
                logger.error(f"Hiba a ciklusban: {e}")
                time.sleep(60)  # Hiba esetén várunk 1 percet, majd újrapróbáljuk
        
    except Exception as e:
        logger.error(f"Hiba: {e}")
        import traceback
        logger.error(traceback.format_exc())

if __name__ == "__main__":
    logger.info("Naptár alkalmazás indítása...")
    main()
EOL

# Szolgáltatás létrehozása a naptár alkalmazáshoz
echo "Szolgáltatás létrehozása..."
sudo bash -c "cat > /etc/systemd/system/waveshare-calendar.service << EOL
[Unit]
Description=Waveshare e-Paper Calendar Display
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/calendar_display.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL"

# Jogosultságok beállítása
echo "Jogosultságok beállítása..."
chmod +x $INSTALL_DIR/epaper_test.py
chmod +x $INSTALL_DIR/calendar_display.py
sudo chmod 644 /etc/systemd/system/waveshare-calendar.service

# Teszt futtatása
echo "Teszt program futtatása..."
cd $INSTALL_DIR
python3 epaper_test.py

# Szolgáltatás indítása
echo "Szolgáltatás beállítása..."
sudo systemctl daemon-reload
sudo systemctl enable waveshare-calendar.service
sudo systemctl start waveshare-calendar.service

echo "==== Telepítés befejezve ===="
if [ "$REBOOT_NEEDED" = "true" ]; then
    echo "Az SPI interfész engedélyezéséhez újra kell indítani a rendszert."
    echo "Szeretnéd most újraindítani? (i/n)"
    read restart_now
    if [ "$restart_now" = "i" ]; then
        sudo reboot
    else
        echo "Ne felejtsd el később újraindítani a rendszert: sudo reboot"
    fi
else
    echo "A teszt kép megjelenítése után a naptár alkalmazás automatikusan elindul."
    echo "Ellenőrizd a naplófájlt: cat $INSTALL_DIR/calendar.log"
    echo "A szolgáltatás státusza: sudo systemctl status waveshare-calendar.service"
fi
