###########################################################################
#/bin/bash
# script for searching DVB-T und DVB-C channels
# feel free to use this script for any purpose.
###########################################################################


#------------------- BITTE HIER AENDERN !!!!----------[BEGIN]-----------------------------------------
# Dieses script benötigt hier der Einfachheit halber einige AENDERUNGEN der Pfade zu
# den Anwendungen. Bitte die folgenden Zeilen anpassen. Alles nach einer Raute ist wie in
# jedem Bash-script ein Kommentar.

# Damit jeder auch hier anpasst eine Abfrage. ;o)
# Nur fuer die etwas zu bequemen linvdr und ct'-vdr user.
# [YES,NO], default:NO => BITTE AUF YES AENDERN !!!
USER_HAS_CHANGED_THIS_PART_OF_FILE=YES

# Wo befindet sich das Programm scan aus dem linuxtv-dvb-1.x.x package
# auf deinem System? Normalerweise in /usr/bin oder /usr/local/bin
SCAN=/usr/local/bin/dvbscan		# default: /usr/src/DVB/apps/scan

# Wo sind die Konfigurationsdateien vom vdr?
# normalerweise entweder /video/vdr oder /etc/vdr
CONFDIR=/etc/vdr		# default: /etc/vdr

# Wie soll die neu erstellte channels.conf heißen?
# default: $CONFDIR/channels.conf.aktuell
CONF_FILE=$CONFDIR/scan/channels.conf.aktuell

# Soll nach Kabelfrequenzen (DVB-C) gesucht werden?
# falls hier mit NO beantwortet wird werden die zugehörigen Kabeldevices ignoriert
CABLE=YES			# search for digital cable?		[YES,NO], default: YES
CABLE_ADAPTER=0			# use DVB /dev/dvb/adapterN		[0,1,2,3], default: 0 (erste Karte)
CABLE_FRONTEND=0		# use DVB /dev/dvb/adapter?/frontendN	[0,1,2,3], default: 0
CABLE_DEMUX=0			# use DVB /dev/dvb/adapter?/demuxN	[0,1,2,3], default: 0

# Fuer fast alle Kabelnetze gilt Symbolrate=6900000, aber einige wenige
# Betreiber nutzen auch beispielsweise Symbolrate=6875000 => normalerweise keine Anpassung nötig.
# Hier sind auch mehrere Symbolraten als Aufzaehlung moeglich, z.B. CABLE_SYMBOLRATES="6875000 6900000"
# In diesem Falle werden u.U. jedoch viele Sender doppelt gefunden!
CABLE_SYMBOLRATES="6900000"	# these are the symbolrates for cable	default: "6900000"

# Soll nach terrestrischen Frequenzen gesucht werden?
# falls hier mit NO beantwortet wird werden die zugehörigen DVB-T-devices ignoriert
TERRESTRIAN=YES			# search for terrestrian DVB?		[YES,NO], default: YES
TERRESTRIAN_ADAPTER=1		# use DVB /dev/dvb/adapterN		[0,1,2,3], default: 1 (zweite Karte)
TERRESTRIAN_FRONTEND=0		# use DVB /dev/dvb/adapter?/frontendN	[0,1,2,3], default: 0
TERRESTRIAN_DEMUX=0		# use DVB /dev/dvb/adapter?/demuxN	[0,1,2,3], default: 0

# okay, das sollte alles sein. :o) Speichern nicht vergessen.
#------------------------------------------------------[END]-------------------------------------------

















#___________PLEASE DONT'T TOUCH THIS BEGINNING FROM HERE________________________________________________
#
# these are the advanced options for this script
#
SEARCHLIST=$CONFDIR/scan/searchlist
VHF_CHAN_5_TO_12="177500000 184500000 191500000 198500000 205500000 212500000 219500000 226500000"
UHF_CHAN_21_TO_68="474000000 482000000 490000000 498000000 506000000 514000000 522000000 530000000 \
     538000000 546000000 554000000 562000000 570000000 578000000 586000000 594000000 \
     602000000 610000000 618000000 626000000 634000000 642000000 650000000 658000000 \
     666000000 674000000 682000000 690000000 698000000 706000000 714000000 722000000 \
     730000000 738000000 746000000 754000000 762000000 770000000 778000000 786000000 \
     794000000 802000000 810000000 818000000 826000000 834000000 842000000 850000000"
CABLE_CHAN_5_TO_68="177500000 184500000 191500000 198500000 205500000 212500000 \
     219500000 226500000 234000000 242000000 250000000 258000000 266000000 274000000 \
     282000000 290000000 298000000 306000000 314000000 322000000 330000000 338000000 \
     346000000 354000000 362000000 370000000 378000000 386000000 394000000 402000000 \
     410000000 418000000 426000000 434000000 442000000 450000000 458000000 466000000 \
     474000000 482000000 490000000 498000000 506000000 514000000 522000000 530000000 \
     538000000 546000000 554000000 562000000 570000000 578000000 586000000 594000000 \
     602000000 610000000 618000000 626000000 634000000 642000000 650000000 658000000 \
     666000000 674000000 682000000 690000000 698000000 706000000 714000000 722000000 \
     730000000 738000000 746000000 754000000 762000000 770000000 778000000 786000000 \
     794000000 802000000 810000000 818000000 826000000 834000000 842000000 850000000"
