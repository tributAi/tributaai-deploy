# ERR_SSL_PROTOCOL_ERROR em tribxai.com

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

## 5. Conferir DNS

O domínio **tribxai.com** (e **www**) deve apontar para o IP da VPS (registro A). Se apontar para outro IP ou estiver em propagação, o Let's Encrypt não consegue validar e o certificado não é emitido.

```bash
dig +short tribxai.com
dig +short www.tribxai.com
```

O IP deve ser o da sua VPS (ex.: 2.57.91.91).

## 6. Se ainda falhar

Envie a saída de:

```bash
docker logs tributaai-traefik 2>&1 | grep -iE 'acme|certificate|error|tribxai' | tail -50
```

Com isso dá para ver se o Let's Encrypt está recusando, se o domínio não resolve ou se há outro erro de configuração.
