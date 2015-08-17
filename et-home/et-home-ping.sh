#!/bin/bash
if [ -f ~/et-home-msg ]
then
    cat ~/et-home-msg
    rm ~/et-home-msg
else
    echo "0"
fi
