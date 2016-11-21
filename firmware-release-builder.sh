#!/bin/bash
echo
echo FirmwareReleaseBuilder
echo

##############################################################################
# Dieses Skript ist fuer den Bau von Frankfurter FW-Releases vorgesehen.
# Das Skript ist nicht für die FW-Entwicklung geeignet! Es wird viel gelöscht!
##############################################################################


# Default Werte
FRB_TARGETS=${FRB_TARGETS:-"ar71xx-generic x86-generic x86-64 x86-kvm_guest x86-xen_domu mpc85xx-generic ar71xx-nand"}
FRB_BRANCH=${FRB_BRANCH:-none}
FRB_VERSION=${FRB_VERSION:-Homebrew}
FRB_CLEANUP=${FRB_CLEANUP:-1}
FRB_BROKEN=${FRB_BROKEN:-0}
FRB_BROKEN_TARGETS=${FRB_BROKEN_TARGETS:-0}
FRB_PRIORITY=${FRB_PRIORITY:-0}
FRB_CREATE_DARCHIVE=${FRB_CREATE_DARCHIVE:-1}
FRB_SIGNKEY_PRIVATE=${FRB_SIGNKEY_PRIVATE:-"none"}
FRB_SIGNKEY_PUBLIC=${FRB_SIGNKEY_PUBLIC:-"none"}
FRB_BPARAMETER=${FRB_BPARAMETER:-"-j4 V=s"}

###################################################################
# Usage Info
###################################################################
show_help() {
cat << EOF
Usage: ${0##*/} ...
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

EOF
}

###################################################################
# Optionen parsen
###################################################################
while getopts "T:B:V:P:s:o:p:c:b:t:a:h" opt; do
  case $opt in
    T) FRB_TARGETS=$OPTARG
       ;;
    B) FRB_BRANCH=$OPTARG
       ;;
    V) FRB_VERSION=$OPTARG
       ;;
    P) FRB_PRIORITY=$OPTARG
       ;;
    s) FRB_SIGNKEY_PRIVATE=$OPTARG
       ;;
    o) FRB_SIGNKEY_PUBLIC=$OPTARG
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
Versionsstring:       $FRB_VERSION
Workspace löschen:    $FRB_CLEANUP
BROKEN Images:        $FRB_BROKEN
BROKEN Targets:       $FRB_BROKEN_TARGETS
GLUON_PRIORITY:       $FRB_PRIORITY
Erzeuge Gesamtarchiv: $FRB_CREATE_DARCHIVE
Pfad Signkey privat:  $FRB_SIGNKEY_PRIVATE
Pfad Signkey public:  $FRB_SIGNKEY_PUBLIC
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
export BUILD_NUMBER=$(date '+%m%d%H%M')
export GLUON_RELEASE=${FRB_VERSION}-${GLUON_BRANCH}-${BUILD_NUMBER}
export GLUON_PRIORITY=${FRB_PRIORITY}
export BROKEN=${FRB_BROKEN}
CLEANUP=${FRB_CLEANUP}
WORKSPACE="$(pwd)/workspace-${FRB_VERSION}-${GLUON_BRANCH}"


# Wenn kein Branch definiert wurde -> Abbruch
if [ "$GLUON_BRANCH" == "none" ];  then
 to_output "Abbruch: Es wurde kein Branch mittels '-B' angegeben"
 exit 1
fi

show_build_information

# ggf. erstmal Aufraeumen, und den Workspace komplett löschen
if [ $CLEANUP != 0 ];  then
 to_output "Loesche Workspace (das kann mehrere Minuten dauern)"
 rm -rf $WORKSPACE
fi

# ggf. Workspace erzeugen und Gluon aus Git holen
if [ ! -d "$WORKSPACE" ]; then
 to_output "Clone Gluon in neuen Workspace"
 git clone https://github.com/freifunk-ffm/gluon.git $WORKSPACE
 to_output  "Clone Site in neuen workspace"
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

# Schauen, ob FRB_BROKEN_TARGETS aktiv ist. Wenn ja, dann immer die volle Anzahl an Möglichkeiten (Images + Targets) bauen.
# FRB_TARGETS verwenden oder komplett ueberschreiben.
if [ $FRB_BROKEN_TARGETS == 1 ]; then
 # All möglichen Targets bauene. Auch die als BROKEN markierten.
 FRB_TARGETS=$(grep -o -E "GluonTarget[,_a-z0-9]*" targets/targets.mk | tr ',' '-' | sed 's/GluonTarget-//')
  # Zur Sicherheit nochmal BROKEN setzen
 export BROKEN=1
fi
to_output "BROKEN = $BROKEN"
to_output "Build Targets = $FRB_TARGETS"

# Alte Images vorher immer komplett entfernen
to_output "Loesche alten Image Ordner"
rm -rf ${WORKSPACE}/output

# Bauen
for GLUON_TARGET in $FRB_TARGETS
do
 export GLUON_TARGET
 to_output "Build target ${GLUON_TARGET}"
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
 # Damit das auch kontrolliert werden kann -> Bereitstellen des öffentlichen  ECDSA-Schluessels
 if [ "$FRB_SIGNKEY_PUBLIC" != "none" ];  then
  to_output "Public ECDSA-Schluessel bereitstellen"
  cp ${FRB_SIGNKEY_PUBLIC} ecdsa-key-${GLUON_RELEASE}.pub
 fi
 cd ${WORKSPACE}
fi

if [ $FRB_CREATE_DARCHIVE != 0 ];  then
  to_output "Vorbereitung der Deplay-Informationen"
  # Verschieben der opkg-Module an Frankfurter Zielort -> 'output/images/sysupgrade/modules'
  mv ${WORKSPACE}/output/modules ${WORKSPACE}/output/images/sysupgrade
  # Firmware-Information erzeugen
  echo ${GLUON_RELEASE} > version
  mv version ${WORKSPACE}/output/images

  # Deploy-Archiv erzeugen
  to_output "Erzeuge Deploy-Archiv"
  cd ${WORKSPACE}/output/images
  tar czvf gluon-ffffm-${GLUON_RELEASE}.tar.gz *
  to_output  "Das Deploy-Archive liegt hier: ${WORKSPACE}/output/images/gluon-ffffm-${GLUON_RELEASE}.tar.gz"
fi

#Fertig!
to_output  "Fertig!"

show_build_information


