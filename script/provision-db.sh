#!/usr/bin/env bash
#
# provision-db.sh — cria o role e os bancos do caviso-despesas no Postgres 16
# compartilhado deste servidor (container `postgres`, /opt/postgres-stack).
#
# Idempotente: pode rodar quantas vezes quiser, não recria o que já existe.
# Reexecutar também SINCRONIZA a senha do role com o PRODUCTION_PASSWORD atual
# do .env — é assim que se troca a senha depois.
#
# Uso:
#   sudo bash script/provision-db.sh
#
# O que cria:
#   role      despesas            (LOGIN CREATEDB)
#   bancos    despesas_prod, despesas_prod_cache,
#             despesas_prod_queue, despesas_prod_cable
#
# Os quatro bancos vêm de config/database.yml: as chaves cache, queue e cable
# reaproveitam a conexão primária variando só o nome (sufixos _cache, _queue e
# _cable). Um app Rails 8 com Solid Cache/Queue/Cable precisa dos quatro.

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$APP_DIR/.env"
PG_CONTAINER="postgres"
DB_SUFFIXES=("" "_cache" "_queue" "_cable")

erro() { printf 'erro: %s\n' "$*" >&2; exit 1; }
info() { printf '  %s\n' "$*"; }

# Lê uma variável do .env sem `source` — o arquivo tem comentários e valores com
# espaços, e source executaria tudo. Remove aspas envolventes, se houver.
read_env() {
  local value
  value="$(grep -E "^${1}=" "$ENV_FILE" | tail -n 1 | cut -d= -f2- || true)"
  value="${value%\"}"; value="${value#\"}"
  value="${value%\'}"; value="${value#\'}"
  printf '%s' "$value"
}

[ "$(id -u)" -eq 0 ] || erro "rode com sudo: sudo bash script/provision-db.sh"
[ -f "$ENV_FILE" ]      || erro "$ENV_FILE não encontrado"

DB_USER="$(read_env PRODUCTION_USERNAME)"
DB_PASS="$(read_env PRODUCTION_PASSWORD)"
DB_NAME="$(read_env PRODUCTION_DATABASE)"

[ -n "$DB_USER" ] || erro "PRODUCTION_USERNAME está vazio no .env"
[ -n "$DB_NAME" ] || erro "PRODUCTION_DATABASE está vazio no .env"

# Os nomes entram em SQL por interpolação; validar aqui evita surpresa e
# dispensa aspas de identificador espalhadas pelo script.
[[ "$DB_USER" =~ ^[a-z_][a-z0-9_]*$ ]] || erro "PRODUCTION_USERNAME inválido: '$DB_USER' (use apenas a-z, 0-9 e _)"
[[ "$DB_NAME" =~ ^[a-z_][a-z0-9_]*$ ]] || erro "PRODUCTION_DATABASE inválido: '$DB_NAME' (use apenas a-z, 0-9 e _)"

docker inspect -f '{{.State.Running}}' "$PG_CONTAINER" 2>/dev/null | grep -q true \
  || erro "container '$PG_CONTAINER' não está rodando (veja /opt/postgres-stack)"

psql_do() { docker exec -i "$PG_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 "$@"; }

echo "Postgres compartilhado — provisionando o caviso-despesas"
info "role:   $DB_USER"
info "bancos: $(printf '%s ' "${DB_SUFFIXES[@]/#/$DB_NAME}")"
echo

# --- role -------------------------------------------------------------------
if psql_do -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER'" | grep -q 1; then
  info "role $DB_USER já existe — mantido"
else
  psql_do -c "CREATE ROLE $DB_USER LOGIN CREATEDB" >/dev/null
  info "role $DB_USER criado"
fi

# CREATEDB é o que permite ao `db:prepare` do entrypoint criar os bancos que
# faltarem num deploy novo.
psql_do -c "ALTER ROLE $DB_USER CREATEDB" >/dev/null

if [ -n "$DB_PASS" ]; then
  # -v + :'pw' deixa o psql fazer o escape do literal, então senha com aspas ou
  # barra não quebra o comando. Precisa ir por stdin (-f -): com `-c` o psql
  # envia o texto direto ao servidor e NÃO interpola a variável, então o :'pw'
  # chega literal e o servidor responde 'syntax error at or near ":"'.
  printf "ALTER ROLE %s WITH PASSWORD :'pw';\n" "$DB_USER" \
    | psql_do -v pw="$DB_PASS" -f - >/dev/null
  info "senha do role sincronizada com o .env"
else
  printf '  AVISO: PRODUCTION_PASSWORD está vazio no .env — senha do role não foi definida.\n' >&2
  printf '         A conexão local funciona mesmo assim (pg_hba confia em 127.0.0.1),\n' >&2
  printf '         mas o role fica sem senha. Preencha e rode de novo.\n' >&2
fi

# --- bancos -----------------------------------------------------------------
for suffix in "${DB_SUFFIXES[@]}"; do
  db="${DB_NAME}${suffix}"
  if psql_do -tAc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1; then
    info "banco $db já existe — mantido"
  else
    psql_do -c "CREATE DATABASE $db OWNER $DB_USER ENCODING 'UTF8'" >/dev/null
    info "banco $db criado (owner $DB_USER)"
  fi
done

echo
echo "Pronto. O entrypoint do container roda 'db:prepare' e carrega o schema"
echo "dos quatro bancos no primeiro 'docker compose up'."
