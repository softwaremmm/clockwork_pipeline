# clockwork_pipeline
Nextflow Pipeline for clockwork, mycobacterial_mapping

## Requirements
- [Docker](https://www.docker.com/products/docker-desktop/)
- nextflow
- nf-test for testing

Clockwork also requires files related to the reference to assemble against.
In this repo they are included in `./test_data/ref_data`.


## Running the Nextflow
Workflow takes 2 parameters:
- input_dir. folder containing input fastq files.
- ref_files. folder containing reference files

To save output files need to set `--publish_dir` which will save output files to directory provided.

example:
```
nextflow run . -profile local --publish_dir results --input_dir test_data/successful --ref_files test_data/ref_data/
```

Change `input_dir` to point to your files. Will look for files based on default parameter:
```
params.input_paired_suffix = "*_{1,2}.fastq.gz"
```

## The Pipeline
- Run clockwork to assemble a genome
- second process summarises some of the process to a report file

example output files:
```
work
├── 6f
│   └── cf6d4122b05a2ba0fdb55f8d71e5dc
│       ├── WTCHG_885333_73205296_1_subset_200K_1.fastq.gz
│       ├── WTCHG_885333_73205296_1_subset_200K_2.fastq.gz
│       ├── cortex.vcf
│       ├── outdir
│       │   ├── alternate-cortex.vcf
│       │   ├── alternate-samtools.vcf
│       │   ├── all_calls.vcf
│       │   ├── final.bam
│       │   ├── final.bam.bai
│       │   ├── final.fasta
│       │   ├── variants.vcf
│       │   └── genome_creation_error.json
│       └── ref_data
└── f3
    └── a06ba84ace7c1185a462d5f549562a
        ├── all_calls.vcf
        ├── final.fasta
        ├── genome_creation_report.json
        ├── het_list
        └── tb_clockwork_report.json.template
```

## Testing
Uses nf-test.

```bash
nf-test test tests/*.nf.test
# or
make test
```

## Docker image
The docker images are include in a separate repository and are built to an
OCI container registry. Currently the containers are stored public so Nextflow
should be able to pull them down.

## Tags, Releases, and Committing
Use conventional commits. This is enforced with commitizen validate action and pre-commit hooks:
```bash
pre-commit install
```

This repo uses a standard gitflow approach, so changes should be first merged into develop and then released to main.
- In the develop branch semantic versioning is not used. Instead you can reference the commit hash to use it in a workflow.
- In a release branch you can create a release candidate with `cz bump a.b.c-rcX`. This also creates a tag.
- When release branch is ready for main run `cz bump a.b.c --files-only`. Manually write a human descriptive changelog. Then push these changes to main and make a release/tag there.
