## Blackbox-Testing - Firmware-Release vX.Y.Z

Die folgenden Tests sollten auf möglichst vielen unterschiedlichen Routermodellen durchgeführt werden.

Ein grober Funktionstest sollten mindestens den folgenden Anforderungen genügen.

---

## Frankfurter Firmware-Release Vorabtest

### Firmware
- [ ] Dev
- [ ] Test
- [ ] Stable
- [ ] Benennung des Firmware-Releases

### Vorarbeiten
- [ ] Bekanntgabe der geplanten site.conf/site.mk auf Admin-Liste oder IRC
- [ ] Inhalt von site/modules ist auf gewünschtem Stand
- [ ] Bauen der Firmware mit allen zur Zeit unterstützten (None-BROKEN) Devices
- [ ] Bereitstellung eines Test-Routers mit aufgespielter vormaliger Firmwareversion
  - [ ] Erfolgreicher Aufruf von '```date```' auf neu gestartetem Test-Router (Backbone-NTP-Check, Latenzzeit nach Neustart beachten)
  - [ ] Erfolgreicher Testaufruf von '```autoupdater -n```' auf Test-Router (Backbone-DNS-Check)  
  
### Sysupgrade
- [ ] FW-Upgrade auf Test-Router, mit aufgespielter vormaliger Firmware, über unterschiedliche Verfahren anstossen
  - [ ] Über den Konfigmodus
  - [ ] Über die Konsole per '```autoupdater```'
  - [ ] zusätzlich über die Konsole manuell/lokal per '```sysupgrade```'
- [ ] Aufruf Konfigmodus mittels unterschiedlicher Web-Browser (z.B. Edge, Chromium, Firefox, Safari)
  - [ ] Texte, Inhalte und Eingabenübernahme im Konfigmodus korrekt
- [ ] Ist Autoupdate entsprechend gesetzt/vorhanden (Konfig-Tab)
- [ ] Ist Updatebranch korrekt gesetzt (Konfig-Tab)
- [ ] Ggf. korrekte Autoupdater Branch-Übernahme bei verwendetem Package "ffffm-use-site-conf-branch"
- [ ] Korrekte Revision-Information Firmware/Gluon (Konfig-Tab)
- [ ] Speicherung Konfiguration (inkl. Reboot)
- [ ] Aufruf Statusseite
  - [ ] 2a06:xyz innerhalb vom Freifunknetz
  - [ ] fddd:xyz innerhalb vom Freifunknetz
  - [ ] 2a06:xyz ausserhalb vom Freifunknetz
- [ ] Ist Sichtung des Knotens auf der Map gegeben
- [ ] Ist Sichtung von aktuellen Knoten-Daten in Grafana gegeben
- [ ] Korrekte Revision-Information Firmware/Gluon auf
  - [ ] Map
  - [ ] Statusseite
- [ ] SSH Login
  - [ ] innerhalb vom Freifunknetz
  - [ ] ausserhalb vom Freifunknetz
  - [ ] unautorisierte Anmeldung ohne Passwort nicht möglich 
- [ ] '```nodeinfo```' - korrekte Inhalts-Ausgabe
- [ ] '```help```' - korrekte Inhalts-Ausgabe
- [ ] WLAN-Kanalübernahme nach Sysupgrade
  - [ ] 2,4GHz
  - [ ] 5GHz
- [ ] Mesh-Verhalten generell
  - [ ] folgende Punkte getestet mit
    - [ ] einem Mesh-VPN-Knoten
    - [ ] einem Mesh-Only-Knoten
  - [ ] gegen Knoten mit gleicher Firmware
    - [ ] WLAN
      - [ ] Radio0
      - [ ] Radio1
    - [ ] LAN
    - [ ] WAN
  - [ ]  gegen Knoten mit vormaliger Firmware
    - [ ] WLAN
      - [ ] Radio0
      - [ ] Radio1
    - [ ] LAN
    - [ ] WAN
- [ ] Clientverbindung (IPv4, IPv6, DNS)
- [ ] OFF/ON Check
  - [ ] Mesh-VPN
  - [ ] WLAN-mesh
  - [ ] MoL
  - [ ] MoW
  - [ ] Client WLAN
  - [ ] Client LAN
  - [ ] WLAN
- [ ] WLAN-Taster - Funktions-Check
- [ ] Offline-SSID
  - [ ] Direkt nach Reboot
    - [ ] Mit Mesh / Mesh-VPN
    - [ ] Herstellung von Normalbedingungen (normale SSID kommt wieder)
  - [ ] Im laufenden Betrieb
    - [ ] Mit Mesh / Mesh-VPN
    - [ ] Herstellung von Normalbedingungen (normale SSID kommt wieder)
- [ ] opkg
  - [ ] '```opkg update```'
  - [ ] opkg-Installation eines Testpackages (z.B. htop)
- [ ] Autoupdate nur nach korrekter Anzahl der geforderten Manifest-Signaturen möglich
- [ ] Autoupdate gefolgt nach Autoupdate
- [ ] Autoupdate (Nachtzeit, selbsständig durch Router)
- [ ] Kurz-Sichtung von '```dmesg```' nach Reboot


### Firstboot
- [ ] '```firstboot```' absetzen
- [ ] Weiter mit dem Sysupgrade-Check (der dortige Testpunkt "FW-Upgrade auf Test-Router..." ist dann nicht mehr relevant).

### Factory
- [ ] Factory-Installation
- [ ] Weiter mit dem Sysupgrade-Check (der dortige Testpunkt "FW-Upgrade auf Test-Router..." ist dann nicht mehr relevant).

### Nacharbeiten
- [ ] Dokumentation der Release-Änderungshistorie
- [ ] Repo-Tagging 
  - [ ] Verwendeter Frankfurter Gluon-Branche
  - [ ] Verwendeter Frankfurter Site-Branche
- [ ] Release-Bekanntgabe
  - [ ] Auf Admin-Liste
  - [ ] Auf User-Liste

### Sonstiges
- [ ] Checkliste abgearbeitet auf mehreren unterschiedlichen Router-Modellen
- [ ] DL-Server
  - [ ] Upload der Firmware auf DL-Server
  - [ ] Backup der vormaligen Firmware-Version und -Modulen korrekt durchgeführt
- [ ] Listung im Frankfurter FirmwareSelector  

---

Das aktuelle Template dieser Checkliste ist hier zu finden:  
Direkt-Link: https://raw.githubusercontent.com/freifunk-ffm/Firmware-Release-Builder/master/FW-Releas_Checkliste.md  
