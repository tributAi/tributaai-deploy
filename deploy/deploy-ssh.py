#!/usr/bin/env python3
"""
Script de Deploy via SSH Direto (melhorado)
Faz deploy do docker-compose.yml diretamente no servidor via SSH
Usa paramiko para conexão SSH mais robusta
"""

import os
import sys
import json
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("❌ Erro: paramiko não instalado")
    print("   Execute: pip install paramiko")
    sys.exit(1)

# Configurações
SSH_HOST = os.getenv("SSH_HOST", "72.62.29.57")
SSH_USER = os.getenv("SSH_USER", "root")
SSH_KEY_PATH = os.getenv("SSH_KEY_PATH", "")
SSH_PASSWORD = os.getenv("SSH_PASSWORD", "")
SSH_PORT = int(os.getenv("SSH_PORT", "22"))
REMOTE_DIR = os.getenv("REMOTE_DIR", "/opt/tributaai")
GHCR_USERNAME = os.getenv("GHCR_USERNAME", "TributAI")
GHCR_TOKEN = os.getenv("GHCR_TOKEN", "")

# Arquivos locais
# Usar production para Traefik (80/443) e URLs por domínio
COMPOSE_FILE = os.getenv("COMPOSE_FILE", "docker-compose.production.yml")
ENV_FILE = ".env.production"


