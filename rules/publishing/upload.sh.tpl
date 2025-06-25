#!/usr/bin/env bash

if [[ -z "${SONATYPE_USERNAME}" || -z ${SONATYPE_PASSWORD} ]]; then
    echo "Missing SONATYPE_PASSWORD and/or SONATYPE_USERNAME envs. Exiting with error." 1>&2
    exit -1
fi

SONATYPE_TOKEN=$({ECHO} -n $SONATYPE_USERNAME:$SONATYPE_PASSWORD | {BASE64} -w0)

{CURL} \
   --request POST \
   --silent \
   --header 'Authorization: Bearer ${SONATYPE_TOKEN}' \
   --form bundle=@{BUNDLE} \
   https://central.sonatype.com/api/v1/publisher/upload?publishingType=AUTOMATIC
