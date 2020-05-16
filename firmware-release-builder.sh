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
FRB_TARGETS=${FRB_TARGETS:-"alle"}
FRB_GLUON_REPO=${FRB_GLUON_REPO:-"https://github.com/freifunk-ffm/gluon.git"}
FRB_GLUON_BRANCH=${FRB_GLUON_BRANCH:-"none"}
FRB_GLUON_TAG=${FRB_GLUON_TAG:-"-"}
FRB_SITE_REPO=${FRB_SITE_REPO:-"https://github.com/freifunk-ffm/site-ffffm.git"}
FRB_SITE_BRANCH=${FRB_SITE_BRANCH:-"none"}
FRB_SITE_TAG=${FRB_SITE_TAG:-"-"}
FRB_FW_UPDATE_BRANCH=${FRB_FW_UPDATE_BRANCH:-"none"}
FRB_VERSION=${FRB_VERSION:-vHomebrew}
FRB_SITE_PATCHES=${FRB_SITE_PATCHES:-0}
FRB_NAME_PATCH_FOLDER=${FRB_NAME_PATCH_FOLDER:-"patches"}
FRB_CLEANUP=${FRB_CLEANUP:-1}
FRB_BROKEN=${FRB_BROKEN:-0}
FRB_BROKEN_TARGETS=${FRB_BROKEN_TARGETS:-0}
FRB_PRIORITY=${FRB_PRIORITY:-0}
FRB_CREATE_DARCHIVE=${FRB_CREATE_DARCHIVE:-1}
FRB_XZPARAMETER=${FRB_XZPARAMETER:-"-T0 -6"}
FRB_SIGNKEY_PRIVATE=${FRB_SIGNKEY_PRIVATE:-"none"}
FRB_BPARAMETER=${FRB_BPARAMETER:-"-j4"}
FRB_VERSION_SUFFIX_1=${FRB_VERSION_SUFFIX_1:-"none"}
FRB_VERSION_SUFFIX_2=${FRB_VERSION_SUFFIX_2:-"none"}

###################################################################
# Usage Info
###################################################################
show_help() {
cat << EOF

Usage: ${0##*/} ...

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
                 (Voreinstellung: "$FRB_VERSION")
    -E <Streing> Eigener erster Suffix fuer die Versionsbezeichnung.
                 (Voreinstellung: Es wird der Parameter von -C übernommen)
    -S <String>  Eigener zweiter Suffix fuer die Versionsbezeichnung.
                 (Voreinstellung: MonatTag)
    -L [0|1]     Lokale Site-Patches anwenden.
                 (Voreinstellung: $FRB_SITE_PATCHES)
    -l <String>  Name des Patch-Ordners innerhalb des Site-Ordners
                 (Voreinstellung: "$FRB_NAME_PATCH_FOLDER)
    -b [0|1]     BROKEN Router-Images bauen?
                 (Voreinstellung: $FRB_BROKEN)
    -t [0|1]     BROKEN Targets bauen?
                 (Voreinstellung: $FRB_BROKEN_TARGETS)
                 Bei 1 werden dann BROKEN-Images fuer "alle" Targets gebaut!
    -P [int]     GLUON_PRIORITY
                 (Voreinstellung: $FRB_PRIORITY)
    -s <String>  Absoluter Pfad und Name des privaten ECDSA-Signkeys. 
                 Falls angegeben, so wird das Manifest damit signiert.
    -p <String>  Build Make-Parameter.
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: "$FRB_BPARAMETER")
    -c [0|1]     Workspace vor dem Bauen löschen?
                 (Voreinstellung: $FRB_CLEANUP)
    -a [0|1]     Ein tar.xz Gesamtarchiv erzeugen?
                 (Voreinstellung: $FRB_CREATE_DARCHIVE)
    -x <String>  Gesamtarchiv xz-Parameter.
                 Liste in Anführungszeichen, getrennt durch Leerzeichen.
                 (Voreinstellung: "$FRB_XZPARAMETER")
    -k <String>  Zu verwendendes Site-Repository.
                 (Voreinstellung $FRB_SITE_REPO)
    -g <String>  Zu verwendendes Gluon-Repository.
                 (Voreinstellung $FRB_GLUON_REPO)
    -w <String>  Zu verwendender Tag des Site-Repositories.
                 Hat Priorität vor dem Parameter -U.
                 (Keine Voreinstellung)
    -v <String>  Zu verwendender Tag des Gluon-Repositories.
                 Hat Priorität vor dem Paramater -B.
                 (Keine Voreinstellung)
    -h           Dieser Text.

EOF
}

###################################################################
# Optionen parsen
###################################################################

while getopts "T:B:C:U:V:P:E:S:L:l:s:p:c:b:t:a:x:g:k:v:w:h" opt; do
  case $opt in
    T) FRB_TARGETS=$OPTARG
       ;;
    C) FRB_FW_UPDATE_BRANCH=$OPTARG
       ;;
    U) FRB_SITE_BRANCH=$OPTARG
       ;;
    B) FRB_GLUON_BRANCH=$OPTARG
       ;;
    V) FRB_VERSION=$OPTARG
       ;;
    P) FRB_PRIORITY=$OPTARG
       ;;
    E) FRB_VERSION_SUFFIX_1=$OPTARG
       ;;
    S) FRB_VERSION_SUFFIX_2=$OPTARG
       ;;
    L) FRB_SITE_PATCHES=$OPTARG
       ;;
    l) FRB_NAME_PATCH_FOLDER=$OPTARG
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
    v) FRB_GLUON_TAG=$OPTARG
       ;;
    w) FRB_SITE_TAG=$OPTARG
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
# Jenkins kann boolesche Variablen nur als "false"/"true" uebergeben.
# Die folgenden Zeilen transformieren Jenkins-Aufrufparameter
# in "0"/"1" zurueck.
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
echo "FRB: $1"
echo ----------------------------------------------------------------
}

