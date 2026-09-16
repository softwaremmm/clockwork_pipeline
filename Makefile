clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
	find . -type d -name .nf-test | xargs rm -rf

test: clean
	nf-test test tests/*.nf.test

run-nextflow:
	nextflow run main.nf \
		--ref_files test_data/ref_data  \
		--input_dir test_data/successful \
		-profile local 
