🔴 Real-Time Local Simulation Runbook
RabbitMQ + DLQ + Argo Workflows (Laptop Demo)

🧱 What You’ll See Live
In RabbitMQ UI + Argo UI, you will watch:

Message published in real time

Consumer fails → message hits DLQ

Argo CronWorkflow triggers

Message moves to retry queue (with delay)

Message re-appears in main queue

After max retry → parking lot

No guessing. You’ll see counters change.

1️⃣ Start Everything Locally
🐳 Start RabbitMQ
docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  rabbitmq:3-management
Open RabbitMQ UI
👉 http://localhost:15672
Login: guest / guest

Keep this tab open.

☸️ Start Kubernetes (Minikube)
minikube start
kubectl create namespace argo
🔁 Install Argo Workflows
kubectl apply -n argo \
 -f https://raw.githubusercontent.com/argoproj/argo-workflows/stable/manifests/install.yaml
Expose UI:

kubectl -n argo port-forward svc/argo-server 2746:2746
Open:
👉 http://localhost:2746

2️⃣ Create Queues (One Time)
Run your queue setup script:

bash rabbitmq/queues.sh
In RabbitMQ UI:

Go to Queues

Confirm:

orders.queue

orders.dlq

orders.retry.5s

orders.retry.30s

orders.parking

3️⃣ Deploy Argo CronWorkflow
kubectl apply -f argo/configmap-script.yaml
kubectl apply -f argo/cron-workflow.yaml
In Argo UI:

Click Cron Workflows

You should see dlq-reprocessor

4️⃣ Real-Time Message Injection (Postman)
Postman Request
POST

http://localhost:15672/api/exchanges/%2F/orders.exchange/publish
Auth: Basic
guest / guest

Body (raw JSON):

{
  "routing_key": "orders",
  "payload": "{\"orderId\":901,\"attempt\":0}",
  "payload_encoding": "string"
}
👉 Click Send

5️⃣ Live Failure Simulation (Manual Consumer)
Now simulate consumer failure:

rabbitmqadmin get queue=orders.queue requeue=false count=1
Watch in RabbitMQ UI
orders.queue → 0

orders.dlq → 1 🔴

This is real time.

6️⃣ Watch Argo Pick It Up (Live)
Wait until next schedule (or trigger manually):

argo cron run dlq-reprocessor
In Argo UI:
Click workflow run

Open Logs

You’ll see:

♻ Retried via orders.retry.5s
7️⃣ Watch Retry Queue Countdown ⏱
In RabbitMQ UI:

orders.retry.5s → 1

Wait ~5 seconds

orders.retry.5s → 0

orders.queue → 1 ✅

This is real-time delayed retry.

8️⃣ Force Max Retry → Parking Lot
Repeat failure 3 times:

rabbitmqadmin get queue=orders.queue requeue=false count=1
Run workflow again:

argo cron run dlq-reprocessor
After attempt = 3:

RabbitMQ UI:
orders.parking → 1 🅿️

orders.dlq → 0

🎉 Poison message safely isolated

9️⃣ Circuit Breaker Demo (Very Cool 🔥)
Rapidly push failures:

for i in {1..6}; do
  rabbitmqadmin publish exchange=orders.exchange routing_key=orders \
   payload='{"orderId":999,"attempt":0}'
done
DLQ fills.

Next Argo run:

Logs show:

🚨 Circuit breaker OPEN
Processing halts safely.

🔎 What to Keep Open During Demo
Tool	Why
RabbitMQ UI	Queue depth changes
Argo UI	Workflow execution
Terminal	Manual triggers
Postman	Real-time injection
🎤 How to Explain This in Real Time (Interview Tip)
“I simulate production failures locally by injecting messages via RabbitMQ HTTP API, forcing consumer failures, and observing DLQ recovery via Argo Workflows in real time.”

That sentence + live demo = instant credibility.

🚀 Want an Even Better Demo?
I can add:

Live Grafana dashboards

Slack alert when DLQ > 0

Manual replay workflow from parking lot

Chaos testing (random failures)

One-click make demo script

Say the word — you’re very close to a killer portfolio demo 💥

Live Grafana dashboards
YES 🔥 — this is the final polish that makes your demo look production-real.
I’ll show you LIVE Grafana dashboards on your local machine, wired to RabbitMQ + DLQ + retries + Argo Workflows.

You’ll literally watch charts move while messages flow.

📊 Live Grafana Dashboards (Local, Real-Time)
🎯 What You’ll See LIVE
In Grafana, in real time:

📦 Main queue depth

💀 DLQ size

🔁 Retry queues (5s / 30s)

🅿 Parking lot count

⏱ Message rate

🚨 Alert when DLQ > 0

🧠 Monitoring Architecture
RabbitMQ
   │
   ├─ rabbitmq_exporter
   │
Prometheus
   │
Grafana Dashboards (LIVE)
1️⃣ Run RabbitMQ Exporter (Local)
RabbitMQ does NOT expose Prometheus metrics by default.

Run exporter
docker run -d \
  --name rabbitmq-exporter \
  -p 9419:9419 \
  -e RABBIT_URL=http://host.docker.internal:15672 \
  -e RABBIT_USER=guest \
  -e RABBIT_PASSWORD=guest \
  kbudde/rabbitmq-exporter
Verify:

curl http://localhost:9419/metrics
✔ You should see metrics output

2️⃣ Run Prometheus (Local)
prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "rabbitmq"
    static_configs:
      - targets: ["host.docker.internal:9419"]
Run Prometheus:

docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
Open:
👉 http://localhost:9090
Test query:

rabbitmq_queue_messages_ready
3️⃣ Run Grafana (Local)
docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana
Open:
👉 http://localhost:3000
Login: admin / admin

4️⃣ Connect Grafana → Prometheus
Grafana → Settings → Data Sources

Add Prometheus

URL:

http://host.docker.internal:9090
Save & Test ✅

5️⃣ Create LIVE Dashboards (Key Panels)
📦 Main Queue Depth
Query

rabbitmq_queue_messages_ready{queue="orders.queue"}
💀 DLQ Depth (MOST IMPORTANT)
rabbitmq_queue_messages_ready{queue="orders.dlq"}
➡ This moves instantly when failures happen.

🔁 Retry Queues
rabbitmq_queue_messages_ready{queue=~"orders.retry.*"}
🅿 Parking Lot Queue
rabbitmq_queue_messages_ready{queue="orders.parking"}
📈 Message Publish Rate
rate(rabbitmq_channel_messages_published_total[1m])
⚠️ Circuit Breaker Visibility (Indirect)
increase(rabbitmq_queue_messages_ready{queue="orders.dlq"}[5m])
Shows DLQ growth trend.

6️⃣ Create a DLQ ALERT (Live 🔥)
Grafana Alert Rule
Condition:

rabbitmq_queue_messages_ready{queue="orders.dlq"} > 0
Trigger:

Slack

Email

Webhook

📌 This mirrors real SRE alerting.

7️⃣ Real-Time Demo Flow (Do This Live)
1. Open Grafana dashboard
2. Open RabbitMQ UI
3. Open Argo UI
Now:

rabbitmqadmin publish exchange=orders.exchange routing_key=orders \
 payload='{"orderId":111,"attempt":0}'
Then:

rabbitmqadmin get queue=orders.queue requeue=false count=1
WATCH LIVE:
📉 orders.queue drops

📈 orders.dlq spikes

⏳ orders.retry.5s rises

🔄 Back to orders.queue

🅿 After retries → orders.parking

Everything updates within seconds.
