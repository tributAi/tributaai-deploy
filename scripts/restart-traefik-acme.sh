#!/usr/bin/env bash
# Reinicia o Traefik e mostra logs relacionados a ACME/certificado.
# Executar no servidor: cd /opt/tributaai && bash scripts/restart-traefik-acme.sh

set -e
cd "${REMOTE_DIR:-/opt/tributaai}"

echo "========== Reiniciando Traefik =========="
docker compose -f docker-compose.production.yml up -d traefik
echo ""
echo "Aguardando 5s..."
sleep 5
echo "========== Últimas linhas (ACME / certificate / error) =========="
docker logs tributaai-traefik 2>&1 | grep -iE 'acme|certificate|error|obtain|tribxai' | tail -30 || true
echo ""
echo "========== Últimas 15 linhas do Traefik =========="
docker logs tributaai-traefik 2>&1 | tail -15
