#!/bin/bash
# ============================================================
# NOTIFICAÇÃO DE FIM DE PIPELINE
# Suporta: ntfy.sh (padrão) | Telegram | email
# Uso: notify.sh "assembly_prokaryote" "sucesso" "2026-05_azospirillum"
# ============================================================

PIPELINE="$1"
STATUS="$2"
PROJECT="$3"

# ── Configure aqui ────────────────────────────────────────────
NOTIFY_METHOD="ntfy"         # ntfy | telegram | email | none
NTFY_CHANNEL="lab-bioinfo-$(whoami)"   # canal único; mude para algo pessoal
NTFY_SERVER="https://ntfy.sh"          # ou seu servidor self-hosted
TELEGRAM_TOKEN=""                       # token do bot (se usar telegram)
TELEGRAM_CHAT_ID=""                     # chat_id do seu usuário
EMAIL_TO=""                             # email destino (se usar email)
# ─────────────────────────────────────────────────────────────

HOSTNAME_PC=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

if [ "$STATUS" = "sucesso" ]; then
    EMOJI="✅"
    PRIORITY="default"
else
    EMOJI="❌"
    PRIORITY="high"
fi

TITLE="${EMOJI} Pipeline ${STATUS}: ${PIPELINE}"
MESSAGE="Projeto: ${PROJECT}\nMáquina: ${HOSTNAME_PC}\nHora: ${TIMESTAMP}"

case "$NOTIFY_METHOD" in
    ntfy)
        curl -s \
            -H "Title: ${TITLE}" \
            -H "Priority: ${PRIORITY}" \
            -H "Tags: dna,computer" \
            -d "$(echo -e $MESSAGE)" \
            "${NTFY_SERVER}/${NTFY_CHANNEL}" > /dev/null
        ;;
    telegram)
        [ -n "$TELEGRAM_TOKEN" ] && \
        curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${TITLE}%0A$(echo -e $MESSAGE)" > /dev/null
        ;;
    email)
        [ -n "$EMAIL_TO" ] && \
        echo -e "Subject: ${TITLE}\n\n$(echo -e $MESSAGE)" | sendmail "$EMAIL_TO"
        ;;
    none)
        ;;
esac

# Sempre loga localmente também
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $TITLE — $PROJECT" >> "$HOME/lab/pipeline_history.log"
