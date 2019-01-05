#!/bin/bash
#
BOARD="Unknown board"
BI="$(biosinfo)"

case "$BI" in 
   *QDI\ Winnex9* | *i810\-W83627HF*)
      BOARD="MP_QDI" ;;
   *07/15/97* | *Instant810C*)
      case "$BI" in
         *1.21*)
	    BOARD="MP_AVT121" ;;
         *)
            BOARD="MP_AVT122" ;;
      esac
      ;;	    
   *D1231* | *D163[68]* | *1\.01\.163[68]*)
      BOARD="ACTIVY" ;;
   *Solano\ System\ CR\ Platform*)
      BOARD="SMT7020" ;;
   *VirtualBox*)
      BOARD="VirtualBox" ;;
esac      
echo "$BOARD"
