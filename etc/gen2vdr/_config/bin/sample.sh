#!/bin/bash
# manview.sh: Formats the source of a man page for viewing.

#  This is useful when writing man page source and you want to
#+ look at the intermediate results on the fly while working on it.

E_WRONGARGS=65

if [ -z "$1" ]
then
  echo "Usage: `basename $0` filename"
  exit $E_WRONGARGS
fi

groff -Tascii -man $1 | less
# From the man page for groff.

# If the man page includes tables and/or equations,
# then the above code will barf.
# The following line can handle such cases.
#
#   gtbl < "$1" | geqn -Tlatin1 | groff -Tlatin1 -mtty-char -man
#
#   Thanks, S.C.

exit 0

le A-2. mailformat: Formatting an e-mail message

#!/bin/bash
# mail-format.sh: Format e-mail messages.

# Gets rid of carets, tabs, also fold excessively long lines.

# =================================================================
#                 Standard Check for Script Argument(s)
ARGS=1
E_BADARGS=65
E_NOFILE=66

if [ $# -ne $ARGS ]  # Correct number of arguments passed to script?
then
  echo "Usage: `basename $0` filename"
  exit $E_BADARGS
fi

if [ -f "$1" ]       # Check if file exists.
then
    file_name=$1
else
    echo "File \"$1\" does not exist."
    exit $E_NOFILE
fi
# =================================================================

MAXWIDTH=70          # Width to fold long lines to.

#  Delete carets and tabs at beginning of lines,
#+ then fold lines to $MAXWIDTH characters.
sed '
s/^>//
s/^  *>//
s/^  *//
s/		*//
' $1 | fold -s --width=$MAXWIDTH
          # -s option to "fold" breaks lines at whitespace, if possible.

#  This script was inspired by an article in a well-known trade journal
#+ extolling a 164K Windows utility with similar functionality.
#
#  An nice set of text processing utilities and an efficient
#+ scripting language provide an alternative to bloated executables.

exit 0

le A-3. rn: A simple-minded file rename utility

script is a modification of Example 12-15.

#! /bin/bash
#
# Very simpleminded filename "rename" utility (based on "lowercase.sh").
#
#  The "ren" utility, by Vladimir Lanin (lanin@csd2.nyu.edu),
#+ does a much better job of this.


ARGS=2
E_BADARGS=65
ONE=1                     # For getting singular/plural right (see below).

if [ $# -ne "$ARGS" ]
then
  echo "Usage: `basename $0` old-pattern new-pattern"
  # As in "rn gif jpg", which renames all gif files in working directory to jpg.
  exit $E_BADARGS
fi

number=0                  # Keeps track of how many files actually renamed.


for filename in *$1*      #Traverse all matching files in directory.
do
   if [ -f "$filename" ]  # If finds match...
   then
     fname=`basename $filename`            # Strip off path.
     n=`echo $fname | sed -e "s/$1/$2/"`   # Substitute new for old in filename.
     mv $fname $n                          # Rename.
     let "number += 1"
   fi
done   

if [ "$number" -eq "$ONE" ]                # For correct grammar.
then
 echo "$number file renamed."
else 
 echo "$number files renamed."
fi 

exit 0


# Exercises:
# ---------
# What type of files will this not work on?
# How can this be fixed?
#
#  Rewrite this script to process all the files in a directory
#+ containing spaces in their names, and to rename them,
#+ substituting an underscore for each space.

le A-4. blank-rename: renames filenames containing blanks

is an even simpler-minded version of previous script.

#! /bin/bash
# blank-rename.sh
#
# Substitutes underscores for blanks in all the filenames in a directory.

ONE=1                     # For getting singular/plural right (see below).
number=0                  # Keeps track of how many files actually renamed.
FOUND=0                   # Successful return value.

for filename in *         #Traverse all files in directory.
do
     echo "$filename" | grep -q " "         #  Check whether filename
     if [ $? -eq $FOUND ]                   #+ contains space(s).
     then
       fname=$filename                      # Strip off path.
       n=`echo $fname | sed -e "s/ /_/g"`   # Substitute underscore for blank.
       mv "$fname" "$n"                     # Do the actual renaming.
       let "number += 1"
     fi
done   

if [ "$number" -eq "$ONE" ]                 # For correct grammar.
then
 echo "$number file renamed."
else 
 echo "$number files renamed."
fi 

exit 0

le A-5. encryptedpw: Uploading to an ftp site, using a locally encrypted password

#!/bin/bash

# Example "ex72.sh" modified to use encrypted password.

#  Note that this is still somewhat insecure,
#+ since the decrypted password is sent in the clear.
# Use something like "ssh" if this is a concern.

E_BADARGS=65

if [ -z "$1" ]
then
  echo "Usage: `basename $0` filename"
  exit $E_BADARGS
fi  

Username=bozo           # Change to suit.
pword=/home/bozo/secret/password_encrypted.file
# File containing encrypted password.

Filename=`basename $1`  # Strips pathname out of file name

Server="XXX"
Directory="YYY"         # Change above to actual server name & directory.


Password=`cruft <$pword`          # Decrypt password.
#  Uses the author's own "cruft" file encryption package,
#+ based on the classic "onetime pad" algorithm,
#+ and obtainable from:
#+ Primary-site:   ftp://metalab.unc.edu /pub/Linux/utils/file
#+                 cruft-0.2.tar.gz [16k]


ftp -n $Server <<End-Of-Session
user $Username $Password
binary
bell
cd $Directory
put $Filename
bye
End-Of-Session
# -n option to "ftp" disables auto-logon.
# "bell" rings 'bell' after each file transfer.

exit 0

le A-6. copy-cd: Copying a data CD

#!/bin/bash
# copy-cd.sh: copying a data CD

CDROM=/dev/cdrom                           # CD ROM device
OF=/home/bozo/projects/cdimage.iso         # output file
#       /xxxx/xxxxxxx/                     Change to suit your system.
BLOCKSIZE=2048
SPEED=2                                    # May use higher speed if supported.

echo; echo "Insert source CD, but do *not* mount it."
echo "Press ENTER when ready. "
read ready                                 # Wait for input, $ready not used.

echo; echo "Copying the source CD to $OF."
echo "This may take a while. Please be patient."

dd if=$CDROM of=$OF bs=$BLOCKSIZE          # Raw device copy.


echo; echo "Remove data CD."
echo "Insert blank CDR."
echo "Press ENTER when ready. "
read ready                                 # Wait for input, $ready not used.

echo "Copying $OF to CDR."

cdrecord -v -isosize speed=$SPEED dev=0,0 $OF
# Uses Joerg Schilling's "cdrecord" package (see its docs).
# http://www.fokus.gmd.de/nthp/employees/schilling/cdrecord.html


echo; echo "Done copying $OF to CDR on device $CDROM."

echo "Do you want to erase the image file (y/n)? "  # Probably a huge file.
read answer

case "$answer" in
[yY]) rm -f $OF
      echo "$OF erased."
      ;;
*)    echo "$OF not erased.";;
esac

