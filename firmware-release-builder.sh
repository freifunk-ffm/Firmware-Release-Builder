#!/bin/bash
echo
echo FirmwareReleaseBuilder
echo

##############################################################################
# Dieses Skript ist fuer den Bau von Frankfurter FW-Releases vorgesehen.
# Das Skript ist nicht für die FW-Entwicklung geeignet! Es wird viel gelöscht!
##############################################################################


# Default Werte
FRB_TARGETS=${FRB_TARGETS:-"ar71xx-tiny ar71xx-generic x86-generic x86-64 x86-geode mpc85xx-generic brcm2708-bcm2708 brcm2708-bcm2709 ar71xx-nand ramips-mt7621"}
FRB_BRANCH=${FRB_BRANCH:-none}
FRB_VERSION=${FRB_VERSION:-Homebrew}
FRB_CLEANUP=${FRB_CLEANUP:-1}
FRB_BROKEN=${FRB_BROKEN:-0}
FRB_BROKEN_TARGETS=${FRB_BROKEN_TARGETS:-0}
FRB_PRIORITY=${FRB_PRIORITY:-0}
FRB_CREATE_DARCHIVE=${FRB_CREATE_DARCHIVE:-1}
FRB_XZPARAMETER=${FRB_XZPARAMETER:-"-T0 -9"}
FRB_SIGNKEY_PRIVATE=${FRB_SIGNKEY_PRIVATE:-"none"}
FRB_BPARAMETER=${FRB_BPARAMETER:-"-j4 V=s --output-sync=recurse"}
FRB_VERSION_SUFFIX=${FRB_VERSION_SUFFIX:-"none"}

###################################################################
# Usage Info
###################################################################
show_help() {
cat << EOF

Usage: ${0##*/} ...

    Die Option -B (Branch) "muss" angegeben werden!
    Optionen in Grossbuchstaben 'sollten' angegeben werden.
    Optionen in Kleinbuchstaben 'koennen' angegeben werden.

    -B <String>  Name des FFM Firmware-Branches (dev, test oder stable).
    -T <String>  Welche Targets sollen gebaut werden?
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: alle als Nicht-BROKEN bekannte Targets)
    -V <String>  Vorgabe des Firmware Versionstrings.
                 (Voreinstellung: "Homebrew")
    -S <String>  Eigener Suffix fuer die Versionsbezeichnung. 
                 Anstelle von Monat/Tag.
    -b [0|1]     BROKEN Router-Images bauen? (Voreinstellung: 0)
    -t [0|1]     BROKEN Targets bauen? (Voreinstellung: 0)
                 Bei 1 werden dann BROKEN-Images fuer "alle" Targets gebaut!
    -P [0.0-1.0] GLUON_PRIORITY (Voreinstellung: 0.0)
    -s <String>  Absoluter Pfad zum privaten ECDSA-Signkey.
    -p <String>  Build Make-Parameter. (Voreinstellung: "-j4 V=s --output-sync=recurse")
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
    -c [0|1]     Workspace vor dem Bauen löschen? (Voreinstellung: 1)
    -a [0|1]     Ein tar.xz Gesamtarchiv erzeugen? (Voreinstellung: 1)
    -x <String>  Gesamtarchiv xz-Parameter. (Voreinstellung: "-T0 -9")
    -h           Dieser Text.

EOF
}

###################################################################
# Optionen parsen
###################################################################
while getopts "T:B:V:P:S:s:p:c:b:t:a:h" opt; do
  case $opt in
    T) FRB_TARGETS=$OPTARG
       ;;
    B) FRB_BRANCH=$OPTARG
       ;;
    V) FRB_VERSION=$OPTARG
       ;;
    P) FRB_PRIORITY=$OPTARG
       ;;
    S) FRB_VERSION_SUFFIX=$OPTARG
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
Branch:               $FRB_BRANCH
Versionstring:        $FRB_VERSION
Versionsuffix:        $FRB_VERSION_SUFFIX
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

# Uebernahme der Parameter für den Gluon-Build
export GLUON_BRANCH=${FRB_BRANCH}
if [ "$FRB_VERSION_SUFFIX" == "none" ];  then
 export BUILD_NUMBER=$(date '+%m%d')
else 
 export BUILD_NUMBER=${FRB_VERSION_SUFFIX}
fi
export GLUON_RELEASE=${FRB_VERSION}-${GLUON_BRANCH}-${BUILD_NUMBER}
export GLUON_PRIORITY=${FRB_PRIORITY}
export BROKEN=${FRB_BROKEN}
CLEANUP=${FRB_CLEANUP}

WORKSPACE="$(pwd)/wspace"

# Wenn kein Branch definiert wurde -> Abbruch
if [ "$GLUON_BRANCH" == "none" ];  then
 show_help
 to_output "Abbruch: Es wurde kein Branch mittels '-B' angegeben"
 exit 1
