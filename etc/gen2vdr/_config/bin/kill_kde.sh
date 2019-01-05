#!/bin/bash
kill $(ps x|grep kdeinit|grep -v "grep"|cut -f 1 -d " ") $(pidof knotify4 kdm 2>/dev/null)
