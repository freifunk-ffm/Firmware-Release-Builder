# Frankfurter Firmware Release Builder (FRB)

Mit dem Firmware Release Builder (FRB) können sehr einfach Firmware Releases gebaut werden.  
Der FRB kann z.B. unter Jenkins oder händisch auf einem PC aufgerufen werden.  

Der FRB ist ein einzelnes Skript, welches alle notwendigen Schritt des Buildprozesses vereint.   
  - Dem Skript könne Parameter übergeben werden.  
  - Das Skript legt einen eigenen Workspace an. Es wird dafür u.a. der Firmware Versionsstring verwendet (siehe weiter unten).  
  - Der FRB ist hauptsächlich auf Frankfurter Ansprüche abgestimmt. Für den automatischen Upload auf den FFM Download-Server wird ein .gz Archiv mit allen Images, allen opkg-Modulen und allen Versionsinformationen erzeugt (siehe https://github.com/freifunk-ffm/scripts/blob/master/firmwarefetch).  

###Achtung!   
Je nach Konfiguration entfernt der FRB Dateien und Unterordner. Daher sollte der FRB nicht zur reinen FW-Entwickling verwendet werden!
  
###Verwendung
   
Skriptname:`firmware-release-builder.sh`  

Wird das Skript mit der Option `-h` aufgerufen, so wird folgendes ausgegeben:

```
Usage: firmware-releas-builder.sh ... 
    Die Option -B (Branch) "muss" angegeben werden!
    Optionen in Grossbuchstaben 'sollten' angegeben werden.
    Optionen in Kleinbuichstaben 'koennen' angegeben werden.
 
    -B          Name des FFM Firmware-Branches.
    -T          Welche Targets sollen gebaut werden? (Voreinstellung: alle nicht BROKEN)
    -V          Vorgabe des Firmware Versionsstrings. (Voreinstellung: "Homebrew")
    -b          BROKEN Router-Images bauen? (Voreinstellung: 0)
    -t          BROKEN Targets bauen. Es werden dann Images fuer "alle" Targets gebaut! (Voreinstellung: 0)
    -P          GLUON_PRIORITY (Voreinstellung: 0)
    -s          Absoluter Pfad zum privaten ECDSA-Signkey.
    -o          Absoluter Pfad zum oeffentlichen ECDSA-Signkey.
    -p          Build Parameter? (Voreinstellung: "-j4 V=s")
    -c          Workspace vor dem Bauen löschen? (Voreinstellung: 1)
    -a          Ein .gz Gesamtarchiv erzeugen? (Voreinstellung: 1)
    -h          Dieser Text.
```