# Ausgabe der verwendeten Parameter
show_build_information() {
cat << EOF

Die FW wird/wurde mit folgenden Optionen gebaut:

Targets:              $FRB_TARGETS
FW Update-Branch:     $FRB_FW_UPDATE_BRANCH
Site-Repo:            $FRB_SITE_REPO
Site-Branch:          $FRB_SITE_BRANCH
Site-Tag:             $FRB_SITE_TAG
Gluon-Repo:           $FRB_GLUON_REPO
Gluon-Branch:         $FRB_GLUON_BRANCH
Gluon-Tag:            $FRB_GLUON_TAG
Versionstring:        $FRB_VERSION
Versionsuffix eins:   $FRB_VERSION_SUFFIX_1
Versionsuffix zwei:   $FRB_VERSION_SUFFIX_2
Site-Patches aktiv:   $FRB_SITE_PATCHES
Site-Patch Ordner:    $FRB_NAME_PATCH_FOLDER
Workspace löschen:    $FRB_CLEANUP
BROKEN Images:        $FRB_BROKEN
BROKEN Targets:       $FRB_BROKEN_TARGETS
GLUON_PRIORITY:       $FRB_PRIORITY
Erzeuge Gesamtarchiv: $FRB_CREATE_DARCHIVE
xz-Parameter:         $FRB_XZPARAMETER
Pfad Signkey privat:  $FRB_SIGNKEY_PRIVATE
Buildparameter:       $FRB_BPARAMETER
Workspace:            $WORKSPACE

Name des FW-Releases: $GLUON_RELEASE
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

# Uebernahme der Parameter für den Firmware-Build

# Wenn kein Firmware-Update-Branch definiert wurde -> Abbruch
if [ "$FRB_FW_UPDATE_BRANCH" == "none" ];  then
 show_help
 to_output "Abbruch: Es wurde kein Firmware-Update-Branch mittels '-C' angegeben"
 exit 1
fi

# Wenn kein Site-Tag oder Site-Branch definiert wurde,
# dann den Firmware-Update-Branch verwenden.
# Der Site-Tag hat Priorität.
if [ "$FRB_SITE_TAG" != "-" ]; then
  FRB_SITE_BRANCH="-"
elif [ "$FRB_SITE_BRANCH" == "none" ];  then
 FRB_SITE_BRANCH=${FRB_FW_UPDATE_BRANCH}
fi

# Wenn kein Gluon-Tag oder Gluon-Branch definiert wurde,
# dann den Firmware-Update-Branch verwenden.
# Der Gluon-Tag hat Priorität.
if [ "$FRB_GLUON_TAG" != "-" ]; then
  FRB_GLUON_BRANCH="-"
elif [ "$FRB_GLUON_BRANCH" == "none" ];  then
 FRB_GLUON_BRANCH=${FRB_FW_UPDATE_BRANCH}
fi


# Suffix 1 (Branchname fuer GLUON_RELEASE)
if [ "$FRB_VERSION_SUFFIX_1" == "none" ];  then
 BRANCH_SHORTENER=$(date '+%m%d')
 FRB_VERSION_SUFFIX_1=${BRANCH_SHORTENER}
else
 BRANCH_SHORTENER=${FRB_VERSION_SUFFIX_1}
fi

# Suffix 2 (Build-Nummer fuer GLUON_RELEASE)
if [ "$FRB_VERSION_SUFFIX_2" == "none" ];  then
 BUILD_NUMBER=$(date '+%m%d')
 FRB_VERSION_SUFFIX_2=${BUILD_NUMBER}
else
 BUILD_NUMBER=${FRB_VERSION_SUFFIX_2}
fi

export GLUON_BRANCH=${FRB_FW_UPDATE_BRANCH}
export GLUON_RELEASE=${FRB_VERSION}-${BRANCH_SHORTENER}-${BUILD_NUMBER}
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
 to_output "Klone Gluon in leeren Workspace"
 git clone $FRB_GLUON_REPO $WORKSPACE
 check_last_exitcode
 to_output  "Klone Site in leeren Workspace"
 git clone $FRB_SITE_REPO $WORKSPACE/site
 check_last_exitcode
fi

# Gluon und Site aus den Git-Branches bzw. Git-Tags holen

# Gluon-Repo
cd $WORKSPACE
to_output  "Gluon-Repository aktualisieren"
git fetch
check_last_exitcode
# Was soll verwendet werden: Branch oder Tag ?
if [ "$FRB_GLUON_TAG" == "-" ];  then
 to_output  "Gluon-Repository checkout Branch"
 echo "Gluon-Repo:  "$FRB_GLUON_REPO
 echo "Repo-Branch: "$FRB_GLUON_BRANCH
 echo
 git reset --hard origin/${FRB_GLUON_BRANCH}
else
 to_output  "Gluon-Repository checkout Tag"
 echo "Gluon-Repo: "$FRB_GLUON_REPO
 echo "Repo-Tag:   "$FRB_GLUON_TAG
 echo
 git reset --hard ${FRB_GLUON_TAG}
fi
check_last_exitcode

# Site-Repo
cd $WORKSPACE/site
to_output  "Site-Repositoriy aktualisieren"
git fetch
check_last_exitcode
# Was soll verwendet werden: Branch oder Tag ?
if [ "$FRB_SITE_TAG" == "-" ];  then
 to_output  "Site-Repository checkout Branch"
 echo "Site-Repo:   "$FRB_SITE_REPO
 echo "Repo-Branch: "$FRB_SITE_BRANCH
 echo
 git reset --hard origin/${FRB_SITE_BRANCH}
else
 to_output  "Site-Repository checkout Tag"
 echo "Site-Repo: "$FRB_SITE_REPO
 echo "Repo-Tag:  "$FRB_SITE_TAG
 echo
 git reset --hard ${FRB_SITE_TAG}
fi
check_last_exitcode


cd $WORKSPACE
to_output "Anwenden von lokalen Site-Patches vor 'make update'"
if [ $FRB_SITE_PATCHES == 1 ]; then
 if [ -d "$WORKSPACE/site/$FRB_NAME_PATCH_FOLDER" ]; then
  cd ${WORKSPACE}/site/$FRB_NAME_PATCH_FOLDER
  if [[ $(echo *.patch)  != "*.patch" ]]; then
   cd $WORKSPACE
   PATCHFILES=*.patch
   for i in site/$FRB_NAME_PATCH_FOLDER/$PATCHFILES
   do
    echo "Angewendeter Patch: $i"
    patch -N -p1 -r - -s -i $i
    echo
   done
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

cd $WORKSPACE
to_output "Anwenden von lokalen Site-Patches nach 'make update'"
if [ $FRB_SITE_PATCHES == 1 ]; then
 if [ -d "$WORKSPACE/site/$FRB_NAME_PATCH_FOLDER" ]; then
  cd ${WORKSPACE}/site/$FRB_NAME_PATCH_FOLDER
  if [[ $(echo *.patch.after_make_update)  != "*.patch.after_make_update" ]]; then
   cd $WORKSPACE
   PATCHFILES=*.patch.after_make_update
   for i in site/$FRB_NAME_PATCH_FOLDER/$PATCHFILES
   do
    echo "Angewendeter Patch: $i"
    patch -N -p1 -r - -s -i $i
    echo
   done
  else
   echo "Keine lokalen Site-Patches gefunden"
  fi
 else
  echo "Keinen Site-Ordner für lokale Patches gefunden"
 fi
else
 echo "Lokale Site-Patches werden nicht angewendet"
fi 

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


# Welche Targets sollen gebaut werden?
# Schauen, ob FRB_BROKEN_TARGETS aktiv ist. Wenn ja, dann immer die volle Anzahl an Möglichkeiten (Images + Targets) bauen.
# FRB_TARGETS verwenden oder komplett ueberschreiben.
if [ $FRB_BROKEN_TARGETS == 1 ]; then
# All möglichen Targets bauene. Auch die als BROKEN markierten.
 FRB_TARGETS=$(grep GluonTarget targets/targets.mk | awk -F, '{print $2 "-" $3}'|sed 's/).*//')
 # Zur Sicherheit nochmal BROKEN setzen
 export BROKEN=1
else
# Oder gefolgt der Standardfall:
# Gibt es bereits eine Vorgabe der zu bauenden Targets,
# oder sollen einfach alle Nicht-BROKEN gebaut werden?
 if [ "$FRB_TARGETS" == "alle" ]; then
  FRB_TARGETS=""
  for GLUON_TARGET in $(make list-targets); do
   FRB_TARGETS="$FRB_TARGETS $GLUON_TARGET"
  done
 fi
fi

to_output "Für folgende Targets werden Images gebaut"
for GLUON_TARGET in $FRB_TARGETS; do
 echo $GLUON_TARGET
done

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

# SHA512 und SHA256 Hashes von allen Images erzeugen, auch von den Factory-Images, und dann alles abspeichern.
# SHA256 wird letztlich noch benötigt. Der SHA256-HASH wird u.a. im Konfig-Modus beim Umflashen angezeigt.
cd ${WORKSPACE}/output/images

to_output  "Erzeuge Image-Hashes"
hashfile_SHA512=../SHA512SUMS-${GLUON_RELEASE}
hashfile_SHA256=../SHA256SUMS-${GLUON_RELEASE}
find -L * -exec sha512sum {} \; > ${hashfile_SHA512}
find -L * -exec sha256sum {} \; > ${hashfile_SHA256}
# Footer an die Hash-Dateien anhängen
echo --- >> ${hashfile_SHA512}
echo --- >> ${hashfile_SHA256}

# Die Hashes ggf. noch mit einem ECDSA-Key signieren (zur absoluten Sicherheit).
if [ "$FRB_SIGNKEY_PRIVATE" != "none" ];  then
 to_output "Signiere die Hash-Dateien"
 # ECDSA signieren der Hash-Dateien
 ecdsasign ${hashfile_SHA512} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_SHA512}
 ecdsasign ${hashfile_SHA256} < ${FRB_SIGNKEY_PRIVATE} >> ${hashfile_SHA256}
 # Die Hash-Dateien an die Zielposition verschieben
 mv ${hashfile_SHA512} .
 mv ${hashfile_SHA256} .
 # Damit es auch kontrolliert werden kann -> Bereitstellen des öffentlichen ECDSA-Schluessels
 to_output "Public ECDSA-Schluessel bereitstellen"
 ecdsakeygen -p < ${FRB_SIGNKEY_PRIVATE} > ecdsa-key-${GLUON_RELEASE}.pub
else
 # Ansonsten einfach nur die Hash-Dateien an die Zielposition verschieben
mv ${hashfile_SHA512} .
mv ${hashfile_SHA256} .
fi

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
  tar cvf gluon-${GLUON_RELEASE}.tar.xz  -I "xz ${FRB_XZPARAMETER}" *
fi

#Fertig!
to_output  "Fertig!"

show_build_information

to_output "Für folgende Targets wurden Images gebaut"
for GLUON_TARGET in $FRB_TARGETS; do
 echo $GLUON_TARGET
done

to_output  "Das Deploy-Archive liegt hier:"
echo ${WORKSPACE}/output/images/gluon-${GLUON_RELEASE}.tar.xz
echo
