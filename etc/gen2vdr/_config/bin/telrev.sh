#!/bin/bash
URL="http://www.dasoertliche.de/Controller?ciid=&district=&kgs=&plz=&zvo_ok=&form_name=search_inv&buc=&kgs=&buab=&zbuab=&page=5&context=4&action=43&ph=$1&image="
wget -O - "$URL" 2>/dev/null | tr -d "\t" |grep " na: " | cut -f 2 -d '"'
