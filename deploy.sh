#!/bin/sh

su tc -c "tce-load -i /cde/optional/Xlibs.tcz"
for z in $(cat /cde/onboot.lst); do             
    su tc -c "tce-load -i /cde/optional/${z}"
done                    
