#!/bin/bash
echo
echo FirmwareReleaseBuilder
echo

##############################################################################
# Dieses Skript ist fuer den Bau von Frankfurter FW-Releases vorgesehen.
# Das Skript ist nicht für die Firmware-Entwicklung geeignet!
# Lokale temporäre Änderungen werden überschrieben!
##############################################################################


# Default Werte
FRB_TARGETS=${FRB_TARGETS:-"ar71xx-generic ar71xx-tiny ar71xx-nand ipq40xx brcm2708-bcm2708 brcm2708-bcm2709 mpc85xx-generic ramips-mt7620 ramips-mt7621 ramips-mt76x8 ramips-rt305x sunxi-cortexa7 x86-generic x86-geode x86-64"}
FRB_GLUON_REPO=${FRB_GLUON_REPO:-"https://github.com/freifunk-ffm/gluon.git"}
FRB_GLUON_BRANCH=${FRB_GLUON_BRANCH:-"none"}
FRB_SITE_REPO=${FRB_SITE_REPO:-"https://github.com/freifunk-ffm/site-ffffm.git"}
FRB_SITE_BRANCH=${FRB_SITE_BRANCH:-"none"}
FRB_FW_UPDATE_BRANCH=${FRB_FW_UPDATE_BRANCH:-none}
FRB_VERSION=${FRB_VERSION:-Homebrew}
FRB_SITE_PATCHES=${FRB_SITE_PATCHES:-0}
FRB_CLEANUP=${FRB_CLEANUP:-1}
FRB_BROKEN=${FRB_BROKEN:-0}
FRB_BROKEN_TARGETS=${FRB_BROKEN_TARGETS:-0}
FRB_PRIORITY=${FRB_PRIORITY:-0}
FRB_CREATE_DARCHIVE=${FRB_CREATE_DARCHIVE:-1}
FRB_XZPARAMETER=${FRB_XZPARAMETER:-"-T0 -6"}
FRB_SIGNKEY_PRIVATE=${FRB_SIGNKEY_PRIVATE:-"none"}
FRB_BPARAMETER=${FRB_BPARAMETER:-"-j4"}
FRB_VERSION_SUFFIX=${FRB_VERSION_SUFFIX:-"none"}

###################################################################
# Usage Info
###################################################################
show_help() {
cat << EOF

Usage: ${0##*/} ...

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
                 (Voreinstellung: "$FRB_VERSION")
    -S <String>  Eigener Suffix fuer die Versionsbezeichnung.
                 (Voreinstellung: MonatTag)
    -L [0|1]     Lokale Site-Patches anwenden.
                 (Voreinstellung: $FRB_SITE_PATCHES)
    -b [0|1]     BROKEN Router-Images bauen? (Voreinstellung: $FRB_BROKEN)
    -t [0|1]     BROKEN Targets bauen? (Voreinstellung: $FRB_BROKEN_TARGETS)
                 Bei 1 werden dann BROKEN-Images fuer "alle" Targets gebaut!
    -P [int]     GLUON_PRIORITY (Voreinstellung: $FRB_PRIORITY)
    -s <String>  Absoluter Pfad zum privaten ECDSA-Signkey.
    -p <String>  Build Make-Parameter. (Voreinstellung: "$FRB_BPARAMETER")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -c [0|1]     Workspace vor dem Bauen löschen? (Voreinstellung: $FRB_CLEANUP)
    -a [0|1]     Ein tar.xz Gesamtarchiv erzeugen? (Voreinstellung: $FRB_CREATE_DARCHIVE)
    -x <String>  Gesamtarchiv xz-Parameter. (Voreinstellung: "$FRB_XZPARAMETER")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -g <String>  Zu verwendendes Gluon-Repository.
                 (Voreinstellung $FRB_GLUON_REPO)
    -k <String>  Zu verwendendes Site-Repository.
                 (Voreinstellung $FRB_SITE_REPO)
    -h           Dieser Text.

EOF
}

###################################################################
# Optionen parsen
###################################################################

while getopts "T:B:C:U:V:P:S:L:s:p:c:b:t:a:x:g:k:h" opt; do
  case $opt in
    T) FRB_TARGETS=$OPTARG
       ;;
    B) FRB_GLUON_BRANCH=$OPTARG
       ;;
    C) FRB_SITE_BRANCH=$OPTARG
       ;;
    U) FRB_FW_UPDATE_BRANCH=$OPTARG
       ;;
    V) FRB_VERSION=$OPTARG
       ;;
    P) FRB_PRIORITY=$OPTARG
       ;;
    S) FRB_VERSION_SUFFIX=$OPTARG
       ;;
    L) FRB_SITE_PATCHES=$OPTARG
       ;;
    s) FRB_SIGNKEY_PRIVATE=$OPTARG
       ;;
    p) FRB_BPARAMETER=$OPTARG
       ;;
    c) FRB_CLEANUP=$OPTARG
       ;;
    b) FRB_BROKEN=$OPTARG
       ;;
    t) FRB_BROKEN_TARGETS=$OPTARG
       ;;
    a) FRB_CREATE_DARCHIVE=$OPTARG
       ;;
    x) FRB_XZPARAMETER=$OPTARG
       ;;
    g) FRB_GLUON_REPO=$OPTARG
       ;;
    k) FRB_SITE_REPO=$OPTARG
       ;;
    h) show_help
       exit 0
       ;;
    :)
       exit 1
       ;;
    ?)
       exit 1
       ;;
  esac
