#!/usr/bin/env bash

{CURL} \
   --request POST \
   --verbose \
   --header 'Authorization: Bearer {SONATYPE_TOKEN}' \
   --form bundle=@{BUNDLE} \
   https://central.sonatype.com/api/v1/publisher/upload?publishingType=AUTOMATIC
