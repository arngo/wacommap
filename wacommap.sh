#!/bin/bash

device=$(xsetwacom list | grep STYLUS | awk '{print $9}')

if [[ -z "$device" ]]; then
    echo "Tablet not found."
    exit 1
fi

center=0
rot=none
mode=''

while getopts ":m:r:c" flag
do
    case "${flag}" in
        m)
            mode=${OPTARG}
            if [[ "$mode" != "fit" && "$mode" != "width" ]]; then
                echo "Invalid mode: $mode"
                exit 1
            fi
            ;;
        r)
            rot=${OPTARG}
            if [[ "$rot" != "cw" && "$rot" != "ccw" && "$rot" != "half" && "$rot" != "none" ]]
            then
                echo "Invalid rotation: $rot"
                exit 1
            else
                xsetwacom set $device Rotate $rot
            fi
            ;;
        c)
            center=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

slop=$(slop -f "%x %y %w %h %g") || exit 1
read -r X Y W H G < <(echo $slop)
area=$(xsetwacom get $device area)
read -r TX TY TW TH < <(echo $area)

# swap tablet width and height if rotated
if [[ "$rot" == "cw" || "$rot" == ccw ]]; then
    temp=$TH
    TH=$TW
    TW=$temp
fi

mapwidth=$W
mapheight=$H

if [[ -n $mode ]]; then
    if [[ "$mode" == "fit" ]]; then
        mapwidth=$((H*TW/TH))
    fi

    if [[ "$mapwidth" -gt "$W" || "$mode" == "width" ]]; then
        mapwidth=$W
        mapheight=$((W*TH/TW))
    fi
fi

if [[ $center -eq 1 ]]; then
    diffW=$((W-mapwidth))
    diffH=$((H-mapheight))

    X=$((X+diffW/2))
    Y=$((Y+diffH/2))
fi

xsetwacom set $device MapToOutput ${mapwidth}x${mapheight}+$X+$Y