done


#####################################################################
# Jenkins kann komfortabel nur boolesche Variablen als false/true 
# uebergeben.
# Die folgendenden Zeilen transformieren durch Jenkins uebergebene 
# Aufrufparameter in 0/1 zurueck.
#####################################################################
normalize_bool() {
  if [[ "$1" = "true" ]]
  then
    echo 1
  elif [[ "$1" = "false" ]]
  then
    echo 0
  else
    echo "$1"
  fi
}
FRB_CLEANUP=$(normalize_bool $FRB_CLEANUP)
FRB_BROKEN=$(normalize_bool $FRB_BROKEN)
FRB_BROKEN_TARGETS=$(normalize_bool $FRB_BROKEN_TARGETS)
FRB_CREATE_DARCHIVE=$(normalize_bool $FRB_CREATE_DARCHIVE)
FRB_SITE_PATCHES=$(normalize_bool $FRB_SITE_PATCHES)

#####################################################################
# Echo formated information
#####################################################################
to_output() {
echo
echo ----------------------------------------------------------------
echo "FirmwareBuilder: $1"
echo ----------------------------------------------------------------
}

# Ausgabe der verwendeten Parameter
show_build_information() {
cat << EOF

Die FW wird/wurde mit folgenden Optionen gebaut:

Targets:              $FRB_TARGETS
Gluon-Repo:           $FRB_GLUON_REPO
Site-Repo:            $FRB_SITE_REPO
Gluon-Branch:         $FRB_GLUON_BRANCH
Site-Branch:          $FRB_SITE_BRANCH
FW Update-Branch:     $FRB_FW_UPDATE_BRANCH
Versionstring:        $FRB_VERSION
Versionsuffix:        $FRB_VERSION_SUFFIX
Site-Patches aktiv:   $FRB_SITE_PATCHES
Workspace löschen:    $FRB_CLEANUP
BROKEN Images:        $FRB_BROKEN
BROKEN Targets:       $FRB_BROKEN_TARGETS
GLUON_PRIORITY:       $FRB_PRIORITY
Erzeuge Gesamtarchiv: $FRB_CREATE_DARCHIVE
xz-Parameter:         $FRB_XZPARAMETER
Pfad Signkey privat:  $FRB_SIGNKEY_PRIVATE
Buildparameter:       $FRB_BPARAMETER
Workspace:            $WORKSPACE

EOF
}

check_last_exitcode()
{
 if [ $? -ne 0 ]; then
  exit 1
 fi
}

###################################################################
###################################################################
# Ab hier geht es los
###################################################################
###################################################################

# Uebernahme der Parameter für den Git-Gluon-Build
# Wenn kein Git-Gluon-Branch definiert wurde -> Abbruch
if [ "$FRB_GLUON_BRANCH" == "none" ];  then
 show_help
 to_output "Abbruch: Es wurde kein Git-Gluon-Branch mittels '-B' angegeben"
 exit 1
fi

# Wenn kein Site-Branch definiert wurde, dann den Git-Gluon-Branch verwenden
if [ "$FRB_SITE_BRANCH" == "none" ];  then
 FRB_SITE_BRANCH=${FRB_GLUON_BRANCH}
fi

# Wenn kein Firmware-Update-Branch definiert wurde, dann den Git-Gluon-Branch verwenden
if [ "$FRB_FW_UPDATE_BRANCH" == "none" ];  then
 FRB_FW_UPDATE_BRANCH=${FRB_GLUON_BRANCH}
fi

