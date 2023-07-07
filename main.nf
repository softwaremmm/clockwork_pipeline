#!/usr/bin/env nextflow

//Set DSL2 syntax
nextflow.enable.dsl=2

// Kubernetes Related Buckets
// if (executor != 'k8s') {
//     params.uploads_bucket = "./data/uploads"
//     params.inputs_bucket = "./data/inputs"
//     params.outputs_bucket = "./data/outputs"
//     params.relatedness_bucket = "./data/relatedness"
//     params.knowledge_bucket = "./data/knowledge"
// } else {
//     params.uploads_bucket = "/data/uploads"
//     params.inputs_bucket = "/data/inputs"
//     params.outputs_bucket = "/data/outputs"
//     params.relatedness_bucket = "/data/relatedness"
//     params.knowledge_bucket = "/data/knowledge"
// }

process run_clockwork{
    input:
        path sample_reads1
        path sample_reads2
    output:
        path("./Outdir/cortex.vcf"), emit: cortex_vcf
        path("./Outdir/final.gvcf"), emit: final_gvcf
        path("./Outdir/final.gvcf.fasta"), emit: final_gvcf_fasta
        path("./Outdir/final.vcf"), emit: final_vcf
        path("./Outdir/samtools.vcf"), emit: samtools_vcf
        path("./Outdir/map.bam"), emit: map_bam
    script:
        """
        clockwork variant_call_one_sample --keep_bam --no_trim /data/Ref_prepare /Outdir ${sample_reads1} ${sample_reads2}
        """
    stub:
        """
        mkdir -p ./Outdir
        touch ./Outdir/cortex.vcf
        touch ./Outdir/final.gvcf
        touch ./Outdir/final.gvcf.fasta
        touch ./Outdir/final.vcf
        touch ./Outdir/samtools.vcf
        touch ./Outdir/map.bam
        """
}

workflow clockwork{
    take:
    sample_reads

    main:

        // //Setup so --help triggers the help message
        // if (params.help) {
        //     log.info """
        //     """
        //     .stripIndent()
        //     exit(0)
        // }

        // if (sample_reads1 = '' or sample_reads2 = '') {
        //     log.info 'Missing one or both of the fasta read files, aborting'
        //     exit(1)
        // }

        // log.info """
        // """
        // .stripIndent()

        run_clockwork(sample_reads[0], sample_reads[1])
    
    emit:
        cortex_vcf = run_clockwork.out.cortex_vcf
        final_gvcf = run_clockwork.out.final_gvcf
        final_gvcf_fasta = run_clockwork.out.final_gvcf_fasta
        final_vcf = run_clockwork.out.final_vcf
        samtools_vcf = run_clockwork.out.samtools_vcf
        map_bam = run_clockwork.out.map_bam
}



workflow{
    main:
        // Channel
        //     .fromFilePairs([params.sample_reads1, params.sample_reads2], checkIfExists:true)
        //     // .set {ch_read_files}
        //     // | clockwork
        //     .view()
        Channel
            .fromFilePairs("$params.sample_read/*reads{1,2}.fq.gz", checkIfExists:true)
            | clockwork
        // clockwork(ch_read_files)
}