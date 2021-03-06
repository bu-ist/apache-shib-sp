#!/bin/bash

# first we generate the shibboleth2.xml file based on environment variables passed in
# sp_idp=https://imp.bu.edu/idp/shibboleth
# sp_sp=http://imp.bu.edu:8000/shibboleth
# sp_skip_update=yes
#
if [ "x$sp_skip_update" = "x" ]; then
  # set defaults
  [ "x$sp_idp" = "x" ] && sp_idp="https://imp.bu.edu/idp/shibboleth"
  [ "x$sp_sp" = "x" ] && sp_sp="http://imp.bu.edu:8000/shibboleth"

  sed "s#SP_ENTITY_ID#$sp_sp#" </etc/shibboleth/shibboleth2-template.xml \
    | sed "s#SHIB_SP_KEY#$SHIB_SP_KEY#" \
    | sed "s#SP_HANDLER_URL#$SP_HANDLER_URL#" \
    | sed "s#SP_HOME_URL#$SP_HOME_URL#" \
    | sed "s#SHIB_SP_CERT#$SHIB_SP_CERT#" \
    | sed "s#IDP_ENTITY_ID#$sp_idp#" >/etc/shibboleth/shibboleth2.xml

  # get the idp-metadata.xml automatically only if not already provided
  if [ -a "/prefetched-data/idp-metadata.xml" ]; then
    cp /prefetched-data/idp-metadata.xml /etc/shibboleth/idp-metadata.xml
  else
    wget --no-check-certificate "$sp_idp" -P /tmp
    if [ -r "/tmp/shibboleth" ]; then
      mv /tmp/shibboleth /etc/shibboleth/idp-metadata.xml
    fi
  fi
fi

/etc/shibboleth/shibd-redhat start
