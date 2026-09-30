process INSTANEXUS_PREPROCESS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/instanexus:0.2.1--pyhdfd78af_0':
        'quay.io/biocontainers/instanexus:0.2.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(csv)
    path contaminants
    path metadata_json

    output:
    tuple val(meta), path("*.cleaned.csv"), emit: csv
    tuple val("${task.process}"), val('instanexus'), eval("python -c \"import importlib.metadata as m; print(m.version('instanexus'))\""), topic: versions, emit: versions_instanexus

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def contaminants_arg = contaminants ? "--contaminants-fasta ${contaminants}" : ''
    def metadata_arg = metadata_json ? "--metadata-json ${metadata_json}" : ''
    // InstaNexus has no threads option; the thread pools of its numerical libraries are capped instead.
    // HOME and MPLCONFIGDIR must be writable because matplotlib is imported on start-up.
    // The input keeps its original name: InstaNexus keys the metadata lookup on the file stem.
    """
    export HOME="\$PWD"
    export MPLCONFIGDIR="\$PWD/.mpl"
    export OMP_NUM_THREADS=${task.cpus}
    export OPENBLAS_NUM_THREADS=${task.cpus}
    export MKL_NUM_THREADS=${task.cpus}
    export NUMEXPR_NUM_THREADS=${task.cpus}

    python -m instanexus.preprocessing \\
        --input-csv ${csv} \\
        ${contaminants_arg} \\
        ${metadata_arg} \\
        --output-csv-path ${prefix}.cleaned.csv \\
        ${args}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.cleaned.csv
    """
}
