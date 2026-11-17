

#!/usr/bin/env bash
set -e

echo "=== Installation des dépendances ==="

apt-get update
apt-get install -y curl

echo "=== Installation de K3s ==="

if ! command -v k3s >/dev/null 2>&1; then
    curl -sfL https://get.k3s.io | \
        INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644" sh -
else
    systemctl enable --now k3s
fi

echo "Attente du démarrage de K3s..."

echo "Attente de l'enregistrement du node Kubernetes..."

MAX_ATTEMPTS=36
ATTEMPT=0

until kubectl get nodes >/dev/null 2>&1 && \
      [ "$(kubectl get nodes --no-headers 2>/dev/null | wc -l)" -gt 0 ]; do

    ATTEMPT=$((ATTEMPT + 1))

    if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
        echo "Erreur : aucun node Kubernetes détecté après 3 minutes."
        exit 1
    fi

    sleep 5
done

kubectl wait --for=condition=Ready node --all --timeout=180s

echo "=== Déploiement des applications ==="

kubectl apply -f /vagrant/confs/

echo "=== Vérification des déploiements ==="

kubectl rollout status deployment/app1 --timeout=180s
kubectl rollout status deployment/app2 --timeout=180s
kubectl rollout status deployment/app3 --timeout=180s

echo "=== État final du cluster ==="

kubectl get nodes
kubectl get pods
kubectl get services
kubectl get ingress

echo "=== Setup terminé ! ==="
