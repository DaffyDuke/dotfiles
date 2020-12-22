#!/bin/bash

trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG

var=2
echo $((var+2))