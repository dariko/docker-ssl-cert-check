#!/bin/bash

ENDPOINTS_FILE=/ssl_endpoints_list

if [[ -v ENDPOINTS ]]; then
  echo "$ENDPOINTS" >> "$ENDPOINTS_FILE"
elif [[ ! -f $ENDPOINTS_FILE ]];then
  echo "Missing ENDPOINTS variable or $ENDPOINTS_FILE file"
  exit 1
fi

if [[ -v SEND_EMAIL ]]; then
  if [[ ! -v SMTP_URI ]] || \
     [[ ! -v SMTP_USER ]] || \
     [[ ! -v SMTP_TO ]] || \
     [[ ! -v SMTP_PASS ]]; then
    echo "SEND_EMAIL option requires SMTP_USER, SMTP_PASS, SMTP_TO and SMTP_URI to be set"
    exit 1
  fi
  : ${SMTP_FROM:=ssl-cert-check@localhost.localdomain}
eval "cat > ~/.mailrc << EOF
$(cat /tmp/mailrc.template)
EOF"
  EMAIL_OPTIONS=" -a -e $SMTP_TO"
fi

: ${WARNING_DAYS:=30}
command="/ssl-cert-check -f $ENDPOINTS_FILE -x $WARNING_DAYS $EMAIL_OPTIONS"

while true;
do
  if [[ -v DAILY_TIME ]]; then
    current_timestamp=$(date +%s)
    next_timestamp=$(date -d "today ${DAILY_TIME}" +%s)
    if [[ $current_timestamp > $next_timestamp ]]; then
      next_timestamp=$(date -d "tomorrow ${DAILY_TIME}" +%s)
    fi
    seconds_to_next_timestamp=$((next_timestamp - current_timestamp))
    echo "Sleeping $seconds_to_next_timestamp seconds for next execution"
    sleep $seconds_to_next_timestamp
    $command
  elif [[ -v CHECK_INTERVAL ]]; then
    $command
    echo "Sleeping $CHECK_INTERVAL seconds for next execution"
    sleep $CHECK_INTERVAL
  else
    $command
    exit 0
  fi
done