export GLUON_BRANCH=${FRB_FW_UPDATE_BRANCH}
if [ "$FRB_VERSION_SUFFIX" == "none" ];  then
 export BUILD_NUMBER=$(date '+%m%d')
else 
 export BUILD_NUMBER=${FRB_VERSION_SUFFIX}
fi

export GLUON_RELEASE=${FRB_VERSION}-${GLUON_BRANCH}-${BUILD_NUMBER}
export GLUON_PRIORITY=${FRB_PRIORITY}

# Der Build-Prozess schaut nur ob die Umgebungsvariable BROKEN existiert. 
# Der Inhalt/Wert von BROKEN ist komplett egal.
# Daher die Umgebungsvariable ggf. komplett entfernen.
if [ $FRB_BROKEN -eq 0 ]; then
  unset BROKEN
else
 export BROKEN=${FRB_BROKEN}
fi

CLEANUP=${FRB_CLEANUP}

WORKSPACE="$(pwd)/wspace"

show_build_information

# Ggf. erstmal Aufraeumen, und den Workspace komplett löschen
# Zur Zeiteersparnis geschieht das Loeschen als Hintergrundprozess
if [ $CLEANUP != 0 ];  then
 to_output "Entferne alten Workspace (Hintergrundprozess)"
 if [ -d "$WORKSPACE" ]; then
  mv $WORKSPACE "$WORKSPACE"__removal_still_in_progress_PID-$$
  rm -rf "$WORKSPACE"__removal_still_in_progress_PID-$$ &
  disown
 fi
fi

# ggf. Workspace erzeugen und Gluon aus Git holen
if [ ! -d "$WORKSPACE" ]; then
 to_output "Clone Gluon in neuen Workspace"
 git clone $FRB_GLUON_REPO $WORKSPACE
 check_last_exitcode
 to_output  "Clone Site in neuen Workspace"
 git clone $FRB_SITE_REPO $WORKSPACE/site
 check_last_exitcode
fi

# Gluon und site.conf aus den Git-Branches holen
cd $WORKSPACE
to_output  "Checkout Git-Branch vom Gluon- und Site-Repository"
git fetch && git reset --hard origin/${FRB_GLUON_BRANCH}
check_last_exitcode
cd $WORKSPACE/site
git fetch && git reset --hard origin/${FRB_SITE_BRANCH}
check_last_exitcode

cd $WORKSPACE
to_output "Anwenden von lokalen Site-Patches"
if [ $FRB_SITE_PATCHES == 1 ]; then
 if [ -d "$WORKSPACE/site/patches" ]; then
  cd ${WORKSPACE}/site/patches
  if [ $(echo *.patch)  != "*.patch" ]; then
   cd $WORKSPACE
   git -c user.name='Frankfurter FirmwareReleaseBuilder' -c user.email='ffffm-FRB@void.example.com' -c commit.gpgsign=false am --whitespace=nowarn --committer-date-is-author-date $WORKSPACE/site/patches/*.patch
   check_last_exitcode
  else
   echo "Keine lokalen Site-Patches gefunden"
  fi
 else
  echo "Keinen Site-Ordner für lokale Patches gefunden"
 fi
else
 echo "Lokale Site-Patches werden nicht angewendet"
fi 

cd $WORKSPACE
to_output "Update OpenWrt"
make update
check_last_exitcode

# Alte Images vorher immer komplett entfernen
to_output "Loesche alten Image Ordner"
if [ -d "$WORKSPACE/output" ]; then
 rm -rf "${WORKSPACE}/output"
fi
# Einen OpenWrt-Download-Cache-Ordner anlegen
to_output "Erstelle Symlink auf Ordner dl-cache"

cd ${WORKSPACE}/openwrt
mkdir -p ../../dl-cache
if [ -d "dl" ]; then
	rm -rf dl
fi
ln -s ../../dl-cache ${WORKSPACE}/openwrt/dl
cd ${WORKSPACE}

# Schauen, ob FRB_BROKEN_TARGETS aktiv ist. Wenn ja, dann immer die volle Anzahl an Möglichkeiten (Images + Targets) bauen.
# FRB_TARGETS verwenden oder komplett ueberschreiben.
if [ $FRB_BROKEN_TARGETS == 1 ]; then
 # All möglichen Targets bauene. Auch die als BROKEN markierten.
 FRB_TARGETS=$(grep GluonTarget targets/targets.mk | awk -F, '{print $2 "-" $3}'|sed 's/).*//')
  # Zur Sicherheit nochmal BROKEN setzen
 export BROKEN=1
