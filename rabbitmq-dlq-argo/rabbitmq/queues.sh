#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures — makes debugging easier

echo "Declaring exchanges..."
rabbitmqadmin declare exchange name=orders.exchange type=direct durable=true || echo "Exchange orders.exchange already exists or failed"
rabbitmqadmin declare exchange name=orders.dlx     type=direct durable=true || echo "Exchange orders.dlx already exists or failed"

echo "Declaring queues..."
rabbitmqadmin declare queue name=orders.queue durable=true \
  arguments='{"x-dead-letter-exchange":"orders.dlx","x-dead-letter-routing-key":"orders.dlq"}'

rabbitmqadmin declare queue name=orders.dlq durable=true

rabbitmqadmin declare queue name=orders.retry.5s durable=true \
  arguments='{"x-message-ttl":5000,"x-dead-letter-exchange":"orders.exchange","x-dead-letter-routing-key":"orders"}'

rabbitmqadmin declare queue name=orders.retry.30s durable=true \
  arguments='{"x-message-ttl":30000,"x-dead-letter-exchange":"orders.exchange","x-dead-letter-routing-key":"orders"}'

rabbitmqadmin declare queue name=orders.parking durable=true

echo "Creating bindings..."
# Bind main exchange → main queue
rabbitmqadmin declare binding source=orders.exchange \
  destination_type=queue \
  destination=orders.queue \
  routing_key=orders

# Bind DLX → DLQ
rabbitmqadmin declare binding source=orders.dlx \
  destination_type=queue \
  destination=orders.dlq \
  routing_key=orders.dlq

echo "✅ RabbitMQ queues, exchanges & bindings created (or already existed)"
echo "Check status:"
rabbitmqadmin list exchanges name type
rabbitmqadmin list queues name durable arguments messages_ready
rabbitmqadmin list bindings