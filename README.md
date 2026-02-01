# tributaai-deploy

Repositório de deploy e infraestrutura TributAI. Contém apenas o Docker Compose de produção e variáveis de ambiente de exemplo.

## Conteúdo

- `docker-compose.production.yml` — stack completo (Traefik, Postgres, Redis, MinIO, MongoDB e todos os serviços TributAI)
- `.env.example` — variáveis de ambiente; copiar para `.env` e preencher

## Uso no servidor

1. Clonar este repositório em `/opt/tributaai` (ou outro diretório):

   ```bash
   git clone https://github.com/tributAi/tributaai-deploy.git /opt/tributaai
   cd /opt/tributaai
   ```

2. Copiar e configurar o `.env`:

   ```bash
   cp .env.example .env
   # Editar .env com senhas e chaves reais
   ```

3. Subir o stack:

   ```bash
   docker compose -f docker-compose.production.yml pull
   docker compose -f docker-compose.production.yml up -d
   ```

Os workflows de cada serviço (tributaai-llm-service, tributaai-core-api, etc.) fazem build e push das imagens para o GHCR e depois SSH para este diretório para executar `docker compose pull && up -d`. Este repo não contém código das aplicações — apenas a definição do stack.