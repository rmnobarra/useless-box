#1. Imagem Inválida no Container
#Altere a imagem da useless-box para algo inexistente:

kubectl -n ns-52327214 patch deployment useless-box \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"invalid/image:tag"}]'

#2. Requests/Limits Impossíveis (Pod não agenda)
#Defina requests/limits muito altos:

kubectl -n ns-52327214 patch deployment useless-box \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value":{"requests":{"cpu":"1000", "memory":"1Ti"}, "limits":{"cpu":"2000", "memory":"2Ti"}}}]'

#3. Remoção de PVC do Redis
#Identifique e delete o PVC do Redis:
kubectl get pvc -n ns-52327214
kubectl delete pvc redis-release-master-0 -n ns-52327214

#4. Affinity ou Toleration Inviável
#Adicione nodeAffinity impossível:
kubectl -n ns-52327214 patch deployment useless-box \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/affinity", "value":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"nonexistent-label","operator":"In","values":["never"]}]}]}}}}]'

# 5. Aplicar ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cpu-memory-quota
  namespace: ns-52327214
spec:
  hard:
    requests.cpu: "200m"
    requests.memory: "256Mi"
    limits.cpu: "500m"
    limits.memory: "512Mi"
    pods: "2"

kubectl apply -f quota.yaml
kubectl scale deployment useless-box -n ns-52327214 --replicas=3

# 6. Node NotReady
kubectl taint nodes ip-192-168-1-100.ec2.internal node.kubernetes.io/unreachable=true:NoSchedule
# para voltar kubectl taint nodes ip-192-168-1-100.ec2.internal node.kubernetes.io/unreachable:NoSchedule-

# Injetar stress de memória dentro do pod
kubectl exec -it -n ns-52327214 $(kubectl get pods -n ns-52327214 -l app=useless-box -o jsonpath='{.items[0].metadata.name}') -- /bin/sh
# Dentro do pod:
apk add --no-cache stress    # ou apt-get install stress
stress --vm 1 --vm-bytes 300M --vm-hang 1