echo

# Exercise:
# Change the above "case" statement to also accept "yes" and "Yes" as input.

exit 0

le A-7. Collatz series

#!/bin/bash
# collatz.sh

#  The notorious "hailstone" or Collatz series.
#  -------------------------------------------
#  1) Get the integer "seed" from the command line.
#  2) NUMBER <--- seed
#  3) Print NUMBER.
#  4)  If NUMBER is even, divide by 2, or
#  5)+ if odd, multiply by 3 and add 1.
#  6) NUMBER <--- result 
#  7) Loop back to step 3 (for specified number of iterations).
#
#  The theory is that every sequence,
#+ no matter how large the initial value,
#+ eventually settles down to repeating "4,2,1..." cycles,
#+ even after fluctuating through a wide range of values.
#
#  This is an instance of an "iterate",
#+ an operation that feeds its output back into the input.
#  Sometimes the result is a "chaotic" series.


MAX_ITERATIONS=200
# For large seed numbers (>32000), increase MAX_ITERATIONS.

h=${1:-$$}                      #  Seed
                                #  Use $PID as seed,
                                #+ if not specified as command-line arg.

echo
echo "C($h) --- $MAX_ITERATIONS Iterations"
echo

for ((i=1; i<=MAX_ITERATIONS; i++))
do

echo -n "$h	"
#          ^^^^^
#           tab

  let "remainder = h % 2"
  if [ "$remainder" -eq 0 ]   # Even?
  then
    let "h /= 2"              # Divide by 2.
  else
    let "h = h*3 + 1"         # Multiply by 3 and add 1.
  fi


COLUMNS=10                    # Output 10 values per line.
let "line_break = i % $COLUMNS"
if [ "$line_break" -eq 0 ]
then
  echo
fi  

done

echo

#  For more information on this mathematical function,
#+ see "Computers, Pattern, Chaos, and Beauty", by Pickover, p. 185 ff.,
#+ as listed in the bibliography.

exit 0

le A-8. days-between: Calculate number of days between two dates

#!/bin/bash
# days-between.sh:    Number of days between two dates.
# Usage: ./days-between.sh [M]M/[D]D/YYYY [M]M/[D]D/YYYY

ARGS=2                # Two command line parameters expected.
E_PARAM_ERR=65        # Param error.

REFYR=1600            # Reference year.
CENTURY=100
DIY=365
ADJ_DIY=367           # Adjusted for leap year + fraction.
MIY=12
DIM=31
LEAPCYCLE=4

MAXRETVAL=256         # Largest permissable
                      # positive return value from a function.

diff=		      # Declare global variable for date difference.
value=                # Declare global variable for absolute value.
day=                  # Declare globals for day, month, year.
month=
year=


Param_Error ()        # Command line parameters wrong.
{
  echo "Usage: `basename $0` [M]M/[D]D/YYYY [M]M/[D]D/YYYY"
  echo "       (date must be after 1/3/1600)"
  exit $E_PARAM_ERR
}  


Parse_Date ()                 # Parse date from command line params.
{
  month=${1%%/**}
  dm=${1%/**}                 # Day and month.
  day=${dm#*/}
  let "year = `basename $1`"  # Not a filename, but works just the same.
}  


check_date ()                 # Checks for invalid date(s) passed.
{
  [ "$day" -gt "$DIM" ] || [ "$month" -gt "$MIY" ] || [ "$year" -lt "$REFYR" ] && Param_Error
  # Exit script on bad value(s).
  # Uses "or-list / and-list".
  #
  # Exercise: Implement more rigorous date checking.
}


