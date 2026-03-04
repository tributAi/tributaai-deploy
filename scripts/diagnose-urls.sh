#!/usr/bin/env bash
# Diagnóstico: por que as URLs tribxai.com não funcionam?
# Executar no servidor: bash scripts/diagnose-urls.sh
# Ou via SSH: ssh user@host 'cd /opt/tributaai && bash -s' < scripts/diagnose-urls.sh

set -e
cd "${REMOTE_DIR:-/opt/tributaai}"

echo "========== 1. Portas 80 e 443 =========="
ss -tlnp 2>/dev/null | grep -E ':80 |:443 ' || true
echo ""

echo "========== 2. Containers (compose production) =========="
docker compose -f docker-compose.production.yml ps 2>/dev/null || true
echo ""

echo "========== 3. Traefik está no ar? =========="
docker ps --filter name=traefik --format '{{.Names}} {{.Status}}' 2>/dev/null || true
echo ""

echo "========== 4. Últimas linhas do Traefik (ACME/erros) =========="
docker logs tributaai-traefik 2>&1 | tail -40
echo ""

echo "========== 5. Teste HTTP local (porta 80) =========="
curl -sI -m 5 http://127.0.0.1:80/ -H "Host: tribxai.com" 2>&1 | head -15
echo ""

echo "========== 6. Landing e Frontend rodando? =========="
docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null | grep -E 'landing|frontend|sophia' || true
