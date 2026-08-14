# RTL8189FS-DKMS fuer Armbian/OPhub

Dieses Repository baut den internen Realtek-RTL8189FTV/RTL8189FS-SDIO-WLAN-Treiber automatisch mit DKMS. Anders als das [kernelgebundene Vorgängerprojekt](https://github.com/dd2git/armbian-rtl8189fs) enthält es kein vorkompiliertes Kernelmodul. DKMS baut den Treiber für den laufenden Kernel und nach Kernel-Updates erneut.

## Getestetes System

- Gerät: X96 Mini / Tanix TX3 Mini mit Amlogic S905W
- Betriebssystem: Armbian OS auf Debian 12 Bookworm
- Kernel: `6.18.43-ophub`
- Architektur: ARM64 (`aarch64`)
- SDIO-ID: `024c:f179`
- Modul: `8189fs`
- Treiberversion: `v5.7.9_35795.20191128`
- Compiler: ARM GNU Toolchain 15.3

Der Installer lädt die zum getesteten OPhub-Kernel passende ARM-GNU-Toolchain, falls sie noch nicht unter `/usr/local/toolchain` vorhanden ist.

## Installation

Die zum laufenden Kernel passenden Header müssen unter `/lib/modules/$(uname -r)/build` vorhanden sein.

```bash
git clone https://github.com/dd2git/armbian-rtl8189fs-dkms.git
cd armbian-rtl8189fs-dkms
sudo ./install.sh
sudo reboot
```

Nach dem Neustart prüfen:

```bash
dkms status
modinfo -n 8189fs
iw dev
```

`modinfo -n 8189fs` sollte einen Pfad unter `updates/dkms` ausgeben.

## WLAN-Netze suchen

```bash
./scan-wifi.sh
```

Oder direkt mit NetworkManager:

```bash
nmcli device wifi list
sudo nmcli device wifi connect "NAME-DES-WLANS" password "WLAN-PASSWORT"
```

## Kernel-Updates

`AUTOINSTALL=yes` in `dkms.conf` sorgt dafür, dass DKMS den Treiber für neu installierte Kernel baut. Das funktioniert, wenn:

1. die passenden Kernel-Header installiert sind,
2. die ARM-GNU-Toolchain weiterhin unter `/usr/local/toolchain` liegt,
3. eine neue Kernel-API keine weitere Quellcodeanpassung benötigt.

Status und Build-Logs:

```bash
dkms status
journalctl -u dkms --no-pager
find /var/lib/dkms/rtl8189fs -name make.log -print
```

## Deinstallation

```bash
sudo ./uninstall.sh
sudo reboot
```

## Technischer Hintergrund

Der Treiber basiert auf dem Branch [`rtl8189fs`](https://github.com/EvilOlaf/rtl8189ES_linux/tree/rtl8189fs), Commit `f95ad2e28bfb1a4350ff5da123a28df4183ca120`. Der OPhub-Kernel 6.18 enthält zurückportierte `cfg80211`-APIs aus neueren Kernelreihen. Deshalb wurden in `driver/os_dep/linux/ioctl_cfg80211.c` die betreffenden Versionsschwellen von Kernel 7.1/7.2 auf 6.18 gesetzt.

Die DKMS-Buildzeile unterdrückt die automatische Übergabe von `KERNELRELEASE` an das alte Realtek-Makefile und verwendet den Compiler, mit dem der getestete Kernel gebaut wurde.

## Sicherheit und Lizenz

Das Repository enthält keine SSH-, Root- oder WLAN-Zugangsdaten. Passwörter gehören weder in Commits noch in Issues.

Der Treiber und die Skripte stehen unter GPL-2.0-only. Siehe [LICENSE](LICENSE).
