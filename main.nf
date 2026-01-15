#!/usr/bin/env nextflow

params.input_paired_suffix = "*_{1,2}.fastq.gz"


workflow {
    ANSI_GREEN = "\033[1;32m"
    ANSI_RESET = "\033[0m"

    if (params.help) {
        log.info(
            """
            ========================================================================
            Clockwork

            Processing bacterial sequence data (Illumina only) and variant calling.

            Parameters:
            ------------------------------------------------------------------------
            --input_dir   Directory holding the fastq files *reads{1,2}.fq.gz
            --ref_files     Location of the reference genome pre prepared files
            """.stripIndent()
        )
        exit(0)
    }

    log.info(
        """
        ========================================================================
        Clockwork

        Processing bacterial sequence data (Illumina only) and variant calling.

        Parameters:
        ------------------------------------------------------------------------
        --input_dir    ${params.input_dir}
        --ref_files      ${params.ref_files}

        Runtime data:
        ------------------------------------------------------------------------
        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """.stripIndent()
    )

    read_ch = Channel.fromFilePairs("${params.input_dir}/${params.input_paired_suffix}", checkIfExists: true)
        .ifEmpty { error("cannot find any reads matching ${params.input_paired_suffix} in ${params.input_dir}") }
    ref_files = Channel.fromPath(params.ref_files).first()

    read_ch.take(3).view()

    clockwork(read_ch, ref_files)
}

workflow clockwork {
    take:
    reads
    ref_files

    main:

    run_clockwork(reads, ref_files)
    calc_counts(run_clockwork.out.all_calls_vcf.join(run_clockwork.out.final_fasta), "${moduleDir}/tb_clockwork_report.json.template", ref_files)

    emit:
    cortex_vcf = run_clockwork.out.cortex_vcf
    all_calls_vcf = run_clockwork.out.all_calls_vcf
    all_calls_vcf_decompressed = run_clockwork.out.all_calls_vcf_decompressed
    final_fasta = run_clockwork.out.final_fasta
    final_vcf = run_clockwork.out.final_vcf
    samtools_vcf = run_clockwork.out.samtools_vcf
    map_bam = run_clockwork.out.map_bam
    map_bam_bai = run_clockwork.out.map_bam_bai
    tb_clockwork_report_json = calc_counts.out.tb_clockwork_report_json
    tb_clockwork_error_json = run_clockwork.out.tb_clockwork_error_json
}

process run_clockwork {
    publishDir "${params.publish_dir}", enabled: params.publish_dir != "", mode: "copy", saveAs: { filename -> sample_name + "_" + filename }
    container params.container_prefix + "/gpas/clockwork:v0.12.5"
    cpus 2
    memory { 16.GB * task.attempt }
    pod label: "name", value: "clockwork_pipeline:run_clockwork"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(reads)
    path ref_files

    output:
    tuple val(sample_name), path("${outdir}/alternate-cortex.vcf.gz"), emit: cortex_vcf
    tuple val(sample_name), path("${outdir}/all_calls.vcf.gz"), emit: all_calls_vcf
    tuple val(sample_name), path("${outdir}/all_calls.vcf"), emit: all_calls_vcf_decompressed
    tuple val(sample_name), path("${outdir}/final.fasta"), emit: final_fasta
    tuple val(sample_name), path("${outdir}/variants.vcf"), emit: variants_vcf
    tuple val(sample_name), path("${outdir}/alternate-samtools.vcf.gz"), emit: samtools_vcf
    tuple val(sample_name), path("${outdir}/final.bam"), emit: map_bam
    tuple val(sample_name), path("${outdir}/final.bam.bai"), emit: map_bam_bai
    tuple val(sample_name), path("${outdir}/genome_creation_error.json"), emit: tb_clockwork_error_json

    script:
    outdir = "outdir"
    """
    clockwork variant_call_one_sample --keep_bam --filter_min_dp 3 --fasta_min_dp 3  --no_trim ${ref_files} ${outdir} ${reads[0]} ${reads[1]}
    if [ ! -f "${outdir}/cortex.vcf" ]; then
        echo -e "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tsample" > ${outdir}/cortex.vcf
    fi

    mv ${outdir}/final.vcf ${outdir}/variants.vcf
    mv ${outdir}/cortex.vcf ${outdir}/alternate-cortex.vcf
    mv ${outdir}/final.gvcf ${outdir}/all_calls.vcf
    gzip -k ${outdir}/all_calls.vcf
    mv ${outdir}/final.gvcf.fasta ${outdir}/final.fasta
    mv ${outdir}/samtools.vcf ${outdir}/alternate-samtools.vcf
    mv ${outdir}/map.bam ${outdir}/final.bam
    mv ${outdir}/map.bam.bai ${outdir}/final.bam.bai
    touch ${outdir}/genome_creation_error.json

    gzip ${outdir}/alternate-cortex.vcf
    gzip ${outdir}/alternate-samtools.vcf

    # replace header of fasta file
    sed -i "1s/^>.*/>${sample_name} ref=NC_000962.3/" ${outdir}/final.fasta
    """
}

process calc_counts {
    publishDir "${params.publish_dir}", enabled: params.publish_dir != "", mode: "copy", saveAs: { filename -> sample_name + "_" + filename }
    container params.container_prefix + "/gpas/clockwork_bcftools:v1.8.2"
    cpus 1
    memory "1 GB"
    pod label: "name", value: "clockwork_pipeline:calc_counts"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(gvcf_file), path(fasta_file)
    path report_template
    path ref_files

    output:
    tuple val(sample_name), path("genome_creation_report.json"), emit: tb_clockwork_report_json

    script:
    """
    bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\t%INFO\\t[%GT]\\t[%DP4]\\t[%COV]\\n'  ${gvcf_file} | \
    awk 'BEGIN {FS=OFS="\\t"} {split(\$7, arr1, ","); split(\$8, arr2, ","); \$7=arr1[1]; \$8=arr1[2]; \$9=arr1[3]; \$10=arr1[4]; \$11=arr2[1]; \$12=arr2[2]; print}'  | \
    awk -F'\\t' '(\$7 + \$8 >= 10 && \$9 > 1 && \$10 > 1) || (\$11 > 1  && \$12>10) || (\$12>1  && \$11>10) ' > het_list
    export het_count=\$(cat het_list | wc -l | xargs)

    export fixed_coverage=\$(cat ${fasta_file} | grep -v "^>" | grep -oE "[NXOZ\\-]" | wc -l | xargs)
    export coverage=\$(cat ${fasta_file} | grep -v "^>" | tr -d '[:space:]' | wc -c | xargs)
    export fixed_coverage_percentage=\$(awk -v coverage=\$coverage -v fixed_coverage=\$fixed_coverage 'BEGIN { print 100 - (100 * (fixed_coverage / coverage))}')

    export null_calls=\$(cat ${fasta_file} | grep -v "^>" | grep -o N | wc -l )

    export reference_genome_length=\$(cat ${ref_files}/ref.fa | grep -v "^>" | tr -d '\\n' | wc -c )

    echo "Het Count: \$het_count"
    echo "Fixed coverage: \$fixed_coverage"
    echo "Coverage: \$coverage"
    echo "Fixed coverage percentage: \$fixed_coverage_percentage"
    echo "Null Calls: \$null_calls"
    echo "Reference Genome Length: \$reference_genome_length"

    cat ${report_template} | envsubst > "genome_creation_report.json"
    """
}
