# clockwork_pipeline
Nextflow Pipeline for clockwork, mycobacterial_mapping

## Local Installation
* Clone the repo and `cd` into the created directory
* Install a condo environment to run and test the code using the following 

```
conda create -f -y -n nextflow
```

Activate it:

```
conda activate `nextflow`
```

and install `nextflow` and `nf-test` e.g.

```
conda install nextflow nf-test
```

Other ways of install `nextflow` and `nf-test` are available!

You will also need to have installed [Docker desktop](https://www.docker.com/products/docker-desktop/).

Because the pipeline runs in the context of a docker container, no other dependencies are needed.

## Running the Nextflow
The files required to run Clockwork Nextflow are currently included in the repo. 
Ideally these will be moved to a different location/storage method in future


Examples:

```
nextflow run . -profile local --sample_read $(PWD)/test_data/successful/ --ref_files $(PWD)/test_data/ref_data/
```

If you want to run your own samples (two fastq files) through, you will need to 
change `$(PWD)/test_data/successful/` to point to the directory containing your
two fastq files.

## What it does
The clockwork workflow have two processes, the first runs clockwork in a docker 
container, in the example below this is the `6f` subdirectory in the example below.
The second process takes some of the output files from the first process and uses
the data to create the `genome_create_report.json`.

Under the `work` directory your output should be similar to the following
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
│       │   ├── alternate.gvcf
│       │   ├── final.bam
│       │   ├── final.bam.bai
│       │   ├── final.fasta
│       │   ├── final.vcf
│       │   └── genome_creation_error.json
│       └── ref_data
└── f3
    └── a06ba84ace7c1185a462d5f549562a
        ├── alternate.gvcf
        ├── final.fasta
        ├── genome_creation_report.json
        ├── het_list
        └── tb_clockwork_report.json.template
```

## Running unit tests
To setup the tests you will need to have run the nextflow with the following command
```
nextflow run . -profile local --sample_read $(PWD)/test_data/successful/ --ref_files $(PWD)/test_data/ref_data/
```
Then copy the `alternate.gvcf` and `final.fasta` created in the work directory to
the `data/calc_counts_input_files` directory using a command similar to the following
```
nextflow run . -profile local --sample_read $(PWD)/test_data/successful/ --ref_files $(PWD)/test_data/ref_data/
```
You will need to change the hashes in the above command to reflect the ones used
in your run.

To run the tests you will need to have installed and activated the condo 
environment as detailed in the "Running the Nextflow" section. you then should be 
able to call the following command.

```
nf-test test
```

## Docker image
The docker images are include inclode a separate repository and are built to an
OCI container registry. Currently the containers are stored public so Nextflow 
should be able to pull them down.