# FEC=2/3 normally sufficent; may be more than one separated by space: ["1/2","2/3","3/4","5/6","7/8"]
FEC="2/3"
MOD_TERR="QAM64"		# normally only QAM64
# MOD_TERR="QAM64 QAM16"	# but other modulations are useable too, also in series separated with space
MOD_CABLE="QAM64"		# normally only QAM64
# MOD_CABLE="QAM64 QAM16"	# but other modulations are useable too, also in series
TERRESTRIAN_INVERSION=0FF	# [ON,OFF,AUTO]		default: OFF
CABLE_INVERSION=AUTO		# [ON,OFF,AUTO]		default: AUTO, (unused because not needed)
#____ end of advanced options _______________________________________________________________________






clear
echo $0
if [ $USER_HAS_CHANGED_THIS_PART_OF_FILE = "NO" ] ; then
  echo " "
  echo " "
  echo " "
  echo "Vielleicht solltest du doch erst lesen?"
  echo " "
  echo "Dieses bash-script muss erst noch editiert werden."
  echo "Bitte dazu die Datei README lesen."
  echo "$0 wird jetzt beendet"
  exit 1
  fi
echo "________________wirbels DVB-T/C scan script_______________"
echo " "
echo "Für scan muessen vdr und runvdr gekillt werden."
echo "Das script laeuft einige Minuten und kann mit <CTRL>+c"
echo "abgebrochen werden."
echo "bitte <CTRL>+c zum Abbrechen oder eine beliebige Taste zum"
echo "Fortsetzen drücken"
echo " "
echo "____________________________________________________________"
read # just waiting for the "any key" ;)
case "$TERRESTRIAN_INVERSION" in
    ON)
	TERR_INV=1
	;;
    OFF)
	TERR_INV=0
	;;
    *)
	TERR_INV=2
	;;
    esac
case "$CABLE_INVERSION" in
    ON)
	CABLE_INV=1
	;;
    OFF)
	CABLE_INV=0
	;;
    *)
	CABLE_INV=2
	;;
    esac
killall runvdr > /dev/null 2>&1
killall vdr  > /dev/null 2>&1
if [ ! -e $CONFDIR/scan ]; then
  mkdir -p $CONFDIR/scan
  fi
if [ -e $CONF_FILE ]; then
  echo Loesche alte Datei $CONF_FILE
  rm $CONF_FILE
  fi
function search_dvb_t()
{
echo ":TERRESTRISCH_`eval date +%x`"  >> $CONF_FILE
if [ ! -e $SEARCHLIST.dvb-t ]; then
  echo "Keine Frequenzliste DVB-T gefunden, erstelle neue Liste."
  for MOD in $MOD_TERR ; do
   for F in $FEC ; do
    for FREQUENCY in $VHF_CHAN_5_TO_12 ; do
     echo "T $FREQUENCY 7MHz $F NONE $MOD 8k 1/8 NONE" >> $SEARCHLIST.dvb-t
     done
    done
   done
  for MOD in $MOD_TERR ; do
   for F in $FEC ; do
    for FREQUENCY in $UHF_CHAN_21_TO_68 ; do
     echo "T $FREQUENCY 8MHz $F NONE $MOD 8k 1/8 NONE" >> $SEARCHLIST.dvb-t
     done
    done
   done
  fi
$SCAN -i $TERR_INV -a $TERRESTRIAN_ADAPTER -f $TERRESTRIAN_FRONTEND -d $TERRESTRIAN_DEMUX -5 -o vdr $SEARCHLIST.dvb-t >> $CONF_FILE
}

function search_dvb_c()
{
echo ":KABEL_`eval date +%x`"  >> $CONF_FILE
# creating new list if needed
if [ ! -e $SEARCHLIST.dvb-c ]; then
  echo "Keine Frequenzliste DVB-C gefunden, erstelle neue Liste."
  for MOD in $MOD_CABLE ; do
   for FREQUENCY in $CABLE_CHAN_5_TO_68 ; do
    for SYMBOLRATE in $CABLE_SYMBOLRATES ; do
     echo "C $FREQUENCY $SYMBOLRATE NONE $MOD" >> $SEARCHLIST.dvb-c
     done
    done
   done
  fi
$SCAN -a $CABLE_ADAPTER -f $CABLE_FRONTEND -d $CABLE_DEMUX -5 -o vdr $SEARCHLIST.dvb-c >> $CONF_FILE
}

if [ $TERRESTRIAN = "YES" ] ; then
  echo "Suche nach DVB-T."
  search_dvb_t
  fi

if [ $CABLE = "YES" ] ;  then
  echo "Suche nach DVB-C."
  search_dvb_c
  fi

echo ":`eval date +%x`"  >> $CONF_FILE
clear
echo "Neue $CONF_FILE angelegt."
echo "Bitte noch nachbearbeiten und dann nach"
echo "$CONFDIR/channels.conf kopieren."