class SSHDeployer:
    """Classe para gerenciar deploy via SSH"""
    
    def __init__(self):
        self.ssh = None
        self.sftp = None
        
    def connect(self):
        """Conecta ao servidor via SSH"""
        print(f"🔌 Conectando a {SSH_USER}@{SSH_HOST}:{SSH_PORT}...")
        
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        try:
            # Expandir ~ no caminho da chave
            key_path = SSH_KEY_PATH
            if key_path:
                key_path = os.path.expanduser(key_path)
            
            if key_path and os.path.exists(key_path):
                # Autenticação via chave
                self.ssh.connect(
                    SSH_HOST,
                    port=SSH_PORT,
                    username=SSH_USER,
                    key_filename=key_path,
                    timeout=10
                )
            elif SSH_PASSWORD:
                # Autenticação via senha
                self.ssh.connect(
                    SSH_HOST,
                    port=SSH_PORT,
                    username=SSH_USER,
                    password=SSH_PASSWORD,
                    timeout=10
                )
            else:
                print("❌ Erro: SSH_KEY_PATH ou SSH_PASSWORD deve ser configurado")
                sys.exit(1)
            
            print("✅ Conectado com sucesso!")
            
            # Criar SFTP para transferência de arquivos
            self.sftp = self.ssh.open_sftp()
            
        except Exception as e:
            print(f"❌ Erro ao conectar: {e}")
            sys.exit(1)
    
    def execute(self, command: str, check: bool = True) -> tuple[str, str, int]:
        """Executa comando remoto"""
        print(f"🔧 Executando: {command}")
        
        stdin, stdout, stderr = self.ssh.exec_command(command)
        exit_status = stdout.channel.recv_exit_status()
        
        stdout_text = stdout.read().decode('utf-8')
        stderr_text = stderr.read().decode('utf-8')
        
        if stdout_text:
            print(stdout_text)
        if stderr_text:
            print(stderr_text, file=sys.stderr)
        
        if check and exit_status != 0:
            print(f"❌ Comando falhou com exit code: {exit_status}")
            sys.exit(1)
        
        return stdout_text, stderr_text, exit_status
    
    def upload_file(self, local_path: str, remote_path: str):
        """Faz upload de arquivo"""
        if not os.path.exists(local_path):
            print(f"⚠️  Arquivo não encontrado: {local_path}")
            return False
        
        print(f"📤 Enviando {local_path} → {remote_path}")
        
        try:
            # Criar diretório remoto se não existir
            remote_dir = os.path.dirname(remote_path)
            self.execute(f"mkdir -p {remote_dir}", check=False)
            
            # Fazer upload
            self.sftp.put(local_path, remote_path)
            print("✅ Arquivo enviado com sucesso!")
            return True
        except Exception as e:
            print(f"❌ Erro ao enviar arquivo: {e}")
            return False
    
    def create_env_file(self, env_vars: dict):
        """Cria arquivo .env no servidor"""
        print("📝 Criando arquivo .env no servidor...")
        
        env_content = "\n".join([f"{k}={v}" for k, v in env_vars.items() if v])
        env_content += "\n"
        
        # Criar arquivo temporário local
        temp_env = "/tmp/tributaai.env"
        with open(temp_env, "w") as f:
            f.write(env_content)
        
        # Upload
        remote_env = f"{REMOTE_DIR}/.env"
        if self.upload_file(temp_env, remote_env):
            # Limpar arquivo temporário
            os.remove(temp_env)
            return True
        return False
    
    def upload_directory(self, local_dir: str, remote_dir: str):
        """Faz upload recursivo de um diretório"""
        if not os.path.isdir(local_dir):
            print(f"⚠️  Diretório não encontrado: {local_dir}")
            return False

        self.execute(f"mkdir -p {remote_dir}", check=False)

        for entry in sorted(os.listdir(local_dir)):
            local_path = os.path.join(local_dir, entry)
            remote_path = f"{remote_dir}/{entry}"
            if os.path.isdir(local_path):
                self.upload_directory(local_path, remote_path)
            else:
                self.upload_file(local_path, remote_path)
        return True

    def run_migrations(self):
        """Aplica migrações pendentes no Postgres (idempotentes)"""
        print("\n📦 Aplicando migrações no banco de dados...")

        migrations_dir = "infra/postgres/migrations"
        remote_migrations = f"{REMOTE_DIR}/db/migrations"

        if not os.path.isdir(migrations_dir):
            print("⚠️  Pasta de migrações não encontrada, pulando.")
            return

        self.upload_directory(migrations_dir, remote_migrations)

        print("⏳ Aguardando Postgres ficar saudável...")
        self.execute(
            f"cd {REMOTE_DIR} && timeout 60 bash -c '"
            "until docker compose -f docker-compose.production.yml exec -T postgres pg_isready -U tributaai; "
            "do sleep 2; done'",
            check=True,
        )

        migration_files = sorted(Path(migrations_dir).glob("*.sql"))
        for mf in migration_files:
            print(f"   ▶ {mf.name}")
            self.execute(
                f"docker exec -i tributaai-postgres psql -U tributaai -d tributaai "
                f"< {remote_migrations}/{mf.name}",
                check=False,
            )

        print("✅ Migrações aplicadas.")

    def deploy(self):
        """Executa o deploy completo"""
        print("🚀 Iniciando deploy...")
        print("=" * 60)
        
        # 1. Criar diretório remoto
        print("\n📁 Criando diretório remoto...")
        self.execute(f"mkdir -p {REMOTE_DIR}")
        
        # 2. Verificar Docker
        print("\n🐳 Verificando Docker...")
        self.execute("docker --version")
        self.execute("docker compose version")
        
        # 3. Upload compose (production = Traefik + domínios)
        print(f"\n📤 Enviando {COMPOSE_FILE}...")
        if not os.path.exists(COMPOSE_FILE):
            print(f"❌ Erro: {COMPOSE_FILE} não encontrado")
            sys.exit(1)
        self.upload_file(COMPOSE_FILE, f"{REMOTE_DIR}/docker-compose.production.yml")
        diagnose_script = "scripts/diagnose-urls.sh"
        if os.path.exists(diagnose_script):
            self.upload_file(diagnose_script, f"{REMOTE_DIR}/scripts/diagnose-urls.sh")
            self.execute(f"chmod +x {REMOTE_DIR}/scripts/diagnose-urls.sh", check=False)
        else:
            print(f"⚠️  {diagnose_script} não encontrado; diagnóstico no servidor não disponível.")
        
        # 4. Criar arquivo .env
        print("\n📝 Configurando variáveis de ambiente...")
        base_url = f"http://{SSH_HOST}"
        env_vars = {
            "POSTGRES_PASSWORD": os.getenv("POSTGRES_PASSWORD", "tributaai_dev"),
            "MINIO_ROOT_USER": os.getenv("MINIO_ROOT_USER", "minioadmin"),
            "MINIO_ROOT_PASSWORD": os.getenv("MINIO_ROOT_PASSWORD", "minioadmin"),
            "MINIO_ACCESS_KEY": os.getenv("MINIO_ACCESS_KEY", os.getenv("MINIO_ROOT_USER", "minioadmin")),
            "MINIO_SECRET_KEY": os.getenv("MINIO_SECRET_KEY", os.getenv("MINIO_ROOT_PASSWORD", "minioadmin")),
            "ADMIN_API_KEY": os.getenv("ADMIN_API_KEY", "dev-admin-key"),
            "LLM_API_KEY": os.getenv("LLM_API_KEY", ""),
            "LLM_BASE_URL": os.getenv("LLM_BASE_URL", "https://api.openai.com/v1"),
            "LLM_PROVIDER": os.getenv("LLM_PROVIDER", "openai"),
            "NEXT_PUBLIC_API_BASE_URL": os.getenv("NEXT_PUBLIC_API_BASE_URL", f"{base_url}:8080"),
            "NEXT_PUBLIC_REPORT_SERVICE_URL": os.getenv("NEXT_PUBLIC_REPORT_SERVICE_URL", f"{base_url}:8086"),
            "NEXT_PUBLIC_ADMIN_API_BASE_URL": os.getenv("NEXT_PUBLIC_ADMIN_API_BASE_URL", f"{base_url}:8081"),
            "NEXT_PUBLIC_TREATY_IMPORT_URL": os.getenv("NEXT_PUBLIC_TREATY_IMPORT_URL", f"{base_url}:8087"),
            "LETSENCRYPT_EMAIL": os.getenv("LETSENCRYPT_EMAIL", "admin@syphertech.com.br"),
        }
        self.create_env_file(env_vars)
        
        # 5. Login no GHCR
        print("\n🔐 Fazendo login no GHCR...")
        if GHCR_TOKEN:
            login_cmd = f"echo '{GHCR_TOKEN}' | docker login ghcr.io -u {GHCR_USERNAME} --password-stdin"
            self.execute(login_cmd)
        else:
            print("⚠️  GHCR_TOKEN não configurado - pulando login")
            print("   Certifique-se de que o login já foi feito no servidor")
        
        # 6. Pull das imagens
        print("\n📥 Fazendo pull das imagens...")
        out, err, code = self.execute(
            f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml pull 2>&1",
            check=False,
        )
        if code != 0:
            print("\n" + "=" * 60, file=sys.stderr)
            print("❌ docker compose pull FALHOU", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            print("Saída completa do comando (stdout + stderr):", file=sys.stderr)
            print(out or "(vazio)", file=sys.stderr)
            if err and err != out:
                print(err, file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            print(
                "Erros comuns: image not found / unauthorized → verifique se a imagem existe no GHCR e se o token tem permissão. "
                "sophia-web (ghcr.io/eeduardoliveira/sophia-web) pode precisar de repositório público ou token com acesso.",
                file=sys.stderr,
            )
            sys.exit(1)
        
        # 7. Deploy (Traefik em 80/443 + apps)
        print("\n🚀 Fazendo deploy...")
        self.execute(f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml stop traefik 2>/dev/null || true", check=False)
        self.execute(f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml rm -f traefik 2>/dev/null || true", check=False)
        self.execute(f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml up -d --remove-orphans")

        # 7.5. Aplicar migrações e seeds no banco de dados
        self.run_migrations()
        
        # 7.6. Reiniciar Traefik para garantir detecção dos containers frontend/admin-portal
        print("\n🔄 Reiniciando Traefik para detectar containers...")
        self.execute(f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml restart traefik")
        
        # 8. Verificar status
        print("\n📊 Verificando status dos containers...")
        self.execute(f"cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml ps")
        
        print("\n" + "=" * 60)
        print("✅ Deploy concluído com sucesso!")
        print()
        print("📝 Comandos úteis:")
        print(f"   ssh {SSH_USER}@{SSH_HOST} 'cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml logs -f'")
        print(f"   ssh {SSH_USER}@{SSH_HOST} 'cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml ps'")
        print(f"   ssh {SSH_USER}@{SSH_HOST} 'cd {REMOTE_DIR} && docker compose -f docker-compose.production.yml restart <service>'")
        print()
        print("🌐 URLs (após propagação SSL):")
        print("   https://tribxai.com")
        print("   https://admin.tribxai.com")
        print("   https://sophia.tribxai.com")
        print("   https://api.tribxai.com")
    
    def close(self):
        """Fecha conexões"""
        if self.sftp:
            self.sftp.close()
        if self.ssh:
            self.ssh.close()


def main():
    """Função principal"""
    deployer = SSHDeployer()
    
    try:
        deployer.connect()
        deployer.deploy()
    except KeyboardInterrupt:
        print("\n⚠️  Deploy interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erro durante deploy: {e}")
        sys.exit(1)
    finally:
        deployer.close()


if __name__ == "__main__":
    main()
