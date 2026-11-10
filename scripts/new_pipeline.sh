#!/bin/bash
# Cria estrutura para um novo pipeline.
# Uso: new_pipeline.sh <nome>

NOME=$1
if [ -z "$NOME" ]; then
    echo "Uso: new_pipeline.sh <nome_do_pipeline>"
    exit 1
fi

PIPE_DIR="$HOME/lab/pipelines/$NOME"
TMPL_DIR="$HOME/lab/templates"

if [ -d "$PIPE_DIR" ]; then
    echo "ERRO: Pipeline '$NOME' já existe em $PIPE_DIR"
    exit 1
fi

mkdir -p "$PIPE_DIR/rules"

cat > "$PIPE_DIR/Snakefile" << SNAKEEOF
# Pipeline: $NOME
# Criado: $(date +%Y-%m-%d)
# ============================================================
import pandas as pd, os

configfile: "config.yaml"

SAMPLES    = pd.read_csv("samples.csv").set_index("sample_id", drop=False)
SAMPLE_IDS = SAMPLES.index.tolist()

RAW       = config["raw_dir"]
PROCESSED = config["processed_dir"]
RESULTS   = config["results_dir"]
LOGS      = config["logs_dir"]
THREADS   = config.get("threads", 4)

include: os.path.expanduser("~/lab/pipelines/$NOME/rules/TODO.smk")

rule all:
    input:
        # TODO: liste os outputs finais esperados
        []
SNAKEEOF

cat > "$PIPE_DIR/rules/TODO.smk" << 'RULEEOF'
# TODO: implemente as rules deste pipeline
# Cada rule deve ter: input, output, log, conda/container, shell/script
# Exemplo de rule:
#
# rule minha_rule:
#     input:  ...
#     output: ...
#     log:    os.path.join(LOGS, "minha_rule/{sample}.log")
#     threads: THREADS
#     conda:  os.path.expanduser("~/lab/software/envs/general")
#     shell:  "..."
RULEEOF

# Cria config template baseado no base_config
cp "$TMPL_DIR/base_config.yaml" "$TMPL_DIR/${NOME}_config.yaml"
sed -i "s|pipeline_type: .*|pipeline_type: \"$NOME\"|" "$TMPL_DIR/${NOME}_config.yaml"

echo ""
echo "=== Pipeline '$NOME' criado ==="
echo ""
echo "Próximos passos:"
echo "  1. Edite o Snakefile:   $PIPE_DIR/Snakefile"
echo "  2. Implemente rules:    $PIPE_DIR/rules/"
echo "  3. Edite o config:      $TMPL_DIR/${NOME}_config.yaml"
echo "  4. Crie env se precisar: ~/lab/software/envs/"
echo "  5. Adicione '$NOME' à lista VALID em ~/lab/scripts/new_project.sh"
