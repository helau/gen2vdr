#!/bin/bash
BINPATH="/_config/bin"

setkeycodes e05f 124 >/dev/null 2>&1
setkeycodes e05b 0 >/dev/null 2>&1
loadkeys $BINPATH/mpvdr >/dev/null 2>&1

