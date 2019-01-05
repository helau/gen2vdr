#!/bin/bash
echo "<h2>Aktuelle Versionen der VDR-Plugins</h2>Stand: $(date)<br>"
echo " <a href=\"http://www.vdr-portal.de/board/thread.php?threadid=86871\">Thread im VDR-Portal</a><br><br>"
VW_URL="http://www.vdr-wiki.de/wiki/index.php"
grep -v "No version info" $1 | tr "\r" "\n" | while read i ; do
   if [ "${i:0:2}" = "Pl" ] ; then
      PLG=${i##* }
      echo "<br>Plugin <a href=\"${VW_URL}/${PLG}-plugin\">$PLG</a><br>"
   elif [ "${i:0:3}" = "URL" ] ; then
      URL=${i##* }
   elif [ "${i:0:3}" = "INF" ] ; then
      INFO=${i##*INFO:  }
      echo "&nbsp;&nbsp;Version: <a href=\"${URL}\">$INFO</a><br>"
   elif [ "${i:0:4}" != "Look" ] && [ "${i:0:4}" != "Avai" ] && [ "${i}" != "" ] ; then
      echo "&nbsp;&nbsp;&nbsp;&nbsp;$i<br>"
   fi            
done
echo "<br><br>"
cat $1 | tr "\r" "\n" | grep "^No" | while read i ; do
   PLG=${i##*<}
   PLG=${PLG%>}      
   echo "<br>No info for <a href=\"${VW_URL}/${PLG}-plugin\">$PLG</a>"
done
