# Frankfurter Firmware Release Builder (FRB)

Mit dem Firmware Release Builder (FRB) können sehr einfach Firmware Releases gebaut werden.  
Der FRB kann z.B. unter Jenkins oder händisch auf einem PC aufgerufen werden.  

Der FRB ist ein einzelnes Skript, welches alle notwendigen Schritt des Buildprozesses vereint.   
  - Dem Skript könne Parameter übergeben werden.  
  - Das Skript legt einen eigenen Workspace an. Es wird dafür u.a. der Firmware Versionsstring verwendet (siehe weiter unten).  
  - Der FRB ist hauptsächlich auf Frankfurter Ansprüche abgestimmt. Für den automatischen Upload auf den FFM Download-Server wird ein .gz Archiv mit allen Images, allen opkg-Modulen und allen Versionsinformationen erzeugt (siehe https://github.com/freifunk-ffm/scripts/blob/master/firmwarefetch).  

###Achtung!   
Je nach Konfiguration entfernt der FRB Dateien und Unterordner. Daher sollte der FRB nicht zur reinen FW-Entwickling verwendet werden!

###Skript-Benutzung
####Voraussetzung 
Für das Firmwarebauen müssen generell alle Pakete aus http://gluon.readthedocs.io/en/latest/user/getting_started.html#dependencies installier sein!
####Das Skript anwenden
Skriptname:`firmware-release-builder.sh`  

Wird das Skript mit der Option `-h` aufgerufen, so wird folgendes ausgegeben:

```
Usage: firmware-release-builder.sh ... 
    Die Option -B (Branch) "muss" angegeben werden!
    Optionen in Grossbuchstaben 'sollten' angegeben werden.
    Optionen in Kleinbuichstaben 'koennen' angegeben werden.

    -B <String>  Name des FFM Firmware-Branches (dev, test oder stable).
    -T <String>  Welche Targets sollen gebaut werden?
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: alle als Nicht-BROKEN bekannte Targets)
    -V <String>  Vorgabe des Firmware Versionsstrings.
                 (Voreinstellung: "Homebrew")
    -b [0|1]     BROKEN Router-Images bauen? (Voreinstellung: 0)
    -t [0|1]     BROKEN Targets bauen. (Voreinstellung: 0)
                 Bei 1 werden dann BROKEN-Images fuer "alle" Targets gebaut!
    -P [0|1]     GLUON_PRIORITY (Voreinstellung: 0)
    -s <String>  Absoluter Pfad zum privaten ECDSA-Signkey.
    -p <String>  Build Parameter? (Voreinstellung: "-j4 V=s")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -c [0|1]     Workspace vor dem Bauen löschen? (Voreinstellung: 1)
    -a [0|1]     Ein .gz Gesamtarchiv erzeugen? (Voreinstellung: 1)
    -h           Dieser Text.
```

## Benötigte ECDSA-Utils
Der FirmwareReleaseBuilder verwendet u.a. die ECDSA-Utils.
Wie diese Tools unter Debian oder OS X installiert werden, ist hier nachzulesen: https://wiki.freifunk.net/ECDSA_Util
