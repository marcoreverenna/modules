process INSTANEXUS_ASSEMBLE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/instanexus:0.2.1--pyhdfd78af_0':
        'quay.io/biocontainers/instanexus:0.2.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(csv)

    output:
    tuple val(meta), path("*.scaffolds.fasta"), emit: scaffolds
    tuple val("${task.process}"), val('instanexus'), eval("python -c \"import importlib.metadata as m; print(m.version('instanexus'))\""), topic: versions, emit: versions_instanexus

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // InstaNexus has no threads option; the thread pools of its numerical libraries are capped instead.
    // HOME and MPLCONFIGDIR must be writable because matplotlib is imported on start-up.
    """
    export HOME="\$PWD"
    export MPLCONFIGDIR="\$PWD/.mpl"
    export OMP_NUM_THREADS=${task.cpus}
    export OPENBLAS_NUM_THREADS=${task.cpus}
    export MKL_NUM_THREADS=${task.cpus}
    export NUMEXPR_NUM_THREADS=${task.cpus}

    python -m instanexus.assembly \\
        --input-csv-path ${csv} \\
        --output-scaffolds-path ${prefix}.scaffolds.fasta \\
        ${args}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.scaffolds.fasta
    """
}
