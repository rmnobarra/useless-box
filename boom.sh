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
      echo "🧨 Quebrando armazenamento Redis - Impacto direto na aplicação"

      # 1. Identifica e deleta o PVC do Redis (vai quebrar o Redis imediatamente)
      echo "🔍 Identificando PVC do Redis..."
      REDIS_PVC=$(kubectl get pvc -n $NS -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
      
      if [ -n "$REDIS_PVC" ]; then
        echo "💣 DELETANDO PVC DO REDIS: $REDIS_PVC"
        kubectl delete pvc $REDIS_PVC -n $NS --force --grace-period=0 2>/dev/null || true
        
        # 2. Remove o PV associado se existir (garante que não há recovery)
        REDIS_PV=$(kubectl get pv -o jsonpath="{.items[?(@.spec.claimRef.name=='$REDIS_PVC' && @.spec.claimRef.namespace=='$NS')].metadata.name}" 2>/dev/null)
        if [ -n "$REDIS_PV" ]; then
          echo "🔨 Removendo PV associado: $REDIS_PV"
          kubectl delete pv $REDIS_PV --force --grace-period=0 2>/dev/null || true
        fi
      fi

      # 3. Mata todos os pods Redis para forçar restart
      echo "💀 Matando pods Redis para forçar falha de montagem"
      kubectl delete pods -n $NS -l app.kubernetes.io/name=redis --force --grace-period=0 2>/dev/null || true

      # 4. Força restart do deployment Redis (vai falhar por falta de PVC)
      echo "🔄 Forçando restart do Redis deployment"
      kubectl rollout restart deployment/redis-release -n $NS 2>/dev/null || true

      # 5. Verifica impacto na aplicação useless-box
      echo "🔍 Forçando restart da aplicação useless-box..."
      kubectl rollout restart deployment/useless-box -n $NS 2>/dev/null || true

      echo "✅ Redis completamente quebrado - useless-box deve falhar ao conectar"
      echo "🔍 Para monitorar: kubectl get events -n $NS --sort-by='.lastTimestamp'"
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
