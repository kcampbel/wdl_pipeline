version 1.0

#import "./tasks/varcalling_Varscan2wdl" as Varscan
#import "./tasks/varcalling_Strelka.wdl" as Strelka

import "https://raw.githubusercontent.com/kcampbel/wdl_pipeline/master/tasks/varcalling_Varscan2.wdl" as Varscan
import "https://raw.githubusercontent.com/kcampbel/wdl_pipeline/master/tasks/varcalling_Strelka.wdl" as Strelka

workflow SomaticVaraintDetection {
    input {
        File fofn_bams_paired
        File reference_fasta
        File reference_fasta_index
    }

    Array[Array[String]] map_bams = read_tsv(fofn_bams_paired)

    scatter (pair in map_bams) {
        String tumorSample = pair[0]
        File tumorBam = pair[1]
        String normalSample = pair[2]
        File normalBam = pair[3]

        call processBam {
            input:
                tumorSample = tumorSample,
                tumorBam = tumorBam,
                normalSample = normalSample,
                normalBam = normalBam
        }

        call Varscan.runVarscan as Varscan {
            input:
                reference_fasta = reference_fasta,
                reference_fasta_index =reference_fasta_index,
                tumor_bam = tumorBam,
                tumor_bam_index = processBam.tumorBamIndex,
                tumor_sample = tumorSample,
                normal_bam = normalBam,
                normal_bam_index = processBam.normalBamIndex
        }

        call Strelka.runStrelka as Strelka {
            input:
                normalbam = normalBam,
                normalbamindex = processBam.normalBamIndex,
                tumorsample = tumorSample,
                tumorbam = tumorBam,
                tumorbamindex = processBam.tumorBamIndex,
                referenceFasta = reference_fasta,
                referenceFastafai = reference_fasta_index
        }

    }

    output {
        Array[File] outputtumorFlagstat = processBam.tumorFlagstat
        Array[File] outputnormalFlagstat = processBam.normalFlagstat
        Array[File] outputtumorBamIndex = processBam.tumorBamIndex
        Array[File] outputnormalBamIndex = processBam.normalBamIndex       
        Array[File] outputVarscansnpFiles = Varscan.snpFile
        Array[File] outputVarscanindelFiles = Varscan.indelFile
        Array[File] outputStrelkaindelFiles = Strelka.indelFile
        Array[File] outputStrelkasnvFile = Strelka.snvFile
    }
    
}

task processBam {
    input {
        String tumorSample 
        File tumorBam
        String normalSample
        File normalBam
    }

    command <<<
        /usr/local/bin/samtools flagstat ~{tumorBam} > ~{tumorSample}.flagstat.txt
        
        /usr/local/bin/samtools flagstat ~{normalBam} > ~{normalSample}.flagstat.txt

        /usr/local/bin/samtools index ~{tumorBam} $PWD/~{tumorSample}.FINAL.bam.bai

        /usr/local/bin/samtools index ~{normalBam} $PWD/~{normalSample}.FINAL.bam.bai
    >>>

    output {
        File tumorFlagstat = "~{tumorSample}.flagstat.txt"
        File normalFlagstat = "~{normalSample}.flagstat.txt"
        File tumorBamIndex = "~{tumorSample}.FINAL.bam.bai"
        File normalBamIndex = "~{normalSample}.FINAL.bam.bai"
    }

    #Remove comments if running locally
    # runtime {
    #     docker: "broadinstitute/genomes-in-the-cloud:2.3.1-1512499786"
    #     disks: "local-disk 100 SSD"
    #     memory: "16G"
    #     cpu: 1
    # }

}