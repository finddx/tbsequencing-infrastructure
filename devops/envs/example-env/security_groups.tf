module "sg" {
  source           = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//security-groups?ref=sg-v1.2"
  security_groups  = local.security_groups
  sg_rules_ingress = local.sg_rules.ingress
  sg_rules_egress  = local.sg_rules.egress
  vpc_id           = module.vpc.vpc_id

  module_name  = var.module_name
  project_name = var.project_name
  environment  = var.environment
  region       = local.aws_region
  default_tags = local.tags
}

locals {
  security_groups = [
    {
      name        = "public-alb"
      description = "Security group for the public facing ELB."
    },
    {
      name        = "private-ecs"
      description = "ECS Fargate Backend Task security group."
    },
    {
      name        = "batch-compute"
      description = "For the bioinformatic/ncbi-sync task executions."
    },
    {
      name        = "postgresql"
      description = "Allow Postgres access."
    },
    {
      name        = "bastion"
      description = "Amazon Linux 2 SG"
    },
    {
      name        = "vpc-endpoints"
      description = "VPC Endpoints SG"
    },
    {
      name        = "glue"
      description = "For the Glue connection to RDS."
    }
  ]
  sg_rules = {
    ingress = {
      # Rule for glue connection
      rule01 = {
        security_group_id        = module.sg.security_group_id["glue"]
        source_security_group_id = module.sg.security_group_id["glue"]
        from_port                = 0
        to_port                  = 65535
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow all trafic, required by Glue"
      },

      # Rules for public-alb
      rule10 = {
        security_group_id        = module.sg.security_group_id["public-alb"]
        source_security_group_id = null
        from_port                = 80
        to_port                  = 80
        protocol                 = "TCP"
        cidr_blocks              = "0.0.0.0/0"
        description              = "Allow HTTP traffic"
      },
      rule11 = {
        security_group_id        = module.sg.security_group_id["public-alb"]
        source_security_group_id = null
        from_port                = 443
        to_port                  = 443
        protocol                 = "TCP"
        cidr_blocks              = "0.0.0.0/0"
        description              = "Allow HTTPS traffic"
      }
      # Rules for private-ecs
      rule20 = {
        security_group_id        = module.sg.security_group_id["private-ecs"]
        source_security_group_id = module.sg.security_group_id["public-alb"]
        from_port                = 8000
        to_port                  = 8000
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Ingress rule to communicate with the ELB"
      },
      # Rules for batch-compute
      rule30 = {
        security_group_id        = module.sg.security_group_id["batch-compute"]
        source_security_group_id = module.sg.security_group_id["batch-compute"]
        from_port                = 1018
        to_port                  = 1023
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow FSx Lustre Communication"
      }
      rule31 = {
        security_group_id        = module.sg.security_group_id["batch-compute"]
        source_security_group_id = module.sg.security_group_id["batch-compute"]
        from_port                = 988
        to_port                  = 988
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow FSx Lustre Communication"
      }
      rule32 = {
        security_group_id        = module.sg.security_group_id["batch-compute"]
        source_security_group_id = module.sg.security_group_id["batch-compute"]
        from_port                = 2049
        to_port                  = 2049
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow EFS Communication"
      }
      # Rules for Postgres
      rule40 = {
        security_group_id        = module.sg.security_group_id["postgresql"]
        source_security_group_id = module.sg.security_group_id["private-ecs"]
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow RDS access from ALB"
      },
      rule41 = {
        security_group_id        = module.sg.security_group_id["postgresql"]
        source_security_group_id = module.sg.security_group_id["bastion"]
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow RDS access from the bastion"
      },
      rule42 = {
        security_group_id        = module.sg.security_group_id["postgresql"]
        source_security_group_id = module.sg.security_group_id["postgresql"]
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow RDS access from the lambda functions"
      },
      rule43 = {
        security_group_id        = module.sg.security_group_id["postgresql"]
        source_security_group_id = module.sg.security_group_id["batch-compute"]
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow RDS access from the compute nodes"
      },
      rule44 = {
        security_group_id        = module.sg.security_group_id["postgresql"]
        source_security_group_id = module.sg.security_group_id["glue"]
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "TCP"
        cidr_blocks              = null
        description              = "Allow RDS access for Glue"
      },

      # Rules for amazon-linux-2
      rule50 = {
        security_group_id        = module.sg.security_group_id["bastion"]
        source_security_group_id = null
        from_port                = 22
        to_port                  = 22
        protocol                 = "TCP"
        cidr_blocks              = "0.0.0.0/0"
        description              = "Allow SSH access"
      },
      # Rules for vpc-endpoints
      rule60 = {
        security_group_id        = module.sg.security_group_id["vpc-endpoints"]
        source_security_group_id = null
        from_port                = 443
        to_port                  = 443
        protocol                 = "TCP"
        cidr_blocks              = module.vpc.vpc_cidr_block
        description              = "Allow vpc endpoints access"
      },
    },
    egress = {
      # Rules for glue connection
      rule09 = {
        security_group_id             = module.sg.security_group_id["glue"]
        destination_security_group_id = null
        from_port                     = null
        to_port                       = null
        protocol                      = "all"
        cidr_blocks                   = "0.0.0.0/0"
        description                   = "Glue connection requires all egress ports to everywhere, somehow."
      },
      # Rules for public-alb
      rule19 = {
        security_group_id             = module.sg.security_group_id["public-alb"]
        destination_security_group_id = module.sg.security_group_id["private-ecs"]
        from_port                     = 443
        to_port                       = 443
        protocol                      = "TCP"
        description                   = "Allow traffic for the listener"
        cidr_blocks                   = null
      },
      rule18 = {
        security_group_id             = module.sg.security_group_id["public-alb"]
        destination_security_group_id = module.sg.security_group_id["private-ecs"]
        from_port                     = 8000
        to_port                       = 8000
        protocol                      = "TCP"
        description                   = "Allow traffic for the health check"
        cidr_blocks                   = null
      },
      # Rules for private-ecs
      rule28 = {
        security_group_id             = module.sg.security_group_id["private-ecs"]
        destination_security_group_id = module.sg.security_group_id["postgresql"]
        from_port                     = 5432
        to_port                       = 5432
        protocol                      = "TCP"
        cidr_blocks                   = null
        description                   = "Allow query to RDS"
      },
      rule29 = {
        security_group_id             = module.sg.security_group_id["private-ecs"]
        destination_security_group_id = null
        from_port                     = 443
        to_port                       = 443
        protocol                      = "TCP"
        cidr_blocks                   = "0.0.0.0/0"
        description                   = "Allow sending of emails."
      },
      # Rules for Postgres
      rule42 = {
        security_group_id             = module.sg.security_group_id["postgresql"]
        destination_security_group_id = module.sg.security_group_id["postgresql"]
        from_port                     = 5432
        to_port                       = 5432
        protocol                      = "TCP"
        cidr_blocks                   = null
        description                   = "Allow Postgres access to itself. This is necessary for lambda."
      },

      # Rules for batch-compute
      rule39 = {
        security_group_id             = module.sg.security_group_id["batch-compute"]
        destination_security_group_id = null
        from_port                     = 0
        to_port                       = 65535
        protocol                      = "TCP"
        cidr_blocks                   = "0.0.0.0/0"
        description                   = "Ports needed: 5432 for Postgres (INSDC & taxonomy sync), 443 for NCBI API, 20-22 + all for SFTP Passive connection."
      },
      # Rules for amazon-linux-2
      rule59 = {
        security_group_id             = module.sg.security_group_id["bastion"]
        destination_security_group_id = null
        from_port                     = 443
        to_port                       = 443
        protocol                      = "tcp"
        cidr_blocks                   = "0.0.0.0/0"
        description                   = "Allow HTTPS outbound access."
      },
      rule58 = {
        security_group_id             = module.sg.security_group_id["bastion"]
        destination_security_group_id = module.sg.security_group_id["postgresql"]
        from_port                     = 5432
        to_port                       = 5432
        protocol                      = "tcp"
        cidr_blocks                   = null
        description                   = "Allow RDS connection."
      },
    }
  }
}
