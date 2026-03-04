# Transferir sophia-web para a org TributAI

## No GitHub (conta que é dona do repositório)

1. Abra o repositório **sophia-web** (ex.: `https://github.com/eeduardoliveira/sophia-web`).

2. Vá em **Settings** (engrenagem).

3. Role até o final da página, na seção **Danger Zone**.

4. Clique em **Transfer ownership**.

5. No campo **New owner**, digite: **TributAI** (nome da organização).

6. Digite o nome do repositório para confirmar: **sophia-web**.

7. Leia o aviso (issues, PRs, stars e referências são mantidos; webhooks e deploy keys são removidos).

8. Clique em **I understand, transfer this repository**.

## Requisitos

- Sua conta precisa ser **owner** da organização TributAI, ou a org precisa permitir que membros transfiram repositórios para ela.
- O repositório não pode ter issues/PRs em lock.
- Depois da transferência, o clone URL passa a ser `https://github.com/TributAI/sophia-web` e a imagem Docker fica **ghcr.io/tributai/sophia-web** (já configurada no `docker-compose.production.yml`).

## Depois da transferência

1. Atualize o **remote** no clone local (se ainda apontar para o repo antigo):
   ```bash
   cd /caminho/para/sophia-web
   git remote set-url origin https://github.com/TributAI/sophia-web.git
   ```

2. Um push em **main** no repo TributAI/sophia-web vai disparar o workflow e publicar `ghcr.io/tributai/sophia-web:latest`. A partir daí o deploy conseguirá fazer pull dessa imagem.