fi
to_output "Build Targets = $FRB_TARGETS"
to_output "BROKEN = $FRB_BROKEN"

############
# Bauen
############
for GLUON_TARGET in $FRB_TARGETS
do
 export GLUON_TARGET
 to_output "Baue Target ${GLUON_TARGET}"
 make ${FRB_BPARAMETER} || (make -j1 V=s ; to_output "Abbruch durch Build-Fehler im Target ${GLUON_TARGET}"; false ;)
 check_last_exitcode
done


# Manifest erstellen
to_output "Erzeuge das Manifest"
make manifest
if [ "$FRB_SIGNKEY_PRIVATE" != "none" ];  then
 contrib/sign.sh ${FRB_SIGNKEY_PRIVATE} ${WORKSPACE}/output/images/sysupgrade/${GLUON_BRANCH}.manifest
fi

# MD5 und SHA256 Hashes von allen Images erzeugen
# MD5 wird letztlich doch noch benötigt. Der MD5-HASH wird im Konfig-Modus beim Umflashen angezeigt.
cd ${WORKSPACE}/output/images

to_output  "Erzeuge Hashes der Images"
# Hier sollte irgendwann mal eine Schleife abgearbeitet werden :o)
hashfile_MD5=../MD5SUMS-${GLUON_RELEASE}
hashfile_SHA256=../SHA256SUMS-${GLUON_RELEASE}
find -L * -exec md5sum {} \; > ${hashfile_MD5}
find -L * -exec sha256sum {} \; > ${hashfile_SHA256}
# Footer an die Hash-Dateien anhängen
echo --- >> ${hashfile_MD5}
echo --- >> ${hashfile_SHA256}

# Die Hashes ggf. noch mit einem ECDSA-Key signieren (zur absoluten Sicherheit).
if [ "$FRB_SIGNKEY_PRIVATE" != "none" ];  then
 to_output "Signiere die Hashedatei"
 # ECDSA signieren der Hash-Dateien
 ecdsasign ${hashfile_MD5} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_MD5}
 ecdsasign ${hashfile_SHA256} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_SHA256}
 mv ${hashfile_MD5} .
 mv ${hashfile_SHA256} .
 # Damit es auch kontrolliert werden kann -> Bereitstellen des öffentlichen ECDSA-Schluessels
 to_output "Public ECDSA-Schluessel bereitstellen"
 ecdsakeygen -p < ${FRB_SIGNKEY_PRIVATE} > ecdsa-key-${GLUON_RELEASE}.pub
fi
# Die Hash-Dateien an Zielposition verschieben
mv ${hashfile_MD5} .
mv ${hashfile_SHA256} .
cd ${WORKSPACE}

if [ $FRB_CREATE_DARCHIVE != 0 ];  then
  to_output "Vorbereitung der Deploy-Informationen"
  # Verschieben der opkg-Module an Frankfurter Zielort -> 'output/images/sysupgrade/modules'

  # Gluon basierte mal auf OpenWrt, dann auf LEDE und nun wieder auf OpenWrt.
  # Die unterschiedlichen Build-Umgebungen hatten u.a. unterschiedliche Zielpfade für Modul- bzw. Package-Binaries.
  # Dieses Hin und Her der Pfadstrukturen wurden nicht bis zum Frankfurter DL-Server durchgereicht.
  # Daher müssen nachträglich einige Pfade der aktuellen Gluon-Buildumgebung an die Pfad-Struktur des DL-Server angepasst werden.
  
  if [ -d "${WORKSPACE}/output/packages" ]; then  # wird alleinig nur ar71xx-tiny gebaut, so gibt es dann diesen Ordner nicht.
    mv ${WORKSPACE}/output/packages ${WORKSPACE}/output/images/sysupgrade/modules
  fi

  # Firmware-Information erzeugen
  echo ${GLUON_RELEASE} > version
  mv version ${WORKSPACE}/output/images

  # Deploy-Archiv erzeugen
  to_output "Erzeuge Deploy-Archiv"
  cd ${WORKSPACE}/output/images
  tar cvf gluon-ffffm-${GLUON_RELEASE}.tar.xz  -I "xz ${FRB_XZPARAMETER}" *
  to_output  "Das Deploy-Archive liegt hier: ${WORKSPACE}/output/images/gluon-ffffm-${GLUON_RELEASE}.tar.xz"
fi

#Fertig!
to_output  "Fertig!"

show_build_information


