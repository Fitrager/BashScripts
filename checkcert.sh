#!/bin/bash
CERTIFICATE_FILE=$(mktemp)
WEBSITE_LIST=`cat ./list.txt`
MAX_DAYS=35
MIN_DAYS=1
RESULT_LIST=''
for CERT in ${WEBSITE_LIST}
do
    echo -n | openssl s_client -servername "$CERT" -connect "$CERT":443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATE_FILE
    date=$(openssl x509 -in $CERTIFICATE_FILE -enddate -noout | sed "s/.*=\(.*\)/\1/")
    date_s=$(date -d "${date}" +%s)
    now_s=$(date -d now +%s)
    date_diff=$(( (date_s - now_s) / 86400 ))
    issuer=$(openssl x509 -in $CERTIFICATE_FILE -issuer -noout | sed "s/.*=\(.*\)/\1/") 
    if [[ $date_diff -lt $MAX_DAYS && $date_diff -gt $MIN_DAYS ]]
    then
        RESULT_LIST+=$(echo "SOON_EXPIRE | ${date_diff} | ${CERT} | ${issuer}\n")
    elif [[ $date_diff -lt 0 ]] 
    then
        RESULT_LIST+=$(echo "EXPIRED | ${date_diff} | ${CERT} | ${issuer}\n")
    else  
        RESULT_LIST+=$(echo "OK | ${date_diff} | ${CERT} | ${issuer}\n")
    fi
done
echo -e $RESULT_LIST | sort
