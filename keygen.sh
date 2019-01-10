#! /bin/sh

while getopts h:u:g:o:e:y:bf c
     do
         case $c in
           u)         USER=$OPTARG;;
           g)         GROUP=$OPTARG;;
           o)         OUT=$OPTARG;;
           b)         BATCH=0;;
           f)         FORCE=1;;
           h)         FQDN=$OPTARG;;
           e)         ENTITYID=$OPTARG;;
           y)         YEARS=$OPTARG;;
           \?)        echo "keygen [-o output directory (default .)] [-u username to own keypair] [-g owning groupname] [-h hostname for cert] [-y years to issue cert] [-e entityID to embed in cert]"
                      exit 1;;
         esac
     done
if [ -z "$OUT" ] ; then
    OUT="."
    #..
fi

if [ -z "$FQDN" ] ; then
    FQDN=`hostname`
    exit
fi

KEY="${OUT}/sp-key.pem"
CERT="${OUT}/sp-cert.pem"

if [ -n "$FORCE" ] ; then
    rm "$KEY" "$CERT"
fi

if  [ -s "$KEY" -o -s "$CERT" ] ; then
    if [ -z "$BATCH" ] ; then  
        echo The files $KEY and/or "$CERT" already exist!
        echo Use -f option to force recreation of keypair.
        exit 2
    fi
    exit 0
fi

if [ -z "$YEARS" ] ; then
    YEARS=10
fi

DAYS=`expr $YEARS \* 365`

if [ -z "$ENTITYID" ] ; then
    ALTNAME=DNS:$FQDN
else
    ALTNAME=DNS:$FQDN,URI:$ENTITYID
fi

SSLCNF=$OUT/sp-cert.cnf
cat >$SSLCNF <<EOF
# OpenSSL configuration file for creating sp-cert.pem
[req]
prompt=no
default_bits=2048
encrypt_key=no
default_md=sha1
distinguished_name=dn
# PrintableStrings only
string_mask=MASK:0002
x509_extensions=ext
[dn]
CN=$FQDN
[ext]
subjectAltName=$ALTNAME
subjectKeyIdentifier=hash
EOF

touch "$KEY"
if [ -z "$BATCH" ] ; then
    openssl req -config $SSLCNF -new -x509 -days $DAYS -keyout "$KEY" -out "$CERT"
else
    openssl req -config $SSLCNF -new -x509 -days $DAYS -keyout "$KEY" -out "$CERT" 2> /dev/null
fi
rm $SSLCNF

exit
if  [ -s $OUT/sp-key.pem -a -n "$USER" ] ; then
    chown $USER $OUT/sp-key.pem $OUT/sp-cert.pem
fi

if  [ -s $OUT/sp-key.pem -a -n "$GROUP" ] ; then
    chgrp $GROUP $OUT/sp-key.pem $OUT/sp-cert.pem
fi