strip_leading_zero () # Better to strip possible leading zero(s)
{                     # from day and/or month
  val=${1#0}          # since otherwise Bash will interpret them
  return $val         # as octal values (POSIX.2, sect 2.9.2.1).
}


day_index ()          # Gauss' Formula:
{                     # Days from Jan. 3, 1600 to date passed as param.

  day=$1
  month=$2
  year=$3

  let "month = $month - 2"
  if [ "$month" -le 0 ]
  then
    let "month += 12"
    let "year -= 1"
  fi  

  let "year -= $REFYR"
  let "indexyr = $year / $CENTURY"


  let "Days = $DIY*$year + $year/$LEAPCYCLE - $indexyr + $indexyr/$LEAPCYCLE + $ADJ_DIY*$month/$MIY + $day - $DIM"
  # For an in-depth explanation of this algorithm, see
  # http://home.t-online.de/home/berndt.schwerdtfeger/cal.htm


  if [ "$Days" -gt "$MAXRETVAL" ]  # If greater than 256,
  then                             # then change to negative value
    let "dindex = 0 - $Days"       # which can be returned from function.
  else let "dindex = $Days"
  fi

  return $dindex

}  


calculate_difference ()            # Difference between to day indices.
{
  let "diff = $1 - $2"             # Global variable.
}  


abs ()                             # Absolute value
{                                  # Uses global "value" variable.
  if [ "$1" -lt 0 ]                # If negative
  then                             # then
    let "value = 0 - $1"           # change sign,
  else                             # else
    let "value = $1"               # leave it alone.
  fi
}



if [ $# -ne "$ARGS" ]              # Require two command line params.
then
  Param_Error
fi  

Parse_Date $1
check_date $day $month $year      # See if valid date.

strip_leading_zero $day           # Remove any leading zeroes
day=$?                            # on day and/or month.
strip_leading_zero $month
month=$?

day_index $day $month $year
date1=$?

abs $date1                         # Make sure it's positive
date1=$value                       # by getting absolute value.

Parse_Date $2
check_date $day $month $year

strip_leading_zero $day
day=$?
strip_leading_zero $month
month=$?

day_index $day $month $year
date2=$?

abs $date2                         # Make sure it's positive.
date2=$value

calculate_difference $date1 $date2

abs $diff                          # Make sure it's positive.
diff=$value

echo $diff

exit 0
# Compare this script with the implementation of Gauss' Formula in C at
# http://buschencrew.hypermart.net/software/datedif

le A-9. Make a "dictionary"

#!/bin/bash
# makedict.sh  [make dictionary]

# Modification of /usr/sbin/mkdict script.
# Original script copyright 1993, by Alec Muffett.
#
#  This modified script included in this document in a manner
#+ consistent with the "LICENSE" document of the "Crack" package
#+ that the original script is a part of.

#  This script processes text files to produce a sorted list
#+ of words found in the files.
#  This may be useful for compiling dictionaries
#+ and for lexicographic research.


E_BADARGS=65

if [ ! -r "$1" ]                     #  Need at least one
then                                 #+ valid file argument.
  echo "Usage: $0 files-to-process"
  exit $E_BADARGS
fi  


# SORT="sort"                        #  No longer necessary to define options
                                     #+ to sort. Changed from original script.

cat $* |                             # Contents of specified files to stdout.
        tr A-Z a-z |                 # Convert to uppercase.
        tr ' ' '\012' |              # New: change spaces to newlines.
#       tr -cd '\012[a-z][0-9]' |    #  Get rid of everything non-alphanumeric
                                     #+ (original script).
        tr -c '\012a-z'  '\012' |    #  Rather than deleting
                                     #+ now change non-alpha to newlines.
        sort |                       # $SORT options unnecessary now.
        uniq |                       # Remove duplicates.
        grep -v '^#' |               # Delete lines beginning with a hashmark.
        grep -v '^$'                 # Delete blank lines.

exit 0	

le A-10. Soundex conversion

#!/bin/bash
# soundex.sh: Calculate "soundex" code for names

# =======================================================
#        Soundex script
#              by
#         Mendel Cooper
#     thegrendel@theriver.com
#       23 January, 2002
#
#   Placed in the Public Domain.
#
# A slightly different version of this script appeared in
#+ Ed Schaefer's July, 2002 "Shell Corner" column
#+ in "Unix Review" on-line,
#+ http://www.unixreview.com/documents/uni1026336632258/
# =======================================================


ARGCOUNT=1                     # Need name as argument.
E_WRONGARGS=70

if [ $# -ne "$ARGCOUNT" ]
then
  echo "Usage: `basename $0` name"
  exit $E_WRONGARGS
fi  


assign_value ()                #  Assigns numerical value
{                              #+ to letters of name.

  val1=bfpv                    # 'b,f,p,v' = 1
  val2=cgjkqsxz                # 'c,g,j,k,q,s,x,z' = 2
  val3=dt                      #  etc.
  val4=l
  val5=mn
  val6=r

# Exceptionally clever use of 'tr' follows.
# Try to figure out what is going on here.

value=$( echo "$1" \
| tr -d wh \
| tr $val1 1 | tr $val2 2 | tr $val3 3 \
| tr $val4 4 | tr $val5 5 | tr $val6 6 \
| tr -s 123456 \
| tr -d aeiouy )

# Assign letter values.
# Remove duplicate numbers, except when separated by vowels.
# Ignore vowels, except as separators, so delete them last.
# Ignore 'w' and 'h', even as separators, so delete them first.
#
# The above command substitution lays more pipe than a plumber <g>.

}  


input_name="$1"
echo
echo "Name = $input_name"


# Change all characters of name input to lowercase.
# ------------------------------------------------
name=$( echo $input_name | tr A-Z a-z )
# ------------------------------------------------
# Just in case argument to script is mixed case.


# Prefix of soundex code: first letter of name.
# --------------------------------------------


char_pos=0                     # Initialize character position. 
prefix0=${name:$char_pos:1}
prefix=`echo $prefix0 | tr a-z A-Z`
                               # Uppercase 1st letter of soundex.

let "char_pos += 1"            # Bump character position to 2nd letter of name.
name1=${name:$char_pos}


# ++++++++++++++++++++++++++ Exception Patch +++++++++++++++++++++++++++++++++
#  Now, we run both the input name and the name shifted one char to the right
#+ through the value-assigning function.
#  If we get the same value out, that means that the first two characters
#+ of the name have the same value assigned, and that one should cancel.
#  However, we also need to test whether the first letter of the name
#+ is a vowel or 'w' or 'h', because otherwise this would bollix things up.

char1=`echo $prefix | tr A-Z a-z`    # First letter of name, lowercased.

assign_value $name
s1=$value
assign_value $name1
s2=$value
assign_value $char1
s3=$value
s3=9$s3                              #  If first letter of name is a vowel
                                     #+ or 'w' or 'h',
                                     #+ then its "value" will be null (unset).
				     #+ Therefore, set it to 9, an otherwise
				     #+ unused value, which can be tested for.


if [[ "$s1" -ne "$s2" || "$s3" -eq 9 ]]
then
  suffix=$s2
else  
  suffix=${s2:$char_pos}
fi  
# ++++++++++++++++++++++ end Exception Patch +++++++++++++++++++++++++++++++++


padding=000                    # Use at most 3 zeroes to pad.


soun=$prefix$suffix$padding    # Pad with zeroes.

MAXLEN=4                       # Truncate to maximum of 4 chars.
soundex=${soun:0:$MAXLEN}

echo "Soundex = $soundex"

echo

#  The soundex code is a method of indexing and classifying names
#+ by grouping together the ones that sound alike.
#  The soundex code for a given name is the first letter of the name,
#+ followed by a calculated three-number code.
#  Similar sounding names should have almost the same soundex codes.

#   Examples:
#   Smith and Smythe both have a "S-530" soundex.
#   Harrison = H-625
#   Hargison = H-622
#   Harriman = H-655

#  This works out fairly well in practice, but there are numerous anomalies.
#
#
#  The U.S. Census and certain other governmental agencies use soundex,
#  as do genealogical researchers.
#
#  For more information,
#+ see the "National Archives and Records Administration home page",
#+ http://www.nara.gov/genealogy/soundex/soundex.html



# Exercise:
# --------
# Simplify the "Exception Patch" section of this script.

exit 0

le A-11. "Game of Life"

#!/bin/bash
# life.sh: "Life in the Slow Lane"

# ##################################################################### #
# This is the Bash script version of John Conway's "Game of Life".      #
# "Life" is a simple implementation of cellular automata.               #
# --------------------------------------------------------------------- #
# On a rectangular grid, let each "cell" be either "living" or "dead".  #
# Designate a living cell with a dot, and a dead one with a blank space.#
#  Begin with an arbitrarily drawn dot-and-blank grid,                  #
#+ and let this be the starting generation, "generation 0".             #
# Determine each successive generation by the following rules:          #
# 1) Each cell has 8 neighbors, the adjoining cells                     #
#+   left, right, top, bottom, and the 4 diagonals.                     #
#                       123                                             #
#                       4*5                                             #
#                       678                                             #
#                                                                       #
# 2) A living cell with either 2 or 3 living neighbors remains alive.   #
# 3) A dead cell with 3 living neighbors becomes alive (a "birth").     #
SURVIVE=2                                                               #
BIRTH=3                                                                 #
# 4) All other cases result in dead cells.                              #
# ##################################################################### #


startfile=gen0   # Read the starting generation from the file "gen0".
                 # Default, if no other file specified when invoking script.
                 #
if [ -n "$1" ]   # Specify another "generation 0" file.
then
  if [ -e "$1" ] # Check for existence.
  then
    startfile="$1"
  fi  
fi  


ALIVE1=.
DEAD1=_
                 # Represent living and "dead" cells in the start-up file.

#  This script uses a 10 x 10 grid (may be increased,
#+ but a large grid will will cause very slow execution).
ROWS=10
COLS=10

GENERATIONS=10          #  How many generations to cycle through.
                        #  Adjust this upwards,
                        #+ if you have time on your hands.

NONE_ALIVE=80           #  Exit status on premature bailout,
                        #+ if no cells left alive.
TRUE=0
FALSE=1
ALIVE=0
DEAD=1

avar=                   #  Global; holds current generation.
generation=0            # Initialize generation count.

# =================================================================


let "cells = $ROWS * $COLS"
                        # How many cells.

declare -a initial      # Arrays containing "cells".
declare -a current

display ()
{

alive=0                 # How many cells "alive".
                        # Initially zero.

declare -a arr
arr=( `echo "$1"` )     # Convert passed arg to array.

element_count=${#arr[*]}

local i
local rowcheck

for ((i=0; i<$element_count; i++))
do

  # Insert newline at end of each row.
  let "rowcheck = $i % ROWS"
  if [ "$rowcheck" -eq 0 ]
  then
    echo                # Newline.
    echo -n "      "    # Indent.
  fi  

  cell=${arr[i]}

  if [ "$cell" = . ]
  then
    let "alive += 1"
  fi  

  echo -n "$cell" | sed -e 's/_/ /g'
  # Print out array and change underscores to spaces.
done  

return

}

IsValid ()                            # Test whether cell coordinate valid.
{

  if [ -z "$1"  -o -z "$2" ]          # Mandatory arguments missing?
  then
    return $FALSE
  fi

local row
local lower_limit=0                   # Disallow negative coordinate.
local upper_limit
local left
local right

let "upper_limit = $ROWS * $COLS - 1" # Total number of cells.


if [ "$1" -lt "$lower_limit" -o "$1" -gt "$upper_limit" ]
then
  return $FALSE                       # Out of array bounds.
fi  

row=$2
let "left = $row * $ROWS"             # Left limit.
let "right = $left + $COLS - 1"       # Right limit.

if [ "$1" -lt "$left" -o "$1" -gt "$right" ]
then
  return $FALSE                       # Beyond row boundary.
fi  

return $TRUE                          # Valid coordinate.

}  


IsAlive ()              # Test whether cell is alive.
                        # Takes array, cell number, state of cell as arguments.
{
  GetCount "$1" $2      # Get alive cell count in neighborhood.
  local nhbd=$?


  if [ "$nhbd" -eq "$BIRTH" ]  # Alive in any case.
  then
    return $ALIVE
  fi

  if [ "$3" = "." -a "$nhbd" -eq "$SURVIVE" ]
  then                  # Alive only if previously alive.
    return $ALIVE
  fi  

  return $DEAD          # Default.

}  


GetCount ()             # Count live cells in passed cell's neighborhood.
                        # Two arguments needed:
			# $1) variable holding array
			# $2) cell number
{
  local cell_number=$2
  local array
  local top
  local center
  local bottom
  local r
  local row
  local i
  local t_top
  local t_cen
  local t_bot
  local count=0
  local ROW_NHBD=3

  array=( `echo "$1"` )

  let "top = $cell_number - $COLS - 1"    # Set up cell neighborhood.
  let "center = $cell_number - 1"
  let "bottom = $cell_number + $COLS - 1"
  let "r = $cell_number / $ROWS"

  for ((i=0; i<$ROW_NHBD; i++))           # Traverse from left to right. 
  do
    let "t_top = $top + $i"
    let "t_cen = $center + $i"
    let "t_bot = $bottom + $i"


    let "row = $r"                        # Count center row of neighborhood.
    IsValid $t_cen $row                   # Valid cell position?
    if [ $? -eq "$TRUE" ]
    then
      if [ ${array[$t_cen]} = "$ALIVE1" ] # Is it alive?
      then                                # Yes?
        let "count += 1"                  # Increment count.
      fi	
    fi  

    let "row = $r - 1"                    # Count top row.          
    IsValid $t_top $row
    if [ $? -eq "$TRUE" ]
    then
      if [ ${array[$t_top]} = "$ALIVE1" ] 
      then
        let "count += 1"
      fi	
    fi  

    let "row = $r + 1"                    # Count bottom row.
    IsValid $t_bot $row
    if [ $? -eq "$TRUE" ]
    then
      if [ ${array[$t_bot]} = "$ALIVE1" ] 
      then
        let "count += 1"
      fi	
    fi  

  done  


  if [ ${array[$cell_number]} = "$ALIVE1" ]
  then
    let "count -= 1"        #  Make sure value of tested cell itself
  fi                        #+ is not counted.


  return $count
  
}

next_gen ()               # Update generation array.
{

local array
local i=0

array=( `echo "$1"` )     # Convert passed arg to array.

while [ "$i" -lt "$cells" ]
do
  IsAlive "$1" $i ${array[$i]}   # Is cell alive?
  if [ $? -eq "$ALIVE" ]
  then                           #  If alive, then
    array[$i]=.                  #+ represent the cell as a period.
  else  
    array[$i]="_"                #  Otherwise underscore
   fi                            #+ (which will later be converted to space).  
  let "i += 1" 
done   


# let "generation += 1"   # Increment generation count.

# Set variable to pass as parameter to "display" function.
avar=`echo ${array[@]}`   # Convert array back to string variable.
display "$avar"           # Display it.
echo; echo
echo "Generation $generation -- $alive alive"

if [ "$alive" -eq 0 ]
then
  echo
  echo "Premature exit: no more cells alive!"
  exit $NONE_ALIVE        #  No point in continuing
fi                        #+ if no live cells.

}


# =========================================================

# main ()

# Load initial array with contents of startup file.
initial=( `cat "$startfile" | sed -e '/#/d' | tr -d '\n' |\
sed -e 's/\./\. /g' -e 's/_/_ /g'` )
# Delete lines containing '#' comment character.
# Remove linefeeds and insert space between elements.

clear          # Clear screen.

echo #         Title
echo "======================="
echo "    $GENERATIONS generations"
echo "           of"
echo "\"Life in the Slow Lane\""
echo "======================="


# -------- Display first generation. --------
Gen0=`echo ${initial[@]}`
display "$Gen0"           # Display only.
echo; echo
echo "Generation $generation -- $alive alive"
# -------------------------------------------


let "generation += 1"     # Increment generation count.
echo

# ------- Display second generation. -------
Cur=`echo ${initial[@]}`
next_gen "$Cur"          # Update & display.
# ------------------------------------------

let "generation += 1"     # Increment generation count.

# ------ Main loop for displaying subsequent generations ------
while [ "$generation" -le "$GENERATIONS" ]
do
  Cur="$avar"
  next_gen "$Cur"
  let "generation += 1"
done
# ==============================================================

echo

exit 0

# --------------------------------------------------------------
# The grid in this script has a "boundary problem".
# The the top, bottom, and sides border on a void of dead cells.
# Exercise: Change the script to have the grid wrap around,
# +         so that the left and right sides will "touch",      
# +         as will the top and bottom.

le A-12. Data file for "Game of Life"

# This is an example "generation 0" start-up file for "life.sh".
# --------------------------------------------------------------
#  The "gen0" file is a 10 x 10 grid using a period (.) for live cells,
#+ and an underscore (_) for dead ones. We cannot simply use spaces
#+ for dead cells in this file because of a peculiarity in Bash arrays.
#  [Exercise for the reader: explain this.]
#
# Lines beginning with a '#' are comments, and the script ignores them.
__.__..___
___._.____
____.___..
_._______.
____._____
..__...___
____._____
___...____
__.._..___
_..___..__



ollowing two scripts are by Mark Moraes of the University of Toronto. See the enclosed file "Moraes-COPYRIGHT" for permissions and restrictions.

le A-13. behead: Removing mail and news message headers

#!/bin/bash
# Strips off the header from a mail/News message i.e. till the first
# empty line
# Mark Moraes, University of Toronto

# ==> These comments added by author of this document.

if [ $# -eq 0 ]; then
# ==> If no command line args present, then works on file redirected to stdin.
	sed -e '1,/^$/d' -e '/^[ 	]*$/d'
	# --> Delete empty lines and all lines until 
	# --> first one beginning with white space.
else
# ==> If command line args present, then work on files named.
	for i do
		sed -e '1,/^$/d' -e '/^[ 	]*$/d' $i
		# --> Ditto, as above.
	done
fi

# ==> Exercise: Add error checking and other options.
# ==>
# ==> Note that the small sed script repeats, except for the arg passed.
# ==> Does it make sense to embed it in a function? Why or why not?

le A-14. ftpget: Downloading files via ftp

#!/bin/bash 
# $Id: ftpget,v 1.2 91/05/07 21:15:43 moraes Exp $ 
# Script to perform batch anonymous ftp. Essentially converts a list of
# of command line arguments into input to ftp.
# Simple, and quick - written as a companion to ftplist 
# -h specifies the remote host (default prep.ai.mit.edu) 
# -d specifies the remote directory to cd to - you can provide a sequence 
# of -d options - they will be cd'ed to in turn. If the paths are relative, 
# make sure you get the sequence right. Be careful with relative paths - 
# there are far too many symlinks nowadays.  
# (default is the ftp login directory)
# -v turns on the verbose option of ftp, and shows all responses from the 
# ftp server.  
# -f remotefile[:localfile] gets the remote file into localfile 
# -m pattern does an mget with the specified pattern. Remember to quote 
# shell characters.  
# -c does a local cd to the specified directory
# For example, 
# 	ftpget -h expo.lcs.mit.edu -d contrib -f xplaces.shar:xplaces.sh \
#		-d ../pub/R3/fixes -c ~/fixes -m 'fix*' 
# will get xplaces.shar from ~ftp/contrib on expo.lcs.mit.edu, and put it in
# xplaces.sh in the current working directory, and get all fixes from
# ~ftp/pub/R3/fixes and put them in the ~/fixes directory. 
# Obviously, the sequence of the options is important, since the equivalent
# commands are executed by ftp in corresponding order
#
# Mark Moraes (moraes@csri.toronto.edu), Feb 1, 1989 
# ==> Angle brackets changed to parens, so Docbook won't get indigestion.
#


# ==> These comments added by author of this document.

# PATH=/local/bin:/usr/ucb:/usr/bin:/bin
# export PATH
# ==> Above 2 lines from original script probably superfluous.

TMPFILE=/tmp/ftp.$$
# ==> Creates temp file, using process id of script ($$)
# ==> to construct filename.

SITE=`domainname`.toronto.edu
# ==> 'domainname' similar to 'hostname'
# ==> May rewrite this to parameterize this for general use.

usage="Usage: $0 [-h remotehost] [-d remotedirectory]... [-f remfile:localfile]... \
		[-c localdirectory] [-m filepattern] [-v]"
ftpflags="-i -n"
verbflag=
set -f 		# So we can use globbing in -m
set x `getopt vh:d:c:m:f: $*`
if [ $? != 0 ]; then
	echo $usage
	exit 65
fi
shift
trap 'rm -f ${TMPFILE} ; exit' 0 1 2 3 15
echo "user anonymous ${USER-gnu}@${SITE} > ${TMPFILE}"
# ==> Added quotes (recommended in complex echoes).
echo binary >> ${TMPFILE}
for i in $*   # ==> Parse command line args.
do
	case $i in
	-v) verbflag=-v; echo hash >> ${TMPFILE}; shift;;
	-h) remhost=$2; shift 2;;
	-d) echo cd $2 >> ${TMPFILE}; 
	    if [ x${verbflag} != x ]; then
	        echo pwd >> ${TMPFILE};
	    fi;
	    shift 2;;
	-c) echo lcd $2 >> ${TMPFILE}; shift 2;;
	-m) echo mget "$2" >> ${TMPFILE}; shift 2;;
	-f) f1=`expr "$2" : "\([^:]*\).*"`; f2=`expr "$2" : "[^:]*:\(.*\)"`;
	    echo get ${f1} ${f2} >> ${TMPFILE}; shift 2;;
	--) shift; break;;
	esac
