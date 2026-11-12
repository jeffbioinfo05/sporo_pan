# sporo_pan

Pangenome and comparative genomics of *Sporothrix brasiliensis* in Brazil.

This repository holds the analytical pipelines, scripts, and supplementary data
for the study of the *S. brasiliensis* pangenome, its population structure, and
candidate genes related to virulence and antifungal resistance.

- Reference genome: *S. brasiliensis* strain 5110 (RefSeq GCF_000820605.1)
- Dataset: 71 Brazilian isolates from four BioProjects
  (PRJNA957313, PRJNA607682, PRJNA836433, PRJNA927289)
- RNA-seq used for annotation: PRJNA1112728
- Archived release: DOI: 10.5281/zenodo.24160864

## Overview

Starting from 79 Illumina datasets, 71 isolates passed quality control and were
analysed together with the reference genome. The pangenome comprises 9,885
orthogroups (7,932 core, 814 shell, 1,139 cloud). Phylogenetic analysis based on
521,106 SNPs and average nucleotide identity delineated nine lineages, with L01
predominant. The study characterises the accessory gene repertoire, candidate
virulence genes, antifungal resistance variants, and genome-wide structural
variation.

## Repository structure

```
ansible/        provisioning for the analysis environment
pipelines/      Snakemake/analysis pipelines (assembly, annotation, pangenome, SNPs)
profiles/       execution profiles
templates/      configuration templates
utils/          helper scripts
scripts/
  structural/   structural variation pipeline (inversions; see its README)
results/
  tables/       supplementary tables (table_S1 ... table_S6) and output data
  figs/         manuscript figures
```

## Main analyses

- Assembly: SPAdes; QC with QUAST and BUSCO (sordariomycetes_odb10)
- Decontamination: Kraken2
- Repeat masking: RepeatModeler + RepeatMasker
- Annotation: BRAKER3
- Orthology and pangenome: OrthoFinder, with absence validation via miniprot
- Variants and lineages: Snippy, single-linkage clustering, Gubbins
- Phylogeny: IQ-TREE (SNP supermatrix and OG supermatrix), gene/site concordance factors
- ANI and species calibration: skani
- Virulence candidates: keyword-based annotation, DeepTMHMM secretion prediction
- Antifungal resistance: itraconazole MIC integration, azole target variants
- Structural variation: RagTag + NUCmer (MUMmer4) + SyRI (see `scripts/structural/`)

## Supplementary tables

- table_S1_isolates.tsv — isolate metadata (host, state, BioProject, lineage, ANI)
- table_S2_functional_class_summary.tsv — COG annotation summary per pangenome class
- table_S3_functional_enrichment.tsv — functional enrichment across classes
- table_S4_resistance_l01_orthogroups.tsv — L01 gene-content association
- table_S5_resistance_l01_snps.tsv — L01 SNP-pattern association
- table_S6_inversions.tsv — clade-associated inversions (coordinates, size, clade, counts)

## Citation

Ramos JV, Rodriguez Martins K, Santos Fava W, Venturini J, Ullmann LS,
Arena Galhardo J. The pangenome of *Sporothrix brasiliensis* in Brazil reveals
an accessory gene repertoire associated with population structure and identifies
candidate genes related to virulence and antifungal resistance. (manuscript in
preparation).

Data and pipelines archived at Zenodo: DOI: 10.5281/zenodo.24160864
