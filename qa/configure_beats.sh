#!/bin/bash
if [ -z "$BEATS" ]; then . ./setenv.sh; fi

for beat in $BEATS; do (
  ls /etc/$beat/$beat.short.yml || cp /etc/$beat/$beat.yml /etc/$beat/$beat.short.yml
  cp /etc/$beat/$beat.full.yml /etc/$beat/$beat.yml || exit 1
  sed -i "s/#username:.*/username: \"$ELASTICUSER\"/" /etc/$beat/$beat.yml
  sed -i "s/#password:.*/password: \"$ELASTICPWD\"/"  /etc/$beat/$beat.yml
); done
