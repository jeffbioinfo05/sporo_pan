rule phylogeny:
    input:  os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt")
    output: os.path.join(RESULTS, "phylogeny/species_tree.nwk")
    log:    os.path.join(LOGS, "phylogeny.log")
    shell:  "cp {input} {output} 2> {log}"
