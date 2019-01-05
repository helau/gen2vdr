#!/bin/bash
equery size $1 | while read i ; do 
   sz=${i##*(}
   s="$(printf "%09d" ${sz%\)})"
   echo "$s $i" 
done | sort
			    