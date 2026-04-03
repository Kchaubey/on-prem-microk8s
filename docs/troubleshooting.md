# Troubleshooting Guide (Expected Issues + Fixes)

This section documents frequent issues seen in on-prem MicroK8s + Helm blue-green environments.

## 1) MicroK8s stays in `not ready`

Symptom:

- `microk8s status --wait-ready` hangs or reports not ready services.

Likely causes:

- Swap enabled
- Low memory/disk
- Broken addon pod in `kube-system`

Fix:

```bash
sudo swapoff -a
free -h
df -h
microk8s inspect
kubectl get pods -n kube-system
kubectl describe pod <failing-pod> -n kube-system
```

## 2) CI cannot connect to cluster (`connection refused` on `:16443`)

Symptom:

- Pipeline fails on `kubectl` commands before deployment starts.

Likely causes:

- Wrong `KUBE_URL`
- Firewall block to API port
- Control-plane IP changed

Fix:

```bash
# from runner host network
nc -vz <control-plane-ip> 16443

# verify current API endpoint on control plane
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

Update CI variable `KUBE_URL` with the correct endpoint.

## 3) `x509: certificate signed by unknown authority`

Symptom:

- `kubectl` in CI fails with x509 certificate errors.

Likely causes:

- Wrong CA content in `KUBE_CA_CERT`
- CA not base64-decoded correctly in pipeline

Fix:

```bash
# regenerate CA value from working kubeconfig
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' ; echo
```

Replace `KUBE_CA_CERT` with this exact base64 value.

## 4) Pods fail with `ImagePullBackOff` / `ErrImagePull`

Symptom:

- New blue/green pods never become ready.

Likely causes:

- Missing/invalid registry secret
- Wrong image repository path or tag

Fix:

```bash
kubectl get secret registry-credentials -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

Recreate secret:

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server="<registry-url>" \
  --docker-username="<user>" \
  --docker-password="<password>" \
  -n <namespace> \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 5) Green smoke test fails in pipeline

Symptom:

- `test_green_k8s` cannot pass health check.

Likely causes:

- `HEALTH_PATH` mismatch
- `service.port` or `targetPort` mismatch
- green deployment scaled to 0 and never warmed up

Fix:

```bash
kubectl get svc -n <namespace> | grep <project>
kubectl get endpoints <project>-green-service -n <namespace>
kubectl logs deploy/<project>-green -n <namespace> --tail=200
```

Verify `HEALTH_PATH` and values file probe/service fields.

## 6) Ingress host returns `404` or default backend

Symptom:

- Domain resolves but serves wrong app/default backend.

Likely causes:

- Wrong ingress host/path in values file
- Ingress class mismatch (`nginx` vs custom)

Fix:

```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <project>-ingress -n <namespace>
kubectl get ingressclass
```

Set correct `ingress.className` and `ingress.hosts` in values file.

## 7) Ingress exists but not reachable from outside

Symptom:

- Service works internally, external access fails.

Likely causes:

- MetalLB not configured / no external IP
- Firewall/NAT missing for ingress endpoint

Fix:

```bash
kubectl get svc -n ingress
kubectl get svc -n ingress ingress-nginx-controller -o wide
kubectl get events -n ingress --sort-by=.metadata.creationTimestamp | tail -n 20
```

If EXTERNAL-IP is pending, configure MetalLB address pool in LAN range.

## 8) HPA shows `<unknown>` metrics

Symptom:

- `kubectl get hpa` shows no CPU/memory metrics.

Likely causes:

- `metrics-server` addon not healthy
- resources requests missing in values

Fix:

```bash
microk8s enable metrics-server
kubectl get pods -n kube-system | grep metrics
kubectl top pods -n <namespace>
```

Ensure each deployment has `resources.requests` configured.

## 9) Helm error: `another operation (install/upgrade/rollback) is in progress`

Symptom:

- New deployment command fails immediately.

Likely causes:

- Previous Helm action interrupted
- Release left in `pending-*` state

Fix:

```bash
helm history <release> -n <namespace>
helm status <release> -n <namespace>
```

Then either rollback or re-run safely:

```bash
helm rollback <release> <revision> -n <namespace> --wait --timeout 10m
```

## 10) Traffic switched to green but users still hit old behavior

Symptom:

- Helm reports success, but live behavior looks unchanged.

Likely causes:

- CDN/browser cache
- wrong host/path validation during testing
- app-level feature flags

Fix:

```bash
kubectl get svc <project>-service -n <namespace> -o yaml | grep -A3 selector
kubectl get pods -n <namespace> -l app=<project>,version=green -o wide
```

Confirm service selector is `version: green` and verify via direct pod/green-service checks.

## 11) Pods stay `Pending` with `nodeSelector` mismatch

Symptom:

- Scheduler cannot place pods.

Likely causes:

- values file `nodeSelector` labels do not exist on nodes

Fix:

```bash
kubectl get nodes --show-labels
kubectl describe pod <pod-name> -n <namespace>
```

Align `nodeSelector` with actual node labels.

## 12) Backend rollout spikes DB connections

Symptom:

- Database errors/timeouts during deployment.

Likely causes:

- both blue and green replicas active simultaneously

Fix:

Use single-active strategy:

```yaml
blueGreen:
  scaleDownInactive: true
  inactiveReplicaCount: 0

deploymentStrategy:
  green:
    type: Recreate
```

## 13) Namespace stuck in `Terminating`

Symptom:

- Namespace deletion never completes.

Likely causes:

- finalizer blocked on stale resource

Fix:

```bash
kubectl get namespace <namespace> -o json | jq '.spec.finalizers'
kubectl get all -n <namespace>
```

Clean stuck resources/finalizers and retry delete.

## 14) Disk pressure on node breaks scheduling

Symptom:

- New pods not scheduled; events mention disk pressure.

Likely causes:

- Snap/MicroK8s images and logs consumed disk

Fix:

```bash
df -h
sudo du -sh /var/snap/microk8s/* | sort -h
kubectl describe node <node-name> | grep -A5 -i pressure
```

Prune unused images/logs and expand disk capacity.

## 15) CoreDNS resolution failures between services

Symptom:

- Pods cannot resolve internal service names.

Likely causes:

- DNS addon unhealthy
- CNI/network issue

Fix:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deploy/coredns --tail=100
kubectl exec -it <pod> -n <namespace> -- nslookup kubernetes.default
```

Restart DNS addon if needed:

```bash
microk8s disable dns
microk8s enable dns
```

## Incident First-Response Command Pack

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 50
helm list -A
```
