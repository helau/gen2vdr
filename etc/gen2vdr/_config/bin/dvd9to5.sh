#!/bin/bash
source /_config/bin/g2v_funcs.sh

#################################################################
# Scriptname: DVD9to5.sh					#
# Version: 1.0							#
# Author: Imsadi / Andreas					#
# Beschreibung: Diese Script wandelt eine DVD9 zu einer DVD5	#
# 		um eine Sicherheitskopie einer eigenen DVD	#
# 		zu erstellen.					#
#		Es ist nicht gestattet mit diesem Script	#
#			>>>R A U B K O P I E N<<< 		#
#		zu erstellen.					#
#								#
# Benoetigte Programme: dvdauthor,mplayer,mencoder,requant,	#
# 			mkisofs,tcextract,tcprobe,tccat,	#
#			tcmplex-panteltje,lsdvd			#
#################################################################

## Variablen ##
AWK=/bin/awk
CAT=/bin/cat
CD=cd
CUT=/bin/cut
DVDAUTHOR=/usr/bin/dvdauthor
ECHO=/bin/echo
EJECT=/usr/bin/eject
GREP=/bin/grep
LN=/bin/ln
LS=/bin/ls
LSDVD=/usr/bin/lsdvd
MENC=/usr/bin/mencoder
MPLAYER=/usr/bin/mplayer
MKISOFS=/usr/bin/mkisofs
MV=/bin/mv
NICE=/usr/bin/nice
NICE_ARGS="-n 19"
REQUANT=/usr/bin/tcrequant
RM=/bin/rm
SLEEP=/bin/sleep
TCCAT=/usr/bin/tccat
TCM=/usr/bin/tcmplex-panteltje
TCP=/usr/bin/tcprobe
TCEXTRACT=/usr/bin/tcextract
TR=/bin/tr

TEMP=/mnt/data/film/tmp
ENDURL=/mnt/data/film/burn
LINKLOG=/var/log/vdr/dvd9to5/dvdlink.log
LOGVIDEO=/var/log/vdr/dvd9to5/dvdripvideo.log
LOGAUDIO=/var/log/vdr/dvd9to5/dvdripaudio.log
LOGFILE=/var/log/vdr/dvd9to5/dvd9to5.log
DUMMYDIR=/var/log/vdr/dvd9to5

DVD=hdd
DVD_SIZE=4700000000

## !!! Ab hier nichts mehr aendern !!! ##
VIDEO=dvdrip.vob
RIPVIDEO=ripvideo.m2v
RIPAUDIO=ripaudio.mp2
RIPAUDIO1=ripaudio1.mp2
ENDVIDEO=endvideo.m2v

AC3_DE_EN_DUMMY=ac3_de_ac3_en.dummy
AC3_DE_DUMMY=ac3_de.dummy
STEREO_DE_DUMMY=stereo_de.dummy

TITLEREAD="Disc Title:"
TRACKREAD="Longest track:"
AUDIO_AC3_DE="ac3 (5.1) Sprache: de"
AUDIO_AC3_EN="ac3 (5.1) Sprache: en"
AUDIO_STEREO_DE="(stereo) Sprache: de"


# !!! Der Job beginnt !!!

### Loeschen eventuell vorhandener Dateileichen
### einer vorherigen Konvertierung mit ABBRUCH
if [ -e $TEMP/$VIDEO ]; then
	$NICE $NICE_ARGS rm $TEMP/$VIDEO
fi

if [ -e $TEMP/$RIPVIDEO ]; then
	$NICE $NICE_ARGS rm $TEMP/$RIPVIDEO
fi

if [ -e $TEMP/$RIPAUDIO ]; then
	$NICE $NICE_ARGS rm $TEMP/$RIPAUDIO
fi

if [ -e $TEMP/$RIPAUDIO1 ]; then
	$NICE $NICE_ARGS rm $TEMP/$RIPAUDIO1
fi

if [ -e $TEMP/$ENDVIDEO ]; then
	$NICE $NICE_ARGS rm $TEMP/$ENDVIDEO
fi

