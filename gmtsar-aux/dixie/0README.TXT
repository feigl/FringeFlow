cat dixie_wells.tmp | sed 's/longitude//g' | sed 's/latitude//g' | sed 's/<//'g | sed 's/>//'g | sed 's%/description%%g' | sed 's%/%%g' | awk '{print $4,$5,$2,$3,$1}' > ! dixie_wells.txt



