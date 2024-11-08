# Latest Amazon Linux 2 AMI
locals {
  ec2_instance_type = var.low_cost_implementation ? "t3.nano" : "t3.small"
  iam_ec2_role_name = module.roles.role_name["ec2"]
}

# EC2 bastion instance
resource "aws_instance" "amazon_linux_2" {
  ami                  = data.aws_ami.amazon_linux_2_latest.id
  instance_type        = local.ec2_instance_type
  availability_zone    = "${local.aws_region}a"
  iam_instance_profile = module.roles.instance_profile_name["ec2"]
  subnet_id            = module.vpc.public_subnets[0]
  security_groups      = [module.sg.security_group_id["bastion"]]

  root_block_device {
    volume_size           = var.low_cost_implementation ? "8" : "20"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }


  tags = merge(
    {
      Name = "${local.prefix}-bastion"
    }
  )

  lifecycle {
    ignore_changes = [
      disable_api_termination,
      ebs_optimized,
      hibernation,
      credit_specification,
      security_groups,
      network_interface,
      ephemeral_block_device,
      ami
    ]
  }

  associate_public_ip_address = true
}

resource "aws_eip" "amazon_linux_2" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.amazon_linux_2.id
  allocation_id = aws_eip.amazon_linux_2.id
}
