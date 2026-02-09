#!/bin/bash
rabbitmqadmin declare exchange name=orders.exchange type=direct
rabbitmqadmin declare exchange name=orders.dlx type=direct
rabbitmqadmin declare queue name=orders.queue durable=true \ 
 arguments='{"x-dead-letter-exchange":"orders.dlx","x-dead-letter-routing-key":"orders.dlq"}'
rabbitmqadmin declare queue name=orders.dlq durable=true
rabbitmqadmin declare queue name=orders.retry.5s durable=true \ 
 arguments='{"x-message-ttl":5000,"x-dead-letter-exchange":"orders.exchange","x-dead-letter-routing-key":"orders"}'
rabbitmqadmin declare queue name=orders.retry.30s durable=true \ 
 arguments='{"x-message-ttl":30000,"x-dead-letter-exchange":"orders.exchange","x-dead-letter-routing-key":"orders"}'
rabbitmqadmin declare queue name=orders.parking durable=true
rabbitmqadmin declare binding source=orders.exchange destination=orders.queue routing_key=orders
rabbitmqadmin declare binding source=orders.dlx destination=orders.dlq routing_key=orders.dlq
echo "✅ RabbitMQ queues & exchanges created"
