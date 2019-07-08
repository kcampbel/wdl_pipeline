version 1.0

task runStrelka {
    input {
        File normalBam
        File normalBamIndex
        File tumorBam
        File tumorBamIndex
        File referenceFasta
        File referenceFastafai
    }

#    File referenceFasta = referenceFastaFiles[0]

    command <<<
        /opt/strelka/bin/configureStrelkaSomaticWorkflow.py --normalBam=~{normalBam} --tumorBam=~{tumorBam} --referenceFasta=~{referenceFasta} --exome --runDir=$PWD
        python2 $PWD/runWorkflow.py -m local -j 2 -g 8
    >>>

    output {
        File indelFile = "results/variants/somatic.indels.vcf.gz"
        File snvFile = "results/variants/somatic.snvs.vcf.gz"
    }

    runtime {
        docker: "mgibio/strelka-cwl:2.9.9"
        disks: "local-disk 400 SSD"
        memory: "64G"
        cpu: 8
    }
}