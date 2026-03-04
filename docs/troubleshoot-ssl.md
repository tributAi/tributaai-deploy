# URLs tribxai.com não funcionam / ERR_SSL_PROTOCOL_ERROR

## Checklist rápido (ordem sugerida)

1. **DNS** — tribxai.com e subdomínios devem apontar para o IP da VPS (registros A).
2. **Firewall** — portas 80 e 443 abertas na VPS (e no painel da Hostinger, se houver).
3. **Deploy** — pipeline deve ter enviado o `docker-compose.production.yml` atualizado e feito `pull` + `up -d` sem falha.
4. **Certificado** — Let's Encrypt precisa conseguir validar via HTTP (porta 80); se falhar, HTTPS não sobe.

Quando as URLs não funcionam, consulte a saída do passo **"Diagnose URLs (portas, Traefik, HTTP)"** na última run do workflow de deploy (Actions do repo tributaai-deploy). Esse passo não falha o job (`continue-on-error: true`); use a saída para ver portas 80/443, logs do Traefik e o resultado do curl local.

---

## ERR_SSL_PROTOCOL_ERROR

Quando o navegador mostra "sent an invalid response" / ERR_SSL_PROTOCOL_ERROR, em geral o certificado Let's Encrypt ainda não foi emitido ou a porta 443 não está acessível.

## 1. Testar HTTP (porta 80)

No navegador: **http://tribxai.com** (sem S).

- Se abrir e redirecionar para HTTPS e então falhar: o problema é só no certificado HTTPS.
- Se não abrir: pode ser DNS, firewall ou Traefik não está recebendo na 80.

## 2. Na VPS: verificar portas e Traefik

```bash
# Portas 80 e 443 em uso
ss -tlnp | grep -E ':80|:443'

# Logs do Traefik (certificado / ACME)
docker logs tributaai-traefik 2>&1 | tail -100
```

Procure por erros tipo: `Unable to obtain certificate`, `acme`, `error`, `tribxai.com`.

## 3. Firewall: liberar 80 e 443

Se o VPS tiver firewall (ufw, iptables, ou painel Hostinger), libere:

- **80** (HTTP – redirect e desafio ACME)
- **443** (HTTPS – TLS-ALPN para Let's Encrypt)

Exemplo com ufw:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
sudo ufw status
```

## 4. Forçar nova tentativa de certificado

Parar e subir de novo o Traefik para ele tentar emitir o certificado de novo:

```bash
cd /opt/tributaai
docker compose -f docker-compose.production.yml restart traefik
```

Aguarde 1–2 minutos e acesse de novo **https://tribxai.com**.

## 5. Conferir DNS (obrigatório)

Todos estes hostnames devem resolver para o **mesmo IP da VPS** (registro A). No painel DNS (ex.: Hostinger), crie:

| Tipo | Nome    | Valor (IP da VPS) |
|------|--------|-------------------|
| A    | @      | IP da VPS         |
| A    | www    | IP da VPS         |
| A    | app    | IP da VPS         |
| A    | admin  | IP da VPS         |
| A    | sophia | IP da VPS         |
| A    | api    | IP da VPS         |
| A    | admin-api | IP da VPS      |
| A    | reports   | IP da VPS      |
| A    | treaty    | IP da VPS      |

Testar no terminal:

```bash
dig +short tribxai.com
dig +short www.tribxai.com
dig +short app.tribxai.com
dig +short api.tribxai.com
```

Todos devem retornar o mesmo IP. Propagação pode levar até 24–48 h.

## 6. Diagnóstico completo no servidor

O deploy envia `scripts/diagnose-urls.sh` para o servidor. No servidor (SSH em `/opt/tributaai`):

```bash
cd /opt/tributaai
bash scripts/diagnose-urls.sh
```

Se o script não existir (deploy antigo), use os comandos diretos:

```bash
ss -tlnp | grep -E ':80|:443'
docker compose -f docker-compose.production.yml ps
docker logs tributaai-traefik 2>&1 | tail -50
curl -sI -m 5 http://127.0.0.1:80/ -H "Host: tribxai.com" | head -15
```

- Se **curl** devolver HTTP 200 ou 302 no servidor mas o **navegador** falhar: o problema é **DNS** (domínio não aponta para este servidor) ou **firewall** (80/443 bloqueados externamente).
- Se **curl** falhar no servidor: Traefik ou os backends (landing/frontend) não estão a responder; use os logs acima.

## 7. Imagem Sophia (sophia-web no compose)

O serviço `sophia-web` usa `image: ghcr.io/tributai/sophia:latest`. O nome da imagem no GHCR segue o nome do repositório (ex.: repo `sophia` → `ghcr.io/tributai/sophia`; repo `sophia-web` → `ghcr.io/tributai/sophia-web`). Se o `compose pull` falhar com "sophia" not found, confirme no GitHub Container Registry o nome exato da imagem e alinhe o `image:` em `docker-compose.production.yml` (serviço `sophia-web`).

## 8. LETSENCRYPT_EMAIL

O Traefik usa `LETSENCRYPT_EMAIL` para o desafio ACME (Let's Encrypt). Configure em GitHub (repo tributaai-deploy): **Settings → Secrets and variables → Actions** — crie a variável `LETSENCRYPT_EMAIL` ou o secret `LETSENCRYPT_EMAIL` com um email válido. O deploy script usa esse valor ao criar o `.env` no servidor; se não estiver definido, usa um valor por defeito (ver deploy-ssh.py).

## 9. Se ainda falhar

Envie a saída de:

```bash
docker logs tributaai-traefik 2>&1 | grep -iE 'acme|certificate|error|tribxai' | tail -50
```

Com isso dá para ver se o Let's Encrypt está recusando, se o domínio não resolve ou se há outro erro de configuração.
