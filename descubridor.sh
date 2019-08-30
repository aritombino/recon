#!/bin/bash

pathtmp="/tmp/aaaa"
pathtrabajo="$2"
subdominios="$2/$1"subdominios.txt
dominio="$1"
echo >  $pathtmp+amass
echo > $pathtmp+subli
echo > $pathtmp+anubis
echo > $pathtmp+anubis2
echo > $pathtmp+security
echo > $subdominios
echo > $pathtmp+aquatone
echo > $pathtmp+subfinder
mkdir "$pathtrabajo/nmap"
mkdir "$pathtrabajo/dirsearch"
mkdir "$pathtrabajo/aquatone"

# INICIA el ESCANEEOOOOOOOOOOO
sublist3r -d $dominio -o $pathtmp+subli &
## va asi porque sino no me escribe nada
/snap/amass/607/bin/amass -active -o $pathtmp+amass -d $dominio &
/opt/go/bin/subfinder -d $dominio -o $pathtmp+subfinder
wait

(/usr/local/bin/anubis -t $dominio -o $pathtmp+anubis ; (head -n -1 $pathtmp+anubis | tail -n +22 > $pathtmp+anubis2))
aquatone-discover -d $dominio

#Se espera a que terminennnnnn


##### PARSEO AQUATONE PRIMEROOOOOOOO
cp /root/aquatone/$dominio/hosts.txt $pathtmp+aquatone
sed -i 's/,.*$//' $pathtmp+aquatone

## BUSCO TODO EN security trails para obtener mas cositasssssssssssssssss y le saco las comillas al final porq joden

curl --request GET  --url https://api.securitytrails.com/v1/domain/$dominio/subdomains --header 'apikey: LFTxQK2Zil5hgvqLVGYlkYABFjYgyf0B ' |jq  -r '.subdomains' | jq '.[]' | tr -d \" |sed "s/ *$/.$dominio/g" > $pathtmp+security


#### ME ARMO LA LISTA Y LA ORDENOOOOOO
cat $pathtmp+aquatone $pathtmp+amass $pathtmp+subli $pathtmp+anubis2 $pathtmp+security $pathtmp+subfinder> $subdominios.tmp

####borro lienas al ped y espacios al final
sed -i '/^$/d' $subdominios.tmp
sed -i 's/ *$//g' $subdominios.tmp
sed -i "/*/d" $subdominios.tmp
###ELIMINO LOS REPETIDOSSSs
sort -u $subdominios.tmp  > $subdominios


#dirsearch -L $subdominios -r -w /usr/share/wordlists/personal.txt -e "*" --simple-report="$pathtrabajo/dirsearch/$dominio" --timeout=15  --max-retries=3 -x=403,404 &
#nmap -sS  -iL $subdominios --top-ports 500 -oA  "$pathtrabajo/nmap/$dominio" &
#eyewitness -f $subdominios --web  --prepend-https
#cat $subdominios | aquatone -scan-timeout 10000 -screenshot-timeout 10000 -http-timeout 10000 -out "$pathtrabajo/aquatone/$dominio"
