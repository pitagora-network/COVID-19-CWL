#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
doc: "Preprocessing of raw SARS-CoV-2 reads"
inputs:
  illumina_reads_sra:
    type: string[]
  oxford_nanopore_reads_sra:
    type: string[]

steps:
  fetch_illumina_reads:
    #run: https://raw.githubusercontent.com/pitagora-galaxy/cwl/master/tools/fastq-dump/fastq-dump.cwl
    run: ../tools/fastq-dump.cwl
    in:
      sraFiles: illumina_reads_sra
    out:
      - fastqFiles
      - forward
      - reverse
  # outputが、ファイルのオプショナル（nullかファイルを許容する。具体的には、ファイルが出力されないことがあるときのための、ラッパー）
  unwrap_illumina_reads_forward:
    run: https://raw.githubusercontent.com/pitagora-network/DAT2-cwl/develop/tool/unwrap/unwrap.cwl
    doc: "`File?` -> `File` の変換ステップ。 `null` が来たら問答無用で `permanentFailure`"
    in:
      input: fetch_illumina_reads/forward
    out:
      - unwrapped
  unwrap_illumina_reads_reverse:
    run: https://raw.githubusercontent.com/pitagora-network/DAT2-cwl/develop/tool/unwrap/unwrap.cwl
    in:
      input: fetch_illumina_reads/reverse
    out:
      - unwrapped
  #   fetch_oxford_nanopore_reads:
  #     run: https://raw.githubusercontent.com/pitagora-galaxy/cwl/master/tools/fastq-dump/fastq-dump.cwl
  #     in:
  #       sraFiles: oxford_nanopore_reads_sra
  #     out:
  #       - fastqFiles
  #       - forward
  #       - reverse
  # trimming_illumina_reads: {} # Using fastp
  fastp:
    run: https://raw.githubusercontent.com/pitagora-network/DAT2-cwl/develop/tool/fastp/fastp-pe/fastp-pe.cwl
    in: # ここに、fetch_illumina_readsのoutputをかく
      fastq1: unwrap_illumina_reads_forward/unwrapped
      fastq2: unwrap_illumina_reads_reverse/unwrapped
    out: # ここで、次に渡すファイルを指定する。この２つをbwa_memのinに書く
      - output_fastq1
      - output_fastq2
#   bwa_mem:
#     doc: |-
#       このステップでは、ヒトゲノムにマップしている。
#       ヒトゲノムのコンタミをのぞくのに、hg38にマップしている。
#       コンタミとは、この場合ウイルスを読んだつもりでいるが、いくらか、ヒトのデータがまざっていることがありうる
#       そのめの、イルミナかigenomeからインデックスを落としておく必要がある。
#     run: https://raw.githubusercontent.com/pitagora-network/pitagora-cwl/master/tools/bwa/bwa-pe.cwl
#     in: # fastpのpaired end outputを書く
#       mem:
#         default: true
#       mark_shorter_split_hits:
#       read_group_header_line:
#       genome_index: # TODO:
#       fq1: fastp/output_fastq1
#       fq2: fastp/output_fastq2
#       process:
#     out:
#   multi_qc:
#     run: https://raw.githubusercontent.com/mareq/cwl-tutor/0ef5b1b97e59309bc2c4f898ada0cc4b93729831/workflows/tools/multiqc/main.cwl
#     in:
#       name:
#       input_files:
#     out:
outputs:
  illumina_reads:
    type: File[]
    outputSource: fetch_illumina_reads/fastqFiles
  #   oxford_nanopore_reads:
  #     type: File[]
  #     outputSource: fetch_oxford_nanopore_reads/fastqFiles
  fastp_output_fastq1:
    type: File
    outputSource: fastp/output_fastq1
  fastp_output_fastq2:
    type: File
    outputSource: fastp/output_fastq2