done
if [ $# -ne 0 ]; then
	echo $usage
	exit 65   # ==> Changed from "exit 2" to conform with standard.
fi
if [ x${verbflag} != x ]; then
	ftpflags="${ftpflags} -v"
fi
if [ x${remhost} = x ]; then
	remhost=prep.ai.mit.edu
	# ==> Rewrite to match your favorite ftp site.
fi
echo quit >> ${TMPFILE}
# ==> All commands saved in tempfile.

ftp ${ftpflags} ${remhost} < ${TMPFILE}
# ==> Now, tempfile batch processed by ftp.

rm -f ${TMPFILE}
# ==> Finally, tempfile deleted (you may wish to copy it to a logfile).


# ==> Exercises:
# ==> ---------
# ==> 1) Add error checking.
# ==> 2) Add bells & whistles.



 Sawicki contributed the following script, which makes very clever use of the parameter substitution operators discussed in Section 9.3.

le A-15. password: Generating random 8-character passwords

#!/bin/bash
# May need to be invoked with  #!/bin/bash2  on older machines.
#
# Random password generator for bash 2.x by Antek Sawicki <tenox@tenox.tc>,
# who generously gave permission to the document author to use it here.
#
# ==> Comments added by document author ==>


MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="8"
# ==> May change 'LENGTH' for longer password, of course.


while [ "${n:=1}" -le "$LENGTH" ]
# ==> Recall that := is "default substitution" operator.
# ==> So, if 'n' has not been initialized, set it to 1.
do
	PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
	# ==> Very clever, but tricky.

	# ==> Starting from the innermost nesting...
	# ==> ${#MATRIX} returns length of array MATRIX.

	# ==> $RANDOM%${#MATRIX} returns random number between 1
	# ==> and length of MATRIX - 1.

	# ==> ${MATRIX:$(($RANDOM%${#MATRIX})):1}
	# ==> returns expansion of MATRIX at random position, by length 1. 
	# ==> See {var:pos:len} parameter substitution in Section 3.3.1
	# ==> and following examples.

	# ==> PASS=... simply pastes this result onto previous PASS (concatenation).

	# ==> To visualize this more clearly, uncomment the following line
	# ==>             echo "$PASS"
	# ==> to see PASS being built up,
	# ==> one character at a time, each iteration of the loop.

	let n+=1
	# ==> Increment 'n' for next pass.
done

echo "$PASS"      # ==> Or, redirect to file, as desired.

exit 0



 R. Van Zandt contributed this script, which uses named pipes and, in his words, "really exercises quoting and escaping".

le A-16. fifo: Making daily backups, using named pipes

#!/bin/bash
# ==> Script by James R. Van Zandt, and used here with his permission.

# ==> Comments added by author of this document.

  
  HERE=`uname -n`    # ==> hostname
  THERE=bilbo
  echo "starting remote backup to $THERE at `date +%r`"
  # ==> `date +%r` returns time in 12-hour format, i.e. "08:08:34 PM".
  
  # make sure /pipe really is a pipe and not a plain file
  rm -rf /pipe
  mkfifo /pipe       # ==> Create a "named pipe", named "/pipe".
  
  # ==> 'su xyz' runs commands as user "xyz".
  # ==> 'ssh' invokes secure shell (remote login client).
  su xyz -c "ssh $THERE \"cat >/home/xyz/backup/${HERE}-daily.tar.gz\" < /pipe"&
  cd /
  tar -czf - bin boot dev etc home info lib man root sbin share usr var >/pipe
  # ==> Uses named pipe, /pipe, to communicate between processes:
  # ==> 'tar/gzip' writes to /pipe and 'ssh' reads from /pipe.

  # ==> The end result is this backs up the main directories, from / on down.

  # ==> What are the advantages of a "named pipe" in this situation,
  # ==> as opposed to an "anonymous pipe", with |?
  # ==> Will an anonymous pipe even work here?


  exit 0



ane Chazelas contributed the following script to demonstrate that generating prime numbers does not require arrays.

le A-17. Generating prime numbers using the modulo operator

#!/bin/bash
# primes.sh: Generate prime numbers, without using arrays.
# Script contributed by Stephane Chazelas.

#  This does *not* use the classic "Sieve of Eratosthenes" algorithm,
#+ but instead uses the more intuitive method of testing each candidate number
#+ for factors (divisors), using the "%" modulo operator.


LIMIT=1000                    # Primes 2 - 1000

Primes()
{
 (( n = $1 + 1 ))             # Bump to next integer.
 shift                        # Next parameter in list.
#  echo "_n=$n i=$i_"
 
 if (( n == LIMIT ))
 then echo $*
 return
 fi

 for i; do                    # "i" gets set to "@", previous values of $n.
#   echo "-n=$n i=$i-"
   (( i * i > n )) && break   # Optimization.
   (( n % i )) && continue    # Sift out non-primes using modulo operator.
   Primes $n $@               # Recursion inside loop.
   return
   done

   Primes $n $@ $n            # Recursion outside loop.
                              # Successively accumulate positional parameters.
                              # "$@" is the accumulating list of primes.
}

Primes 1

exit 0

# Uncomment lines 17 and 25 to help figure out what is going on.

# Compare the speed of this algorithm for generating primes
# with the Sieve of Eratosthenes (ex68.sh).

# Exercise: Rewrite this script without recursion, for faster execution.



 Sanfeliu gave permission to use his elegant tree script.

le A-18. tree: Displaying a directory tree

#!/bin/bash
#         @(#) tree      1.1  30/11/95       by Jordi Sanfeliu
#                                         email: mikaku@arrakis.es
#
#         Initial version:  1.0  30/11/95
#         Next version   :  1.1  24/02/97   Now, with symbolic links
#         Patch by       :  Ian Kjos, to support unsearchable dirs
#                           email: beth13@mail.utexas.edu
#
#         Tree is a tool for view the directory tree (obvious :-) )
#

# ==> 'Tree' script used here with the permission of its author, Jordi Sanfeliu.
# ==> Comments added by the author of this document.
# ==> Argument quoting added.


search () {
   for dir in `echo *`
   # ==> `echo *` lists all the files in current working directory, without line breaks.
   # ==> Similar effect to     for dir in *
   # ==> but "dir in `echo *`" will not handle filenames with blanks.
   do
      if [ -d "$dir" ] ; then   # ==> If it is a directory (-d)...
         zz=0   # ==> Temp variable, keeping track of directory level.
         while [ $zz != $deep ]    # Keep track of inner nested loop.
         do
            echo -n "|   "    # ==> Display vertical connector symbol,
	                      # ==> with 2 spaces & no line feed in order to indent.
            zz=`expr $zz + 1` # ==> Increment zz.
         done
         if [ -L "$dir" ] ; then   # ==> If directory is a symbolic link...
            echo "+---$dir" `ls -l $dir | sed 's/^.*'$dir' //'`
	    # ==> Display horiz. connector and list directory name, but...
	    # ==> delete date/time part of long listing.
         else
            echo "+---$dir"      # ==> Display horizontal connector symbol...
                                 # ==> and print directory name.
            if cd "$dir" ; then  # ==> If can move to subdirectory...
               deep=`expr $deep + 1`   # ==> Increment depth.
               search     # with recursivity ;-)
	                  # ==> Function calls itself.
               numdirs=`expr $numdirs + 1`   # ==> Increment directory count.
            fi
         fi
      fi
   done
   cd ..   # ==> Up one directory level.
   if [ "$deep" ] ; then  # ==> If depth = 0 (returns TRUE)...
      swfi=1              # ==> set flag showing that search is done.
   fi
   deep=`expr $deep - 1`  # ==> Decrement depth.
}

# - Main -
if [ $# = 0 ] ; then
   cd `pwd`    # ==> No args to script, then use current working directory.
else
   cd $1       # ==> Otherwise, move to indicated directory.
fi
echo "Initial directory = `pwd`"
swfi=0      # ==> Search finished flag.
deep=0      # ==> Depth of listing.
numdirs=0
zz=0

while [ "$swfi" != 1 ]   # While flag not set...
do
   search   # ==> Call function after initializing variables.
done
echo "Total directories = $numdirs"

exit 0
# ==> Challenge: try to figure out exactly how this script works.

Friedman gave permission to use his string function script, which essentially reproduces some of the C-library string manipulation functions.

le A-19. string functions: C-like string functions

#!/bin/bash

# string.bash --- bash emulation of string(3) library routines
# Author: Noah Friedman <friedman@prep.ai.mit.edu>
# ==>     Used with his kind permission in this document.
# Created: 1992-07-01
# Last modified: 1993-09-29
# Public domain

# Conversion to bash v2 syntax done by Chet Ramey

# Commentary:
# Code:

#:docstring strcat:
# Usage: strcat s1 s2
#
# Strcat appends the value of variable s2 to variable s1. 
#
# Example:
#    a="foo"
#    b="bar"
#    strcat a b
#    echo $a
#    => foobar
#
#:end docstring:

###;;;autoload   ==> Autoloading of function commented out.
function strcat ()
{
    local s1_val s2_val

    s1_val=${!1}                        # indirect variable expansion
    s2_val=${!2}
    eval "$1"=\'"${s1_val}${s2_val}"\'
    # ==> eval $1='${s1_val}${s2_val}' avoids problems,
    # ==> if one of the variables contains a single quote.
}

#:docstring strncat:
# Usage: strncat s1 s2 $n
# 
# Line strcat, but strncat appends a maximum of n characters from the value
# of variable s2.  It copies fewer if the value of variabl s2 is shorter
# than n characters.  Echoes result on stdout.
#
# Example:
#    a=foo
#    b=barbaz
#    strncat a b 3
#    echo $a
#    => foobar
#
#:end docstring:

###;;;autoload
function strncat ()
{
    local s1="$1"
    local s2="$2"
    local -i n="$3"
    local s1_val s2_val

    s1_val=${!s1}                       # ==> indirect variable expansion
    s2_val=${!s2}

    if [ ${#s2_val} -gt ${n} ]; then
       s2_val=${s2_val:0:$n}            # ==> substring extraction
    fi

    eval "$s1"=\'"${s1_val}${s2_val}"\'
    # ==> eval $1='${s1_val}${s2_val}' avoids problems,
    # ==> if one of the variables contains a single quote.
}

#:docstring strcmp:
# Usage: strcmp $s1 $s2
#
# Strcmp compares its arguments and returns an integer less than, equal to,
# or greater than zero, depending on whether string s1 is lexicographically
# less than, equal to, or greater than string s2.
#:end docstring:

###;;;autoload
function strcmp ()
{
    [ "$1" = "$2" ] && return 0

    [ "${1}" '<' "${2}" ] > /dev/null && return -1

    return 1
}

#:docstring strncmp:
# Usage: strncmp $s1 $s2 $n
# 
# Like strcmp, but makes the comparison by examining a maximum of n
# characters (n less than or equal to zero yields equality).
#:end docstring:

###;;;autoload
function strncmp ()
{
    if [ -z "${3}" -o "${3}" -le "0" ]; then
       return 0
    fi
   
    if [ ${3} -ge ${#1} -a ${3} -ge ${#2} ]; then
       strcmp "$1" "$2"
       return $?
    else
       s1=${1:0:$3}
       s2=${2:0:$3}
       strcmp $s1 $s2
       return $?
    fi
}

#:docstring strlen:
# Usage: strlen s
#
# Strlen returns the number of characters in string literal s.
#:end docstring:

###;;;autoload
function strlen ()
{
    eval echo "\${#${1}}"
    # ==> Returns the length of the value of the variable
    # ==> whose name is passed as an argument.
}

#:docstring strspn:
# Usage: strspn $s1 $s2
# 
# Strspn returns the length of the maximum initial segment of string s1,
# which consists entirely of characters from string s2.
#:end docstring:

###;;;autoload
function strspn ()
{
    # Unsetting IFS allows whitespace to be handled as normal chars. 
    local IFS=
    local result="${1%%[!${2}]*}"
 
    echo ${#result}
}

#:docstring strcspn:
# Usage: strcspn $s1 $s2
#
# Strcspn returns the length of the maximum initial segment of string s1,
# which consists entirely of characters not from string s2.
#:end docstring:

###;;;autoload
function strcspn ()
{
    # Unsetting IFS allows whitspace to be handled as normal chars. 
    local IFS=
    local result="${1%%[${2}]*}"
 
    echo ${#result}
}

#:docstring strstr:
# Usage: strstr s1 s2
# 
# Strstr echoes a substring starting at the first occurrence of string s2 in
# string s1, or nothing if s2 does not occur in the string.  If s2 points to
# a string of zero length, strstr echoes s1.
#:end docstring:

###;;;autoload
function strstr ()
{
    # if s2 points to a string of zero length, strstr echoes s1
    [ ${#2} -eq 0 ] && { echo "$1" ; return 0; }

    # strstr echoes nothing if s2 does not occur in s1
    case "$1" in
    *$2*) ;;
    *) return 1;;
    esac

    # use the pattern matching code to strip off the match and everything
    # following it
    first=${1/$2*/}

    # then strip off the first unmatched portion of the string
    echo "${1##$first}"
}

#:docstring strtok:
# Usage: strtok s1 s2
#
# Strtok considers the string s1 to consist of a sequence of zero or more
# text tokens separated by spans of one or more characters from the
# separator string s2.  The first call (with a non-empty string s1
# specified) echoes a string consisting of the first token on stdout. The
# function keeps track of its position in the string s1 between separate
# calls, so that subsequent calls made with the first argument an empty
# string will work through the string immediately following that token.  In
# this way subsequent calls will work through the string s1 until no tokens
# remain.  The separator string s2 may be different from call to call.
# When no token remains in s1, an empty value is echoed on stdout.
#:end docstring:

###;;;autoload
function strtok ()
{
 :
}

#:docstring strtrunc:
# Usage: strtrunc $n $s1 {$s2} {$...}
#
# Used by many functions like strncmp to truncate arguments for comparison.
# Echoes the first n characters of each string s1 s2 ... on stdout. 
#:end docstring:

###;;;autoload
function strtrunc ()
{
    n=$1 ; shift
    for z; do
        echo "${z:0:$n}"
    done
}

# provide string

# string.bash ends here


# ========================================================================== #
# ==> Everything below here added by the document author.

# ==> Suggested use of this script is to delete everything below here,
# ==> and "source" this file into your own scripts.

# strcat
string0=one
string1=two
echo
echo "Testing \"strcat\" function:"
echo "Original \"string0\" = $string0"
echo "\"string1\" = $string1"
strcat string0 string1
echo "New \"string0\" = $string0"
echo

# strlen
echo
echo "Testing \"strlen\" function:"
str=123456789
echo "\"str\" = $str"
echo -n "Length of \"str\" = "
strlen str
echo



# Exercise:
# --------
# Add code to test all the other string functions above.


exit 0

ane Chazelas demonstrates object-oriented programming in a Bash script.

le A-20. Object-oriented database

#!/bin/bash
# obj-oriented.sh: Object-oriented programming in a shell script.
# Script by Stephane Chazelas.


person.new()        # Looks almost like a class declaration in C++.
{
  local obj_name=$1 name=$2 firstname=$3 birthdate=$4

  eval "$obj_name.set_name() {
          eval \"$obj_name.get_name() {
                   echo \$1
                 }\"
        }"

  eval "$obj_name.set_firstname() {
          eval \"$obj_name.get_firstname() {
                   echo \$1
                 }\"
        }"

  eval "$obj_name.set_birthdate() {
          eval \"$obj_name.get_birthdate() {
            echo \$1
          }\"
          eval \"$obj_name.show_birthdate() {
            echo \$(date -d \"1/1/1970 0:0:\$1 GMT\")
          }\"
          eval \"$obj_name.get_age() {
            echo \$(( (\$(date +%s) - \$1) / 3600 / 24 / 365 ))
          }\"
        }"

  $obj_name.set_name $name
  $obj_name.set_firstname $firstname
  $obj_name.set_birthdate $birthdate
}

echo

person.new self Bozeman Bozo 101272413
# Create an instance of "person.new" (actually passing args to the function).

self.get_firstname       #   Bozo
self.get_name            #   Bozeman
self.get_age             #   28
self.get_birthdate       #   101272413
self.show_birthdate      #   Sat Mar 17 20:13:33 MST 1973

echo

# typeset -f
# to see the created functions (careful, it scrolls off the page).

exit 0

   Home	Next
ography	 	A Sed and Awk Micro-Primer
