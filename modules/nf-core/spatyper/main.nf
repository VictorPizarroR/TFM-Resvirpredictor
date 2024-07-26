process SPATYPER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/spatyper:0.3.3--pyhdfd78af_3' :
        'biocontainers/spatyper:0.3.3--pyhdfd78af_3' }"

    input:
    tuple val(meta), path(fasta)
    path repeats
    path repeat_order

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_args = repeats && repeat_order ? "-r ${repeats} -o ${repeat_order}" : ""
    """
    spaTyper \\
        $args \\
        $input_args \\
        --fasta $fasta \\
        --output ${prefix}.tsv

    echo -e "Sample\\tSequence name\\tRepeats\\tType" > ${prefix}_modified.tsv
    tail -n +2 ${prefix}.tsv | while IFS= read -r line; do
        echo -e "${meta.id}\\t\$line" >> ${prefix}_modified.tsv
    done

    mv ${prefix}_modified.tsv ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatyper: \$( echo \$(spaTyper --version 2>&1) | sed 's/^.*spaTyper //' )
    END_VERSIONS
    """
}
