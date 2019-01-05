grep "USE=" $1 | cut -f 2 -d '"' | while read i ; do 
   oldf=""
   t=${i%\**}
   f=${t##* }
   while [ "$f" != "$oldf" ] ; do
      echo "$f"
      oldf=$f
      t=${t%\**}
      f=${t##* }
   done
done
