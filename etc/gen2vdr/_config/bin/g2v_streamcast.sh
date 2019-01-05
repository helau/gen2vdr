#!/bin/bash
UTIL_DIR="/_config/bin"
DEPTH=10

UTIL_DIR/get_icefxd.sh $DEPTH
UTIL_DIR/get_shoutfxd.sh $DEPTH

screen -dm sh -c "UTIL_DIR/get_castlogos.sh"
