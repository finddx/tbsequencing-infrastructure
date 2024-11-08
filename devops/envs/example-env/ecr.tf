locals {
  ecr_app_repo_names = [
    "backend",
    "genomicsworkflow-agat",
    "genomicsworkflow-bcftools",
    "genomicsworkflow-bedtools",
    "genomicsworkflow-biopython",
    "genomicsworkflow-bwa",
    "genomicsworkflow-delly",
    "genomicsworkflow-fastqc",
    "genomicsworkflow-fasttree",
    "genomicsworkflow-freebayes",
    "genomicsworkflow-gatk",
    "genomicsworkflow-hail",
    "genomicsworkflow-iqtree",
    "genomicsworkflow-kraken",
    "genomicsworkflow-mosdepth",
    "genomicsworkflow-perl",
    "genomicsworkflow-raxml",
    "genomicsworkflow-samtools",
    "genomicsworkflow-snpeff",
    "genomicsworkflow-spades",
    "genomicsworkflow-sra-tools",
    "ncbi-sync",
    "clamav"
  ]
}

module "ecr" {
  source             = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//ecr?ref=ecr-v1.2"
  ecr_app_repo_names = local.ecr_app_repo_names
  project_name       = var.project_name
}
