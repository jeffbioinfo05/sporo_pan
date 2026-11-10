#!/bin/bash
# Cria um novo projeto com estrutura padronizada.
# Uso: new_project.sh <pipeline_type> <nome>
# Exemplo: new_project.sh assembly_prokaryote 2026-05_azospirillum

TIPO=$1
NOME=$2

VALID="assembly_prokaryote assembly_eukaryote pangenome_prokaryote pangenome_eukaryote metabarcoding sanger rnaseq metagenomics"

if [ -z "$TIPO" ] || [ -z "$NOME" ]; then
    echo "Uso: new_project.sh <tipo> <nome>"
    echo "Tipos: $VALID"
    exit 1
fi

if ! echo "$VALID" | grep -qw "$TIPO"; then
    echo "ERRO: Tipo '$TIPO' inválido. Use: $VALID"
    exit 1
fi

DATE_PREFIX=$(date +%Y-%m)
[[ ! "$NOME" =~ ^[0-9]{4}-[0-9]{2} ]] && NOME="${DATE_PREFIX}_${NOME}"

PROJ_SSD="$HOME/lab/projects/$NOME"
PROJ_HDD="/mnt/bioinfo/projects/$NOME"

if [ -d "$PROJ_SSD" ]; then
    echo "ERRO: Projeto '$NOME' já existe. Abortando."
    exit 1
fi

echo "=== Criando projeto: $NOME ($TIPO) ==="

mkdir -p "$PROJ_SSD"
mkdir -p "$PROJ_HDD"/{raw,processed,results,logs,tmp}

for d in raw processed results logs tmp; do
    ln -s "$PROJ_HDD/$d" "$PROJ_SSD/$d"
done

TMPL="$HOME/lab/templates"
cp "$TMPL/${TIPO}_config.yaml" "$PROJ_SSD/config.yaml"

# Seleciona samples.csv adequado para o tipo
case "$TIPO" in
    sanger)        SCSV="samples_sanger.csv"       ;;
    metabarcoding) SCSV="samples_metabarcoding.csv" ;;
    *)             SCSV="samples_generic.csv"       ;;
esac
cp "$TMPL/samples/$SCSV" "$PROJ_SSD/samples.csv"

# Substitui placeholders
for f in "$PROJ_SSD/config.yaml" "$PROJ_SSD/samples.csv"; do
    sed -i "s|__PROJ_NAME__|$NOME|g"    "$f"
    sed -i "s|__PROJ_DIR__|$PROJ_HDD|g" "$f"
    sed -i "s|__DATE__|$DATE_PREFIX|g"  "$f"
    sed -i "s|__PIPELINE__|$TIPO|g"     "$f"
done

cd "$PROJ_SSD"
git init --quiet
cat > .gitignore << 'GIT'
raw/
processed/
results/
logs/
tmp/
*.fastq
*.fq
*.fastq.gz
*.fq.gz
*.bam
*.sam
*.cram
*.vcf
*.h5
GIT
git add config.yaml samples.csv .gitignore
git commit -m "Inicialização: $NOME ($TIPO)" --quiet

echo ""
echo "=== PROJETO CRIADO ==="
echo "SSD (configs): $PROJ_SSD"
echo "HD  (dados):   $PROJ_HDD"
echo ""
echo "Próximos passos:"
echo "  1. nano $PROJ_SSD/samples.csv"
echo "  2. nano $PROJ_SSD/config.yaml"
echo "  3. Coloque os dados em: $PROJ_HDD/raw/"
echo "  4. cd $PROJ_SSD && run_pipeline.sh --dry-run"
