"""
Agrega métricas do pipeline e gera Excel.
Adaptar conforme as entradas disponíveis em snakemake.input
"""
import pandas as pd, os, sys, json
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils.dataframe import dataframe_to_rows

# TODO: coletar métricas específicas deste pipeline
df = pd.DataFrame({"status": ["Implementar coleta de métricas para aggregate_pangenome"]})

wb = Workbook()
ws = wb.active
ws.title = "Metrics"
for row in dataframe_to_rows(df, index=False, header=True):
    ws.append(row)
wb.save(snakemake.output[0])
print(f"Planilha gerada: {snakemake.output[0]}", file=sys.stderr)
