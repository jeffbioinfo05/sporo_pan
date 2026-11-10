#!/bin/bash
# run_pipeline.sh — v2 (com notificação e report automático)
# Uso: run_pipeline.sh [flags extras snakemake]

set -e

if [ ! -f "config.yaml" ]; then
    echo "ERRO: config.yaml não encontrado. Execute no diretório do projeto."
    exit 1
fi

PIPELINE_TYPE=$(python3 -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c['pipeline_type'])")
PROJECT_NAME=$(python3  -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('project_name',''))")
SNAKEFILE="$HOME/lab/pipelines/$PIPELINE_TYPE/Snakefile"

if [ ! -f "$SNAKEFILE" ]; then
    echo "ERRO: Pipeline '$PIPELINE_TYPE' não encontrado em $SNAKEFILE"
    exit 1
fi

echo "========================================"
echo "Pipeline : $PIPELINE_TYPE"
echo "Projeto  : $PROJECT_NAME"
echo "Início   : $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

START_TIME=$(date +%s)

# Executa o pipeline
STATUS="sucesso"
snakemake \
    --snakefile "$SNAKEFILE" \
    --configfile config.yaml \
    --profile    "$HOME/lab/profiles/default" \
    "$@" || STATUS="falhou"

END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))

echo ""
echo "========================================"
echo "Status   : $STATUS"
echo "Duração  : ${ELAPSED} minutos"
echo "========================================"

# Gera relatório HTML do Snakemake (exceto em dry-run)
if [[ ! " $* " =~ " --dry-run " ]] && [[ ! " $* " =~ " -n " ]]; then
    snakemake \
        --snakefile "$SNAKEFILE" \
        --configfile config.yaml \
        --report results/snakemake_report.html \
        2>/dev/null && echo "Relatório: results/snakemake_report.html" || true
fi

# Notificação
notify.sh "$PIPELINE_TYPE" "$STATUS" "$PROJECT_NAME"

# Commita estado final dos configs no git do projeto
if [ "$STATUS" = "sucesso" ]; then
    git add config.yaml samples.csv 2>/dev/null || true
    git commit -m "Pipeline concluído: $PIPELINE_TYPE — $(date '+%Y-%m-%d')" \
        --quiet 2>/dev/null || true
fi

[ "$STATUS" = "falhou" ] && exit 1
exit 0