if [ -e $TEMP/*.mpg ]; then
	$NICE $NICE_ARGS rm $TEMP/*.mpg
fi

if [ -d $TEMP/DVD_STRUKTUR ]; then
	$NICE $NICE_ARGS rm -r $TEMP/DVD_STRUKTUR
fi

if [ -e $LINKLOG ]; then
	rm $LINKLOG
fi

if [ -e $LOGVIDEO ]; then
	rm $LOGVIDEO
fi

if [ -e $LOGAUDIO ]; then
	rm $LOGAUDIO
fi

if [ -e $LOGFILE ]; then
	rm $LOGFILE
fi

if [ -e $DUMMYDIR/*.dummy ]; then
	rm $DUMMYDIR/*.dummy
fi
###


### Link dvd bei Bedarf auf das gewuenschte
### Device setzen (Variable DVD)
ls -l /dev/dvd 2>&1 > $LINKLOG

if [ ! /dev/dvd = $DVD ]; then
	cd /dev
	rm dvd
	ln -s $DVD dvd
fi
###


cd $TEMP
$TCP -i /dev/$DVD -H 10 2>&1 > /dev/null
instatus=$?
if [ "$instatus" -gt 0 ] ; then
   $EJECT /dev/$DVD
   svdrps "MESG ! Bitte DVD einlegen !"
   sleep 10
   instatus=1
   while [ "$instatus" -gt 0 ]
   do
       $TCP -i /dev/$DVD -H 10 2>&1 > /dev/null
       instatus=$?
       if [ $instatus -gt 0 ]; then
       svdrps "MESG ! Keine DVD eingelegt, bitte nachholen !"
       $EJECT /dev/$DVD
       sleep 10
       fi
   done
fi


### Audio Spuren filtern und in Logaudio schreiben
$MENC dvd://1 -o -v > $LOGAUDIO

### Titel bzw. Longest Track in Logvideo schreiben
$LSDVD > $LOGVIDEO
###


### Generelles Logfile fuer alle folgenden Befehle anlegen
exec > $LOGFILE; exec 2>&1
###


### Titel aus Logvideo auslesen
TITEL=`cat $LOGVIDEO | $GREP "$TITLEREAD" | awk '{print $3}'`
svdrps "MESG ! Titel = $TITEL !"

### Longest Track aus Logvideo auslesen
TRACK=`cat $LOGVIDEO | $GREP "$TRACKREAD" | awk '{print $3}'`
###


### Video auslesen
svdrps "MESG ! Starte Video auslesen !" && $NICE $NICE_ARGS $TCCAT -i /dev/$DVD -T $TRACK,-1 > $VIDEO

if [ "$?" = "0" ] ; then
	$EJECT /dev/$DVD
else
	svdrps "MESG ! ABBRUCH, Video auslesen fehlgeschlagen !" && exit 1
fi
###


### Video extrahieren
svdrps "MESG ! Starte Video extrahieren !" && $NICE $NICE_ARGS $TCEXTRACT -i $VIDEO -t vob -x mpeg2 > $RIPVIDEO

if [ "$?" != "0" ] ; then
	svdrps "MESG ! ABBRUCH, Video extrahieren fehlgeschlagen !" && exit 1
fi
###


### Audio aus Logaudio auslesen
AID_AC3_DE="$(cat $LOGAUDIO | grep "$AUDIO_AC3_DE" | tr -d '.' | awk '{print $9}')"
AID_AC3_EN="$(cat $LOGAUDIO | grep "$AUDIO_AC3_EN" | tr -d '.' | awk '{print $9}')"
AID_STEREO_DE="$(cat $LOGAUDIO | grep "$AUDIO_STEREO_DE" | tr -d '.' | awk '{print $9}')"
###


### Audio extrahieren
if [ "$AID_AC3_DE" ] && [ "$AID_AC3_EN" ]; then
	echo > $DUMMYDIR/$AC3_DE_EN_DUMMY
	svdrps "MESG ! Starte Audio (ac3 de,en) extrahieren !" && $NICE $NICE_ARGS $MPLAYER $VIDEO -aid $AID_AC3_DE -dumpaudio -dumpfile $RIPAUDIO && $NICE $NICE_ARGS $MPLAYER $VIDEO -aid $AID_AC3_EN -dumpaudio -dumpfile $RIPAUDIO1

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $VIDEO
		else
			svdrps "MESG ! ABBRUCH, Audio extrahieren fehlgeschlagen !" && exit 1
		fi
fi

if [ "$AID_AC3_DE" ] && [ ! "$AID_AC3_EN" ]; then
	echo > $DUMMYDIR/$AC3_DE_DUMMY
	svdrps "MESG ! Starte Audio (ac3 de) extrahieren !" && $NICE $NICE_ARGS $MPLAYER $VIDEO -aid $AID_AC3_DE -dumpaudio -dumpfile $RIPAUDIO

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $VIDEO
		else
			svdrps "MESG ! ABBRUCH, Audio extrahieren fehlgeschlagen !" && exit 1
		fi
fi

if [ ! "$AID_AC3_DE" ] && [ "$AID_STEREO_DE" ]; then
	echo > $DUMMYDIR/$STEREO_DE_DUMMY
	echo $AID_STEREO_DE | cut -d" " -f1
	svdrps "MESG ! Starte Audio (stereo de) extrahieren !" && $NICE $NICE_ARGS $MPLAYER $VIDEO -aid $AID_STEREO_DE -dumpaudio -dumpfile $RIPAUDIO

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $VIDEO
		else
			svdrps "MESG ! ABBRUCH, Audio extrahieren fehlgeschlagen !" && exit 1
		fi
fi
###


### Videofile bei Bedarf verkleinern (shrinken)
if [ -e $TEMP/$RIPVIDEO -a -e $TEMP/$RIPAUDIO -a -e $TEMP/$RIPAUDIO1 ]; then
	M2VGR=`ls -l $TEMP/$RIPVIDEO | awk '{print $5}'`
	AUDIO1GR=`ls -l $TEMP/$RIPAUDIO | awk '{print $5}'`
	AUDIO2GR=`ls -l $TEMP/$RIPAUDIO1 | awk '{print $5}'`
	GR=$(( $M2VGR + $AUDIO1GR + $AUDIO2GR ))
	svdrps "MESG ! Groesse der Files = $GR !" && FACTOR=`echo $M2VGR $DVD_SIZE $AUDIO1GR $AUDIO2GR |awk '{printf "%f\n",0.05+($1/($2-$3-$4))}' |tr "," "."` && echo "FACTOR zum Verkleinern = ${FACTOR} "

	if [ $GR -gt $DVD_SIZE ] ; then
		svdrps "MESG ! Videofile zu gross, Starte Verkleinern !"
		$NICE $NICE_ARGS cat $TEMP/$RIPVIDEO | $REQUANT $FACTOR > $TEMP/$ENDVIDEO

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $RIPVIDEO
		else
			svdrps "MESG ! ABBRUCH, Verkleinern fehlgeschlagen !" && exit 1
		fi
	else
		svdrps "MESG ! Videofile hat die richtige Groesse !"
		mv $TEMP/$RIPVIDEO $TEMP/$ENDVIDEO
	fi

fi

if [ -e $TEMP/$RIPVIDEO -a -e $TEMP/$RIPAUDIO -a ! -e $TEMP/$RIPAUDIO1 ]; then
	M2VGR=`ls -l $TEMP/$RIPVIDEO | awk '{print $5}'`
	AUDIO1GR=`ls -l $TEMP/$RIPAUDIO | awk '{print $5}'`
	GR=$(( $M2VGR + $AUDIO1GR ))
	svdrps "MESG ! Groesse der Files = $GR !" && FACTOR=`echo $M2VGR $DVD_SIZE $AUDIO1GR |awk '{printf "%f\n",0.05+($1/($2-$3))}' |tr "," "."` && echo "FACTOR zum Verkleinern = ${FACTOR} "

	if [ $GR -gt $DVD_SIZE ] ; then
		svdrps "MESG ! Videofile zu gross, Starte Verkleinern !"
		$NICE $NICE_ARGS cat $TEMP/$RIPVIDEO | $REQUANT $FACTOR > $TEMP/$ENDVIDEO

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $RIPVIDEO
		else
			svdrps "MESG ! ABBRUCH, Verkleinern fehlgeschlagen !" && exit 1
		fi
	else
		svdrps "MESG ! Videofile hat die richtige Groesse !"
		mv $TEMP/$RIPVIDEO $TEMP/$ENDVIDEO
	fi

fi
###


### Zusammenfuegen (muxen)
if [ -e $TEMP/$ENDVIDEO -a -e $TEMP/$RIPAUDIO -a -e $TEMP/$RIPAUDIO1 ]; then
	svdrps "MESG ! Starte Mpg Erstellung !" && $NICE $NICE_ARGS $TCM -i $ENDVIDEO -0 $RIPAUDIO -1 $RIPAUDIO1 -o $TITEL.mpg -m d

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $ENDVIDEO
			$NICE $NICE_ARGS rm $RIPAUDIO
			$NICE $NICE_ARGS rm $RIPAUDIO1
		else
			svdrps "MESG ! ABBRUCH, Mpg Erstellung fehlgeschlagen !" && exit 1
		fi
fi

if [ -e $TEMP/$ENDVIDEO -a -e $TEMP/$RIPAUDIO -a ! -e $TEMP/$RIPAUDIO1 ]; then
	svdrps "MESG ! Starte Mpg Erstellung !" && $NICE $NICE_ARGS $TCM -i $ENDVIDEO -0 $RIPAUDIO -o $TITEL.mpg -m d

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $ENDVIDEO
			$NICE $NICE_ARGS rm $RIPAUDIO
		else
			svdrps "MESG ! ABBRUCH, Mpg Erstellung fehlgeschlagen !" && exit 1
		fi
fi
###


### Authoring (VIDEO_TS und AUDIO_TS) erstellen
if [ -e $DUMMYDIR/$AC3_DE_EN_DUMMY ]; then
	svdrps "MESG ! Starte Dvd-Authoring !" && $NICE $NICE_ARGS $DVDAUTHOR -t -a ac3+de,ac3+en -o $TITEL $TITEL.mpg && $DVDAUTHOR -T -o $TITEL

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $TITEL.mpg
			rm $DUMMYDIR/$AC3_DE_EN_DUMMY
		else
			if [ -d $TITEL ]; then
				mv -f $TITEL DVD_STRUKTUR
			fi

			svdrps "MESG ! ABBRUCH, Dvd-Authoring fehlgeschlagen !" && exit 1
		fi
fi

if [ -e $DUMMYDIR/$AC3_DE_DUMMY ]; then
	svdrps "MESG ! Starte Dvd-Authoring !" && $NICE $NICE_ARGS $DVDAUTHOR -t -a ac3+de -o $TITEL $TITEL.mpg && $DVDAUTHOR -T -o $TITEL

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $TITEL.mpg
			rm $DUMMYDIR/$AC3_DE_DUMMY
		else
			if [ -d $TITEL ]; then
				mv -f $TITEL DVD_STRUKTUR
			fi

			svdrps "MESG ! ABBRUCH, Dvd-Authoring fehlgeschlagen !" && exit 1
		fi
fi

if [ -e $DUMMYDIR/$STEREO_DE_DUMMY ]; then
	svdrps "MESG ! Starte Dvd-Authoring !" && $NICE $NICE_ARGS $DVDAUTHOR -t -a mp2+de -o $TITEL $TITEL.mpg && $DVDAUTHOR -T -o $TITEL

		if [ "$?" = "0" ] ; then
			$NICE $NICE_ARGS rm $TITEL.mpg
			rm $DUMMYDIR/$STEREO_DE_DUMMY
		else
			if [ -d $TITEL ]; then
				mv -f $TITEL DVD_STRUKTUR
			fi

			svdrps "MESG ! ABBRUCH, Dvd-Authoring fehlgeschlagen !" && exit 1
		fi
fi
###


### Fuer eine Disc ID in Grossbuchstaben (Parameter -V) in mkisofs
#DISC_ID="$(echo $TITEL|tr "[a-zäöü]" "[A-ZÄÖÜ]")"
###


### Iso erstellen
#svdrps "MESG ! Starte Iso Erstellung !" && $NICE $NICE_ARGS $MKISOFS -V ${DISC_ID:0:31} -dvd-video -o $TITEL.iso $TITEL

svdrps "MESG ! Starte Iso Erstellung !" && $NICE $NICE_ARGS $MKISOFS -V $TITEL -dvd-video -o $TITEL.iso $TITEL

if [ "$?" = "0" ] ; then
	mv $TITEL.iso $ENDURL
	svdrps "MESG ! FERTIG - Iso ist in $ENDURL !"
	$NICE $NICE_ARGS rm -rf $TITEL
else
	svdrps "MESG ! ABBRUCH, Iso Erstellung fehlgeschlagen !" && exit 1
fi


### Musste der Link dvd oben im Script auf ein bestimmtes Device
### (Variable DVD) gesetzt werden (z.B: wenn man mehrere Lw. im System
### eingebaut hat), so wird dieser nun wieder auf das Device
### welches vor Abarbeitung dieses Scripts auf dvd zeigte zurueckgestellt
ORG_DEV_GELINKT="> "
LINK_RETOUR="$(cat $LINKLOG | grep "$ORG_DEV_GELINKT" | awk '{print $11}')"

if [ ! /dev/dvd = $LINK_RETOUR ]; then
	cd /dev
	rm dvd
	ln -s $LINK_RETOUR dvd
fi
###

exit 0