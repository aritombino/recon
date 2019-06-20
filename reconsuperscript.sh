#######################
### in order to execute this script u have to isntall:
### amass, anubis, aquatone, jq and eyewitness
### the bin's paths are symbolic, so could change in yr pc
#######################


#!/bin/bash
#########################
#first parameter: web to recon
#second parameter: path to store data
#########################
dominio="$1"
pathtrabajo="$2"
subdominios="$2/$1"subdominios.txt

#####paths temporales para que vaya guardando por si se caee todo
pathtmp="/tmp/aaaa"
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

## el orden de los recond esta asi por optimizacion de mi pc, pero pudeee cambbiiiiarr

# INICIA el ESCANEEOOOOOOOOOOO
sublist3r -d $dominio -o $pathtmp+subli &
## va asi porque sino no me escribe nada
/snap/amass/607/bin/amass -active -o $pathtmp+amass -d $dominio &
/opt/go/bin/subfinder -d $dominio -o $pathtmp+subfinder

wait

(/usr/local/bin/anubis -t $dominio -o $pathtmp+anubis ; (head -n -1 $pathtmp+anubis | tail -n +22 > $pathtmp+anubis2))
aquatone-discover -d $dominio


##### PARSEO AQUATONE PRIMEROOOOOOOO
cp /root/aquatone/$dominio/hosts.txt $pathtmp+aquatone
sed -i 's/,.*$//' $pathtmp+aquatone

## BUSCO TODO EN security trails para obtener mas cositasssssssssssssssss y le saco las comillas al final porq joden

curl --request GET  --url https://api.securitytrails.com/v1/domain/$dominio/subdomains --header 'apikey: MANDALETUKEY ' |jq  -r '.subdomains' | jq '.[]' | tr -d \" |sed "s/ *$/.$dominio/g" > $pathtmp+security


#### ME ARMO LA LISTA Y LA ORDENOOOOOO
cat $pathtmp+aquatone $pathtmp+amass $pathtmp+subli $pathtmp+anubis2 $pathtmp+security $pathtmp+subfinder> $subdominios.tmp

####borro lienas al ped  espacios y basura al final
sed -i '/^$/d' $subdominios.tmp
sed -i 's/ *$//g' $subdominios.tmp
sed -i "/*/d" $subdominios.tmp
###ELIMINO LOS REPETIDOSSSs
sort -u $subdominios.tmp  > $subdominios


dirsearch -L $subdominios -r -w /usr/share/wordlists/personal.txt -e "*" --simple-report="$pathtrabajo/dirsearch/$dominio" --timeout=15  --max-retries=3 -x=403,404 &
nmap -sS  -iL $subdominios --top-ports 500 -oA  "$pathtrabajo/nmap/$dominio" &
eyewitness -f $subdominios --web  --prepend-https