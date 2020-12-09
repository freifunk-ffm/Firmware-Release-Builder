# Frankfurter Firmware Release Builder (FRB)

Mit dem Firmware Release Builder (FRB) können auf einfachste Art und Weise automatisiert Firmware-Releases gebaut werden.

Der FRB kann händisch auf einem PC oder automatisiert durch z.B. Jenkins aufgerufen werden.   

Der FRB ist ein einzelnes Skript, welches alle notwendigen Schritte des Buildprozesses vereint.   
  - Dem Skript werden Parameter übergeben.
  - Das Skript holt selbständig die Inhalte aller notwendigen Gluon-Git-Repositories.
  - Das Skript kann lokale Site-Patches (aus site/patches) anwenden.
  - **Das Skript legt einen eigenen Workspace an (./wspace).**
  - **Das Skript legt einen Paketesourcen-Download-Cache an (./dl-cache).**
  - Das Skript erzeugt eine Sysupgrade-Manifest-Datei und signiert diese ggf. mit einem vorliegenden Public-ECDSA-Key.
  - Das Skript erstellt zwei Dateien mit SHA256- und SHA512-Image-Hashes (auch Factory) und signiert diese ggf. mit einem vorliegenden Public-ECDSA-Key.
  - Für einen automatisierten Upload auf einen Download-Server wird ein komprimiertes Tar-Archiv mit allen Images, allen opkg-Modulen und allen Versionsinformationen erstellt (**siehe dazu das Frankfurter Fetch-Skript:** https://github.com/freifunk-ffm/scripts/blob/master/firmwarefetch ).
  - Der FRB ist defaultmäßig auf Frankfurter Ansprüche abgestimmt. 
  - Durch anpassung der Aufrufparameter ist der FirmwareReleaseBuilder jedoch Community-übergreifend einsetzbar.

### Achtung - Achtung - Achtung   
Der FRB setzt die lokal verwendeten Git-Repos hart auf die Origin-HEAD-Commits zurück. Lokale Anpassungen werden **immer** verworfen! Daher sollte der FRB nicht zur reinen FW-Entwickling verwendet werden!

### Skript-Benutzung
#### Voraussetzung 
  - Die zu verwendenen Community-spezifischen site-Sources und die Gluon-Sources müssen über einen Git-Server abrufbar sein.

  - Für das Firmwarebauen müssen generell alle Pakete aus http://gluon.readthedocs.io/en/latest/user/getting_started.html#dependencies installier sein!
  
  - Für die Make-Aufrufe deklariert und definiert der FirmwareReleaseBuilder die Umgebungsvariablen `GLUON_BRANCH`, `GLUON_RELEASE`, `GLUON_PRIORITY`, `GLUON_TARGET` und `BROKEN`. Dieses ist in Bezug auf die Verwendung der Umgabungsvariablen innerhalb der `site.mk` zu berücksichtigen.

#### Kleines Build-Beispiel:
```
firmware-release-builder.sh -C test -V v1.2.3
```
Durch diesen Aufruf wird aus den aktuellen Frankfurter Test-Branches (Site und Gluon) für alle verfügbaren Targets die Firmware `v1.2.3-test-Builddatum` erstellt. Vorab wird ein bereits vorhandener Build-Workspace gelöscht. Es wird ein unsigniertes Sysupgrade-Manifest angelegt und alle erstellten Images und opkg-Module als komprimiertes Archiv abgelegt. Das Skript zeigt den Pfad zu dem Ablageordner an. Je nach Rechner-Power braucht der Build ca. 5-8 Stunden.

Der Aufruf des Build-Beispiels für nur ein Target (hier ar71xx-generic) sähe so aus:
```
firmware-release-builder.sh -C test -V v1.2.3 -T ar71xx-generic
```
Je nach Rechner-Power braucht ein clean Build dann nur ca. 30 Minuten.

#### Optionen des Skriptes
Skriptname:`firmware-release-builder.sh`  

Wird das Skript mit der Option `-h` aufgerufen, so wird folgendes ausgegeben:

```
Usage: firmware-release-builder.sh ...

    Die Option -C (Git Site-Branch) "muss" angegeben werden!
    Optionen in Grossbuchstaben 'sollten' angegeben werden.
    Optionen in Kleinbuchstaben 'koennen' angegeben werden.

    -C <String>  Name des Firmware Autoupdater-Branches (Firmware-spezifisch).
                 (Geht als Mittelstring in die FW-Release-Bezeichnung ein)
    -U <String>  Name des Git Site-Branches (z.B. dev, test oder stable).
                 (Voreinstellung: Es wird der Parameter von -C übernommen)
    -B <String>  Name des Git Gluon-Branches (z.B. dev, test oder stable).
                 (Voreinstellung: Es wird der Parameter von -C übernommen)
    -T <String>  Welche Targets sollen gebaut werden?
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: alle als Nicht-BROKEN bekannte Targets)
    -V <String>  Vorgabe des Firmware Versionstrings.
                 (Voreinstellung: "vHomebrew")
    -E <Streing> Eigener erster Suffix für die Versionsbezeichnung.
                 (Voreinstellung: Es wird der Parameter von -C übernommen)
    -S <String>  Eigener zweiter Suffix für die Versionsbezeichnung.
                 (Voreinstellung: MonatTag)
    -L [0|1]     Lokale Site-Patches anwenden.
                 (Voreinstellung: 0)
    -b [0|1]     BROKEN Router-Images bauen?
                 (Voreinstellung: 0)
    -t [0|1]     BROKEN Targets bauen?
                 (Voreinstellung: 0)
                 Bei 1 werden dann BROKEN-Images für "alle" Targets gebaut!
    -P [int]     GLUON_PRIORITY
                 (Voreinstellung: 0)
    -s <String>  Absoluter Pfad und Name des privaten ECDSA-Signkeys. 
                 Falls angegeben, so wird das Manifest damit signiert.
    -p <String>  Build Make-Parameter.
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: "-j4")
    -c [0|1]     Workspace vor dem Bauen löschen?
                 (Voreinstellung: 1)
    -a [0|1]     Ein tar.xz Gesamtarchiv erzeugen?
                 (Voreinstellung: 1)
    -x <String>  Gesamtarchiv xz-Parameter.
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: "-T0 -6")
    -k <String>  Zu verwendendes Site-Repository.
                 (Voreinstellung https://github.com/freifunk-ffm/site-ffffm.git)
    -g <String>  Zu verwendendes Gluon-Repository.
                 (Voreinstellung https://github.com/freifunk-ffm/gluon.git)
    -w <String>  Zu verwendender Tag des Site-Repositories.
                 Hat Priorität vor dem Parameter -U.
                 (Keine Voreinstellung)
    -v <String>  Zu verwendender Tag des Gluon-Repositories.
                 Hat Priorität vor dem Paramater -B.
                 (Keine Voreinstellung)
    -h           Dieser Text.
```

## Benötigte ECDSA-Utils
Der FirmwareReleaseBuilder verwendet u.a. die ECDSA-Utils.
Wie diese Tools unter Debian oder OS X installiert werden, ist hier nachzulesen: https://wiki.freifunk.net/ECDSA_Util
