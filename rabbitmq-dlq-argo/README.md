# Event-Driven DLQ Processing with Argo Workflows

## Objective
- Dead Letter Queues (DLQ)
- Exponential backoff retry
- Circuit breaker logic
- Parking lot queue for poison messages
- Reprocessing via Argo Workflows
- GitOps deployment via Argo CD

## Setup
### RabbitMQ Local
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

### Create Exchanges & Queues
bash rabbitmq/queues.sh

### Deploy Argo Workflow
kubectl apply -f argo/configmap-script.yaml
kubectl apply -f argo/cron-workflow.yaml

### Argo CD Deployment
argocd app sync rabbitmq-dlq-argo
