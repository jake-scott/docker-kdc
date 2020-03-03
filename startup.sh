#!/bin/bash

umask 077

if [[ ! -e ${KRB5_CONFIG} ]]
then
    if [[ -z ${REALM} ]]
    then
        echo New config: specify REALM variable
        exit 1
    fi

    sed "s;%REALM%;${REALM};g ; s;%HOST%;${HOSTNAME};g"  /opt/kdc/templates/krb5.conf >${KRB5_CONFIG}
fi

if [[ ! -e ${KRB5_KDC_PROFILE} ]]
then
    if [[ -z ${REALM} ]]
    then
        echo New config: specify REALM variable
        exit 1
    fi

    sed "s;%REALM%;${REALM};g  ; s;%HOST%;${HOSTNAME};g"  /opt/kdc/templates/kdc.conf >${KRB5_KDC_PROFILE}
fi


if [[ ! -e /kdc/logs ]]
then
    mkdir -p /kdc/logs
fi

if [[ ! -e /kdc/db ]]
then
    mkdir -p /kdc/db
fi

if [[ ! -e /kdc/db/principal ]]
then
    if [[ -z ${REALM} ]]
    then
        echo New config: specify REALM variable
        exit 1
    fi

    echo Initialising realm 
    kdb5_util create -r ${REALM} -s -P password

    PW="$(pwmake 128)"
    kadmin.local addprinc -pw "${PW}" admin/admin@${REALM}
    echo "NEW DATABASE: password for admin/admin@${REALM}: [${PW}]"
fi

if [[ ! -e /kdc/db/kadm5.acl ]]
then
    if [[ -z ${REALM} ]]
    then
        echo New config: specify REALM variable
        exit 1
    fi

    sed "s;%REALM%;${REALM};g  ; s;%HOST%;${HOSTNAME};g"  /opt/kdc/templates/kadm5.acl >/kdc/db/kadm5.acl
fi

krb5kdc
kadmind -nofork


