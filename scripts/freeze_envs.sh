#!/bin/bash
# Exporta estado exato de todos os ambientes conda para reprodução futura.
# Os arquivos gerados garantem reprodução byte a byte (com conda-lock).

ENV_DIR="$HOME/lab/software/envs"
FREEZE_DIR="$HOME/lab/envs_frozen"
DATE=$(date +%Y-%m-%d)

mkdir -p "$FREEZE_DIR"

echo "=== Exportando ambientes conda: $DATE ==="

for env_path in "$ENV_DIR"/*/; do
    env_name=$(basename "$env_path")
    out="$FREEZE_DIR/${env_name}_${DATE}.yml"

    if [ -d "$env_path" ]; then
        echo "  Exportando: $env_name"
        conda env export -p "$env_path" --no-builds > "$out" 2>/dev/null && \
            echo "    ok -> $out" || \
            echo "    falhou: $env_name"
    fi
done

echo ""
echo "=== Exportação concluída ==="
echo "Arquivos em: $FREEZE_DIR"
echo ""
echo "Para restaurar um ambiente:"
echo "  mamba env create -f $FREEZE_DIR/<nome>_<data>.yml --prefix $ENV_DIR/<nome>"

# Commita no git do lab
cd "$HOME/lab"
git add envs_frozen/
git commit -m "freeze envs: $DATE" --quiet 2>/dev/null && \
    echo "Commitado no git do lab." || true
