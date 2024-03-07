#!/bin/bash

for filename in /shc-data/bash/*.sh; do

    for ((i=0; i<=3; i++)); do

        shc -r -f $filename -o "$filename-build"

    done

done

rm -f /shc-data/bash/*.c