fi

show_build_information

# Ggf. erstmal Aufraeumen, und den Workspace komplett löschen
# Zur Zeiteersparnis geschieht das Loeschen als Hintergrundprozess
if [ $CLEANUP != 0 ];  then
 to_output "Entferne alten Workspace (Hintergrundprozess)"
 if [ -d "$WORKSPACE" ]; then
  mv $WORKSPACE "$WORKSPACE"__removal_still_in_progress_PID-$$
  rm -rf "$WORKSPACE"__removal_still_in_progress_PID-$$ &
 fi
fi

# ggf. Workspace erzeugen und Gluon aus Git holen
if [ ! -d "$WORKSPACE" ]; then
 to_output "Clone Gluon in neuen Workspace"
 git clone https://github.com/freifunk-ffm/gluon.git $WORKSPACE
 to_output  "Clone Site in neuen Workspace"
 git clone https://github.com/freifunk-ffm/site-ffffm.git $WORKSPACE/site
fi

# Gluon und site.conf aus dem Github Branch holen
cd $WORKSPACE
to_output  "Checkout $GLUON_BRANCH Branch von Gluon und Site"
git checkout ${GLUON_BRANCH}
git pull
cd $WORKSPACE/site
git checkout ${GLUON_BRANCH}
git pull

cd $WORKSPACE
to_output "Update OpenWrt"
make update
check_last_exitcode

# Alte Images vorher immer komplett entfernen
to_output "Loesche alten Image Ordner"
if [ -d "$WORKSPACE/output" ]; then
 rm -rf ${WORKSPACE}/output
fi
# Einen OpenWrt-Download-Cache-Ordner anlegen
to_output "Erstelle Symlink auf Ordner dl-cache"
if [ -d "${WORKSPACE}/openwrt" ]; then
 RAIDER_HEISST_JETZT_TWIX="openwrt"
else
 RAIDER_HEISST_JETZT_TWIX="lede"
fi

cd ${WORKSPACE}/${RAIDER_HEISST_JETZT_TWIX}
mkdir -p ../../dl-cache
if [ -d "dl" ]; then
	rm -rf dl
fi
ln -s ../../dl-cache ${WORKSPACE}/${RAIDER_HEISST_JETZT_TWIX}/dl
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
to_output "BROKEN = $BROKEN"

############
# Bauen
############
for GLUON_TARGET in $FRB_TARGETS
do
 export GLUON_TARGET
 to_output "Baue Target ${GLUON_TARGET}"
 make ${FRB_BPARAMETER}
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

# Die Hashes ggf. noch mit einem ECDSA-Key signieren (zur absoluten Sicherheit).
if [ "$FRB_SIGNKEY_PRIVATE" != "none" ];  then
 to_output "Signiere die Hashedatei"
 # ECDSA signieren der Hash-Datei und verschieben in output/images/sysupgrade
 echo --- >> ${hashfile_MD5}
 echo --- >> ${hashfile_SHA256}
 ecdsasign ${hashfile_MD5} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_MD5}
 ecdsasign ${hashfile_SHA256} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_SHA256}
 mv ${hashfile_MD5} .
 mv ${hashfile_SHA256} .
 # Damit es auch kontrolliert werden kann -> Bereitstellen des öffentlichen  ECDSA-Schluessels
 to_output "Public ECDSA-Schluessel bereitstellen"
 ecdsakeygen -p < ${FRB_SIGNKEY_PRIVATE} > ecdsa-key-${GLUON_RELEASE}.pub
 cd ${WORKSPACE}
fi

if [ $FRB_CREATE_DARCHIVE != 0 ];  then
  to_output "Vorbereitung der Deplay-Informationen"
  # Verschieben der opkg-Module an Frankfurter Zielort -> 'output/images/sysupgrade/modules'

  if [ "$RAIDER_HEISST_JETZT_TWIX" == "lede" ]; then
    # lede
    mv ${WORKSPACE}/output/packages ${WORKSPACE}/output/images/sysupgrade/modules
  else
    # OpenWrt
    mv ${WORKSPACE}/output/modules ${WORKSPACE}/output/images/sysupgrade
  fi
  # Firmware-Information erzeugen
  echo ${GLUON_RELEASE} > version
  mv version ${WORKSPACE}/output/images

  # Deploy-Archiv erzeugen
  to_output "Erzeuge Deploy-Archiv"
  cd ${WORKSPACE}/output/images
  tar cvf gluon-ffffm-${GLUON_RELEASE}.tar.xz  -I "xz $FRB_XZPARAMETER" *
  to_output  "Das Deploy-Archive liegt hier: ${WORKSPACE}/output/images/gluon-ffffm-${GLUON_RELEASE}.tar.xz"
fi

#Fertig!
to_output  "Fertig!"

show_build_information


