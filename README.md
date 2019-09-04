# Frankfurter Firmware Release Builder (FRB)

Mit dem Firmware Release Builder (FRB) können auf einfachste Art und Weise automatisiert Firmware-Releases gebaut werden.

Der FRB kann händisch auf einem PC oder automatisiert durch z.B. Jenkins aufgerufen werden.   

Der FRB ist ein einzelnes Skript, welches alle notwendigen Schritte des Buildprozesses vereint.   
  - Dem Skript werden Parameter übergeben.  
  - Das Skript holt selbständig die Inhalte aller notwendigen Gluon-Git-Repositories.
  - Das Skript kann lokale Site-Patches (aus site/patches) anwenden.
  - Das Skript legt einen eigenen Workspace an (./wspace).
  - Das Skript legt einen Paketesourcen-Download-Cache an (./dl-cache).
  - Der FRB ist hauptsächlich auf Frankfurter Ansprüche abgestimmt. Für den automatischen Upload auf den FFM Download-Server wird ein Tar-Archiv mit allen Images, allen opkg-Modulen und allen Versionsinformationen erzeugt (siehe https://github.com/freifunk-ffm/scripts/blob/master/firmwarefetch).  

### Achtung - Achtung - Achtung   
Der FRB setzt die Git-Repos hart auf den entsprechenden HEAD-Commit zurück. Lokale Anpassungen werden **immer** verworfen. Daher sollte der FRB nicht zur reinen FW-Entwickling verwendet werden!

### Skript-Benutzung
#### Voraussetzung 
  - Die zu verwendenen Gluon-Sources und die Community-spezifischen site-Sources müssen über einen Git-Server abrufbar sein. ~Durch den FRB werden für beide Repos Branches mit identischem Namen abgerufen.~

  - Für das Firmwarebauen müssen generell alle Pakete aus http://gluon.readthedocs.io/en/latest/user/getting_started.html#dependencies installier sein!  

#### Kleines Build-Beispiel:
```
firmware-release-builder.sh -B test -V vX.Y.Z
```
Durch diesen Aufruf wird aus den aktuellen Frankfurter Test-Branches (Gluon und Site) für alle verfügbaren Targets die Firmware `vX.Y.Z-test-Builddatum` erstellt. Es wird ein unsigniertes Manifest angelegt und das ganze als komprimiertes Archiv abgelegt. Das Skript zeigt den Pfad zu dem Ablageordner an. Je nach Rechner-Power braucht der Build ca. 5-8 Stunden.

#### Optionen des Skriptes
Skriptname:`firmware-release-builder.sh`  

Wird das Skript mit der Option `-h` aufgerufen, so wird folgendes ausgegeben:

```
Usage: firmware-release-builder.sh ... 

    Die Option -B (Git Haupt-Branch) "muss" angegeben werden!
    Optionen in Grossbuchstaben 'sollten' angegeben werden.
    Optionen in Kleinbuchstaben 'koennen' angegeben werden.

    -B <String>  Name des Gluon-Branches (z.B. dev, test oder stable).
    -T <String>  Welche Targets sollen gebaut werden?
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: alle als Nicht-BROKEN bekannte Targets)
    -C <String>  Name des Site-Branches (z.B. dev, test oder stable).
                 (Voreinstellung: Es wird der Parameter von -B übernommen)
    -U <String>  Name des Firmware Autoupdater-Branches (Firmware-spezifisch).
                 (Voreinstellung: Es wird der Parameter von -B übernommen)
    -V <String>  Vorgabe des Firmware Versionstrings.
                 (Voreinstellung: "Homebrew")
    -S <String>  Eigener Suffix fuer die Versionsbezeichnung.
                 (Voreinstellung: MonatTag)
    -L [0|1]     Lokale Site-Patches anwenden.
                 (Voreinstellung: 0)
    -b [0|1]     BROKEN Router-Images bauen? (Voreinstellung: 0)
    -t [0|1]     BROKEN Targets bauen? (Voreinstellung: 0)
                 Bei 1 werden dann BROKEN-Images fuer "alle" Targets gebaut!
    -P [int]     GLUON_PRIORITY (Voreinstellung: 0)
    -s <String>  Absoluter Pfad zum privaten ECDSA-Signkey.
    -p <String>  Build Make-Parameter. (Voreinstellung: "-j4")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -c [0|1]     Workspace vor dem Bauen löschen? (Voreinstellung: 1)
    -a [0|1]     Ein tar.xz Gesamtarchiv erzeugen? (Voreinstellung: 1)
    -x <String>  Gesamtarchiv xz-Parameter. (Voreinstellung: "-T0 -6")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -g <String>  Zu verwendendes Gluon-Repository.
                 (Voreinstellung https://github.com/freifunk-ffm/gluon.git)
    -k <String>  Zu verwendendes Site-Repository.
                 (Voreinstellung https://github.com/freifunk-ffm/site-ffffm.git)
    -v <String>  Zu verwendender Tag des Gluon-Repositories.
                 (Keine Voreinstellung)
    -w <String>  Zu verwendender Tag des Site-Repositories.
                 (Keine Voreinstellung) 
    -h           Dieser Text.
```

## Benötigte ECDSA-Utils
Der FirmwareReleaseBuilder verwendet u.a. die ECDSA-Utils.
Wie diese Tools unter Debian oder OS X installiert werden, ist hier nachzulesen: https://wiki.freifunk.net/ECDSA_Util
