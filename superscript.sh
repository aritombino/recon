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
securitytrailsapi=`cat /opt/securitytrailsapi`

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
echo > $pathtmp+findomain
mkdir "$pathtrabajo/nmap"
mkdir "$pathtrabajo/dirsearch"
mkdir "$pathtrabajo/aquatone"

## el orden de los recond esta asi por optimizacion de mi pc, pero pudeee cambbiiiiarr

# INICIA el ESCANEEOOOOOOOOOOO
sublist3r -d $dominio -o $pathtmp+subli &
## va asi porque sino no me escribe nada
/snap/bin/amass enum -active -o $pathtmp+amass -d $dominio &
/opt/go/bin/subfinder -d $dominio -o $pathtmp+subfinder
/usr/bin/findomain -t $dominio -u $pathtmp+findomain

wait

###Seteo la fecha para parsear el resultado despues
d=`date +%m-%d-%Y`
sudomy -s shodan,dnsdumpster,webarchive,virustotal,censys,dnsdb,entrust,crtsh,bufferover -tO -d $dominio
aquatone-discover -d $dominio
#(/usr/local/bin/anubis -t $dominio -o $pathtmp+anubis ; (head -n -1 $pathtmp+anubis | tail -n +22 > $pathtmp+anubis2))

##### PARSEO AQUATONE PRIMEROOOOOOOO
cp /root/aquatone/$dominio/hosts.txt $pathtmp+aquatone
sed -i 's/,.*$//' $pathtmp+aquatone

## BUSCO TODO EN security trails para obtener mas cositasssssssssssssssss y le saco las comillas al final porq joden

curl --request GET  --url https://api.securitytrails.com/v1/domain/$dominio/subdomains --header "apikey: $securitytrailsapi" |jq  -r '.subdomains' | jq '.[]' | tr -d \" |sed "s/ *$/.$dominio/g" > $pathtmp+security

#### ME ARMO LA LISTA Y LA ORDENOOOOOO
cat $pathtmp+aquatone $pathtmp+amass $pathtmp+subli $pathtmp+anubis2 $pathtmp+security $pathtmp+subfinder /opt/Sudomy/output/$d/$dominio/subdomain.txt > $subdominios.tmp

####borro lienas al ped  espacios y basura al final
sed -i '/^$/d' $subdominios.tmp
sed -i 's/ *$//g' $subdominios.tmp
sed -i "/*/d" $subdominios.tmp
###ELIMINO LOS REPETIDOSSSs
sort -u $subdominios.tmp  > $subdominios


##muevo el resultado del takeover al path de trabajo

mv /opt/Sudomy/output/$d/$dominio/TakeOver.txt $pathtrabajo


###THXXX @maurosoria para usar la tool jajajjaj  https://github.com/maurosoria/dirsearch.git
dirsearch -L $subdominios -r -w /usr/share/wordlists/personal.txt -E --timeout=15  --max-retries=3 --exclude-status=301,404,429,502 --simple-report=$pathtrabajo/dirsearch/$dominio.txt &

cat $subdominios | aquatone -scan-timeout 10000 -screenshot-timeout 10000 -http-timeout 10000 -out "$pathtrabajo/aquatone/gral"
nmap -sS  -iL $subdominios --top-ports 500 -oA  "$pathtrabajo/nmap/$dominio" &
eyewitness -f $subdominios --web  --prepend-https
