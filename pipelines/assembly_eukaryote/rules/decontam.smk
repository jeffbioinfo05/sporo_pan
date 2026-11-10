def get_hosts():
    return config["decontam"].get("hosts", [])

if config["decontam"]["run"] and len(get_hosts()) > 0:

    rule decontam:
        input:
            r1 = os.path.join(PROC, "trimmed/{sample}_R1.fastq.gz"),
            r2 = os.path.join(PROC, "trimmed/{sample}_R2.fastq.gz"),
        output:
            r1     = os.path.join(PROC, "decontam/{sample}_R1.fastq.gz"),
            r2     = os.path.join(PROC, "decontam/{sample}_R2.fastq.gz"),
            report = os.path.join(RESULTS, "qc/decontam/{sample}_decontam_report.tsv"),
        params:
            hosts   = get_hosts(),
            tmp_dir = os.path.join(TMP, "decontam/{sample}"),
            bindir  = os.path.expanduser("~/lab/software/envs/general/bin"),
        log:     os.path.join(LOGS, "decontam/{sample}.log")
        threads: THREADS_H
        conda:   os.path.expanduser("~/lab/software/envs/general")
        run:
            import subprocess, os

            env = os.environ.copy()
            env["PATH"] = params.bindir + ":" + env.get("PATH", "")

            os.makedirs(params.tmp_dir, exist_ok=True)
            os.makedirs(os.path.dirname(output.r1), exist_ok=True)
            os.makedirs(os.path.dirname(output.report), exist_ok=True)

            def count_reads(fastq_gz):
                result = subprocess.run(
                    f"zcat {fastq_gz} | wc -l",
                    shell=True, capture_output=True, text=True, env=env)
                return int(result.stdout.strip()) // 4

            current_r1 = input.r1
            current_r2 = input.r2

            initial = count_reads(current_r1)
            report_rows = [
                ("sample", "step", "reads", "removed", "removed_pct"),
                (wildcards.sample, "raw", initial, 0, "0.00")
            ]
            prev = initial

            for i, host_ref in enumerate(params.hosts):
                host_name = os.path.basename(host_ref)
                for ext in [".fa", ".fna", ".fasta", ".gz"]:
                    host_name = host_name.replace(ext, "")

                out_r1 = os.path.join(params.tmp_dir, f"step{i+1}_R1.fastq.gz")
                out_r2 = os.path.join(params.tmp_dir, f"step{i+1}_R2.fastq.gz")
                bam    = os.path.join(params.tmp_dir, f"step{i+1}_host.bam")

                with open(log[0], "a") as logf:
                    logf.write(f"\n=== Removendo hospedeiro: {host_name} ===\n")

                cmd = (
                    f"minimap2 -ax sr -t {threads} {host_ref} "
                    f"{current_r1} {current_r2} 2>>{log[0]} | "
                    f"samtools view -f 12 -F 256 -b -o {bam} 2>>{log[0]} && "
                    f"samtools sort -n -@ {threads} {bam} 2>>{log[0]} | "
                    f"samtools fastq "
                    f"-1 {out_r1} -2 {out_r2} "
                    f"-0 /dev/null -s /dev/null 2>>{log[0]} && "
                    f"rm -f {bam}"   # remove BAM imediatamente após uso
                )
                subprocess.run(cmd, shell=True, check=True, env=env)

                # Remove FASTQs do passo anterior para liberar espaço
                if i > 0:
                    prev_r1 = os.path.join(params.tmp_dir, f"step{i}_R1.fastq.gz")
                    prev_r2 = os.path.join(params.tmp_dir, f"step{i}_R2.fastq.gz")
                    for f in [prev_r1, prev_r2]:
                        if os.path.exists(f): os.remove(f)

                curr = count_reads(out_r1)
                removed = prev - curr
                pct = f"{removed / prev * 100:.2f}" if prev > 0 else "0.00"
                report_rows.append((wildcards.sample, host_name, curr, removed, pct))

                current_r1 = out_r1
                current_r2 = out_r2
                prev = curr

            subprocess.run(f"cp {current_r1} {output.r1}", shell=True, check=True, env=env)
            subprocess.run(f"cp {current_r2} {output.r2}", shell=True, check=True, env=env)

            # Remove último step intermediário e os trimmed de input
            for f in [current_r1, current_r2]:
                if os.path.exists(f) and f != output.r1 and f != output.r2:
                    os.remove(f)

            # Remove os trimmed após decontam bem-sucedido
            for f in [input.r1, input.r2]:
                if os.path.exists(f):
                    os.remove(f)

            # Remove dir tmp da amostra
            import shutil
            shutil.rmtree(params.tmp_dir, ignore_errors=True)

            with open(output.report, "w") as f:
                for row in report_rows:
                    f.write("\t".join(str(x) for x in row) + "\n")

    def clean_reads(sample, read):
        return os.path.join(PROC, f"decontam/{sample}_{read}.fastq.gz")

else:
    def clean_reads(sample, read):
        return os.path.join(PROC, f"trimmed/{sample}_{read}.fastq.gz")
