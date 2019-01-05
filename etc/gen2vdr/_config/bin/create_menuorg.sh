wget http://www.vdr-wiki.de/wiki/index.php/Plugins_nach_Themen
awk '
BEGIN {
        MENU=""
}
/class="editsection"/ {
li = substr($0,10)
        MENU=substr(li, 1, index(li, "\"") - 1)
}
/-plugin#/ {
        li=substr($0, 1, length($0) - 4)
        i=index(li,">")
        while (i > 0) {
                li=substr(li, i + 1)
                i=index(li,">")
        }
        #print MENU":"li
        arm[MENU]=arm[MENU]":"li
}
END {
        printf("<?xml version=\"1.0\"?>\n")
        printf("<menus>\n")

        for(m in arm) {
                printf("<menu name=\"%s\">\n", m)
                ap=arm[m]
                split(ap, arp, ":")
                for(p in arp) {
                        #print m":"arp[p]
                        if(arp[p] != "") {;printf("<plugin name=\"%s\"/>\n", arp[p]);}
                }
                printf("</menu>\n")
        }

        printf("</menus>\n")
}
' Plugins_nach_Themen

