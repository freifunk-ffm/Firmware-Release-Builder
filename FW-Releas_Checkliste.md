## Firmware-Release Nutzbarkeits-Checkliste

Die folgenden Tests sollten auf möglichst vielen unterschiedlichen Routermodellen durchgeführt werden.

Ein grober Funktionstest sollten mindestens den folgenden Anforderungen genügen.

---

#### Factory
- [ ] Routerspezifische Factory-Installation
- [ ] Konfigmodus: Erstkonfiguration (alle Eingabefelder/-möglichkeiten)

Dann weiter mit Sysupgrade-Check.

---

#### Sysupgrade
- [ ] Allgemeines Erscheininhsbild der LEDs
- [ ] Erscheininhsbild der erwarteten Netzwerk-Konntektivität
- [ ] Aufruf Konfigmodus über Reset-/WPS-Taster
- [ ] Konfigmodus: Überprüfung der Beibehaltung der Benutzer-Konfiguration
- [ ] Konfigmodus: Revision-Information (FW/Gluon)
- [ ] Konfigmodus: Autoupdate Konfig
- [ ] Konfigmodus: Updatebranch 
- [ ] Konfigmodus: Texte allgemein
- [ ] Konfigmodus: Neustart
- [ ] Sichtung auf Map
- [ ] SSH Login
- [ ] Kanalübernahme
- [ ] Mesh-VPN
- [ ] Meshverhalten
- [ ] Mesh-VPN (jeweils ON/OFF)
- [ ] Wifi-mesh (jeweils ON/OFF)
- [ ] MoL (jeweils ON/OFF)
- [ ] MoW (jeweils ON/OFF)
- [ ] Client Wifi (jeweils ON/OFF)
- [ ] Client LAN (jeweils ON/OFF)
- [ ] Wifi-Taster
- [ ] Offline-SSID
- [ ] Nodeinfo
- [ ] opkg update
- [ ] opkg Testinstallation (inkl. kmods)
- [ ] Autoupdater (Nachtzeit, Router selbsständig)
- [ ] ggf. Autoupdater-Test"use site conf branch"
- [ ] Sysupgrade nach Sysupgrade (inkl. gefolgter Kurztest)
- [ ] Sysupgrade mit lokaler Image-Datei per 'sysupgrade'

---

#### Firstboot
- [ ] Durchführung mehrerer Factoryinstallationen, jeweils mit unterschiedlichen Erstkonfigurationen. Dann jeweils weiter mit Sysupgrade-Check

---

#### Sonstiges
- [ ] Check Listungen Firmwarewizard
