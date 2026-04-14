# Patroni HA PostgreSQL Cluster — Helm Chart PoC

A production-grade Patroni cluster on Kubernetes with:
- **3 PostgreSQL nodes** (1 primary + 2 replicas) managed by Patroni
- **3-node embedded etcd** cluster as the DCS
- **PodDisruptionBudget** (minAvailable: 2) for safe node drains
- **NetworkPolicy** to isolate Patroni ↔ etcd traffic
- **Resource limits** on all containers
- **Anti-affinity rules** to spread pods across nodes
- **RBAC** for Patroni to manage Kubernetes endpoints

---

## Prerequisites

| Tool | Version |
|------|---------|
| Kubernetes | ≥ 1.25 |
| Helm | ≥ 3.10 |
| kubectl | matching cluster |
| Cloud storage class | gp3 (EKS) / pd-ssd (GKE) / managed-premium (AKS) |

---

## Quick Start

```bash
# 1. Create namespace
kubectl create namespace patroni

# 2. Install the chart
helm install patroni-cluster ./patroni-cluster \
  --namespace patroni \
  --set postgresql.postgresPassword=MySecurePass123 \
  --set postgresql.replicationPassword=MyReplPass123

# 3. Watch rollout (etcd first, then Patroni)
kubectl get pods -n patroni -w

# 4. Check cluster status (once all pods are Running)
kubectl exec -n patroni patroni-cluster-0 -- \
  patronictl -c /etc/patroni/patroni.yaml list
```

Expected output:
```
+ Cluster: patroni-cluster ----+----+-----------+
| Member              | Host  | Role    | State   |
+---------------------+-------+---------+---------+
| patroni-cluster-0   | ...   | Leader  | running |
| patroni-cluster-1   | ...   | Replica | running |
| patroni-cluster-2   | ...   | Replica | running |
+---------------------+-------+---------+---------+
```

---

## Cloud-Specific Storage Class

Set the right StorageClass for your cloud:

```bash
# EKS (gp3)
--set persistence.storageClass=gp3

# GKE (SSD)
--set persistence.storageClass=premium-rwo

# AKS (managed-premium)
--set persistence.storageClass=managed-premium
```

---

## Architecture

```
                    ┌─────────────────────────────┐
                    │         Kubernetes           │
                    │                             │
   App ──► primary-svc (RW)                       │
   App ──► replica-svc (RO)                       │
                    │                             │
        ┌───────────┼───────────┐                 │
        │           │           │                 │
   [Pod-0]      [Pod-1]      [Pod-2]              │
   Patroni      Patroni      Patroni              │
   Primary      Replica      Replica              │
        │           │           │                 │
        └─────── etcd cluster ──┘                 │
              [etcd-0,1,2]                        │
                    └─────────────────────────────┘
```

---

## Verify HA Failover

```bash
# 1. Find the current leader
kubectl exec -n patroni patroni-cluster-0 -- \
  patronictl -c /etc/patroni/patroni.yaml list

# 2. Delete the leader pod to simulate failure
kubectl delete pod patroni-cluster-0 -n patroni

# 3. Watch Patroni elect a new leader (takes ~10-15s)
kubectl exec -n patroni patroni-cluster-1 -- \
  patronictl -c /etc/patroni/patroni.yaml list
```

---

## Key values.yaml Overrides

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | 3 | Number of Patroni pods |
| `postgresql.postgresPassword` | changeme | Superuser password |
| `persistence.size` | 10Gi | PVC size per pod |
| `persistence.storageClass` | "" | Cloud storage class |
| `resources.limits.cpu` | 2000m | CPU limit per pod |
| `resources.limits.memory` | 2Gi | Memory limit per pod |
| `podDisruptionBudget.minAvailable` | 2 | Minimum pods during disruption |
| `networkPolicy.enabled` | true | Enable network isolation |

---

## Uninstall

```bash
helm uninstall patroni-cluster -n patroni

# Remove PVCs (data is lost!)
kubectl delete pvc -n patroni -l app.kubernetes.io/name=patroni-cluster
```
