#!/bin/bash
set -e

DLQ="orders.dlq"
MAX_RETRY=3
FAILURE_THRESHOLD=5
STATE_FILE="/tmp/failures"

touch $STATE_FILE
FAILURES=$(cat $STATE_FILE)

if [[ $FAILURES -ge $FAILURE_THRESHOLD ]]; then
  echo "🚨 Circuit breaker OPEN"
  exit 0
fi

MSG=$(rabbitmqadmin get queue=$DLQ requeue=false count=1)

if [[ -z "$MSG" ]]; then
  echo "✅ DLQ empty"
  echo 0 > $STATE_FILE
  exit 0
fi

PAYLOAD=$(echo "$MSG" | grep payload | sed 's/.*payload=//')
ATTEMPT=$(echo "$PAYLOAD" | jq '.attempt')

if [[ $ATTEMPT -ge $MAX_RETRY ]]; then
  echo "🅿 Sending to Parking Lot"
  rabbitmqadmin publish exchange="" routing_key=orders.parking payload="$PAYLOAD"
  exit 0
fi

if [[ $ATTEMPT -eq 0 ]]; then
  RETRY_QUEUE="orders.retry.5s"
else
  RETRY_QUEUE="orders.retry.30s"
fi

NEW_PAYLOAD=$(echo "$PAYLOAD" | jq '.attempt += 1')
rabbitmqadmin publish exchange="" routing_key=$RETRY_QUEUE payload="$NEW_PAYLOAD"

FAILURES=$((FAILURES + 1))
echo $FAILURES > $STATE_FILE

echo "♻ Retried via $RETRY_QUEUE"
