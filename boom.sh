#!/bin/bash

declare -A NS_ERRORS=(
  ["ns-48414609"]="invalid_image"
  ["ns-49212557"]="bad_resources"
  ["ns-52327214"]="delete_pvc"
  ["ns-68213933"]="affinity_block"
  ["ns-94714545"]="quota_exceed"
  ["ns-95875646"]="node_taint"
)

NODES=("build-and-run-worker" "build-and-run-worker2" "build-and-run-worker3")
node_index=0

# 🚫 PRIMEIRO PASSO: Cordon (unschedule) todos os nodes
echo "🚫 CORDONING TODOS OS NODES - Nenhum pod novo será agendado"
echo "=================================================="
for NODE in "${NODES[@]}"; do
  echo "🔒 Cordoning node: $NODE"
  kubectl cordon $NODE
done
echo "=================================================="
echo

for NS in "${!NS_ERRORS[@]}"; do
  ERROR_TYPE="${NS_ERRORS[$NS]}"
  NODE="${NODES[$((node_index % ${#NODES[@]}))]}"
  echo "===================================="
  echo "Namespace: $NS | Falha: $ERROR_TYPE"
  echo "Node alvo (se aplicável): $NODE"
  echo "===================================="

  case $ERROR_TYPE in

    invalid_image)
      echo "🚫 Alterando imagem para inválida"
      kubectl -n $NS patch deployment useless-box \
        --type='json' \
        -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"invalid/image:tag"}]'
      ;;

    bad_resources)
      echo "📉 Definindo requests/limits impossíveis"
      kubectl -n $NS patch deployment useless-box \
        --type='json' \
        -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value":{"requests":{"cpu":"1000", "memory":"1Ti"}, "limits":{"cpu":"2000", "memory":"2Ti"}}}]'
      ;;

    delete_pvc)
      echo "🧨 Criando falhas de armazenamento Redis"

      # 1. Primeiro, cria um PVC com StorageClass inexistente para gerar eventos de erro
      echo "📦 Criando PVC com StorageClass inexistente"
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: broken-redis-storage
  namespace: $NS
  labels:
    app: redis-broken
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  storageClassName: nonexistent-storage-class
EOF

      # 2. Força o Redis a usar armazenamento inexistente através de patch
      echo "⚠️ Alterando Redis para usar PVC inexistente"
      kubectl -n $NS patch statefulset redis-release-master \
        --type='json' \
        -p='[{"op": "replace", "path": "/spec/volumeClaimTemplates/0/spec/storageClassName", "value":"nonexistent-storage-class"}]' \
        2>/dev/null || true

      # 3. Força restart do StatefulSet para tentar montar o volume quebrado
      echo "🔄 Forçando restart do Redis StatefulSet"
      kubectl rollout restart statefulset/redis-release-master -n $NS 2>/dev/null || true

      # 4. Simula corrupção de dados removendo finalizers de PVCs ativos (cria inconsistência)
      PVC_NAME=$(kubectl get pvc -n $NS -o jsonpath='{.items[?(@.metadata.name contains "redis-release-master")].metadata.name}' 2>/dev/null)
      
      if [ -n "$PVC_NAME" ]; then
        echo "� Removendo finalizers do PVC ativo (simula corrupção)"
        kubectl patch pvc $PVC_NAME -n $NS --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
      fi

      # 5. Cria múltiplos pods tentando usar o mesmo PVC (conflito de montagem)
      echo "⚔️ Criando conflito de montagem de volume"
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: conflicting-pod-1
  namespace: $NS
  labels:
    app: volume-conflict
spec:
  containers:
  - name: redis
    image: redis:6.2-alpine
    volumeMounts:
    - name: redis-data
      mountPath: /data
  volumes:
  - name: redis-data
    persistentVolumeClaim:
      claimName: $PVC_NAME
---
apiVersion: v1
kind: Pod
metadata:
  name: conflicting-pod-2
  namespace: $NS
  labels:
    app: volume-conflict
spec:
  containers:
  - name: redis
    image: redis:6.2-alpine
    volumeMounts:
    - name: redis-data
      mountPath: /data
  volumes:
  - name: redis-data
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF

      echo "✅ Falhas de armazenamento criadas - verifique eventos e logs para observabilidade"
      ;;

    affinity_block)
      echo "🚫 Injetando nodeAffinity impossível"
      kubectl -n $NS patch deployment useless-box \
        --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/affinity", "value":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"nonexistent-label","operator":"In","values":["never"]}]}]}}}}]'
      ;;

    quota_exceed)
      echo "📊 Aplicando ResourceQuota e escalando pods"
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cpu-memory-quota
  namespace: $NS
spec:
  hard:
    requests.cpu: "200m"
    requests.memory: "256Mi"
    limits.cpu: "500m"
    limits.memory: "512Mi"
    pods: "2"
EOF
      kubectl scale deployment useless-box -n $NS --replicas=3
      ;;

    node_taint)
      echo "🛑 Simulando Node NotReady via taint"
      kubectl taint nodes $NODE node.kubernetes.io/unreachable=true:NoSchedule
      ((node_index++))
      ;;
  esac

  echo
done

echo "🔁 Para reverter todas as alterações:"
echo "======================================="
echo "# Uncordon nodes:"
for NODE in "${NODES[@]}"; do
  echo "kubectl uncordon $NODE"
done
echo
echo "# Remover taints:"
for NODE in "${NODES[@]}"; do
  echo "kubectl taint nodes $NODE node.kubernetes.io/unreachable:NoSchedule-"
done
