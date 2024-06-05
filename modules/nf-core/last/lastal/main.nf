process LAST_LASTAL {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/last:1542--h43eeafb_1' :
        'biocontainers/last:1542--h43eeafb_1' }"

    input:
    tuple val(meta), path(fastx), path (param_file)
    path index

    output:
    tuple val(meta), path("*.maf.gz"), emit: maf
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def trained_params = param_file ? "-p ${param_file}"  : ''
    """
    INDEX_NAME=\$(basename \$(ls $index/*.des) .des)
    lastal \\
        -P $task.cpus \\
        $trained_params \\
        $args \\
        ${index}/\$INDEX_NAME \\
        $fastx \\
        | gzip --no-name > ${prefix}.\$INDEX_NAME.maf.gz
    # gzip needs --no-name otherwise it puts a timestamp in the file,
    # which makes its checksum non-reproducible.

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        last: \$(lastal --version 2>&1 | sed 's/lastal //')
    END_VERSIONS
    """
}
