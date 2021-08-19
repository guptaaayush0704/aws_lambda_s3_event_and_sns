#---------------------------------------------------------
# Cloud Provider
#---------------------------------------------------------
provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.assume_role_arn
  }
}


#---------------------------------------------------------------------------------
# Data Sources
# The data sources that are used to fetch already existing resources in AWS.
#---------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}




data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


#-------------------------------
# Already existing VPC Resource
#-------------------------------
data "aws_vpc" "vpc_id" {
  tags = {
    Name = var.vpc
  }
}


#-----------------------------------
# Already existing Subnet Resource
#-----------------------------------
data "aws_subnet_ids" "private_subnets" {
    tags = {
    Name = var.subnet_prefix
  }
  vpc_id = data.aws_vpc.vpc_id.id
}


#-------------------------------------------
# Security Group Resources Already Existing
#-------------------------------------------
data "aws_security_group" "NetworkHTTPS" {
  filter {
    name   = "tag:Name"
    values = [var.security_group_https]
  }
}


#-----------------------------------------------------------------------------------------------------------------------------------------
# ASG Configuration Data File Resource
# The template file section where user data(including custom scripts(bash/shell etc.) and other data like json formats etc can be passed)  
#-----------------------------------------------------------------------------------------------------------------------------------------
data "template_file" "user_data" {
  template = file("user_data.tpl")

  vars = {
    componentName = var.component
    environmentName = var.environment
  }
}


#----------------------------------
# ASG Group Configuration Resource  
#----------------------------------
#Launch Configurations cannot be updated after creation with the Amazon Web Service API.
#In order to update a Launch Configuration, Terraform will destroy the existing resource and create a replacement.
#In order to effectively use a Launch Configuration resource with an AutoScaling Group resource, it's recommended to specify create_before_destroy in a lifecycle block.
resource "aws_launch_configuration" "aws_test_lconfig" {
  name_prefix    = var.resource_name_prefix
  associate_public_ip_address = "false"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.keypair_name

  user_data = data.template_file.user_data.rendered
  iam_instance_profile = "ecsInstanceRole"

  root_block_device {
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }
  security_groups = [
   data.aws_security_group.NetworkHTTPS.id
  ]
  lifecycle {
    create_before_destroy = true
  }

}

#----------------------------------
# AWS Autoscaling Group Resource  
#----------------------------------
resource "aws_autoscaling_group" "asg" {
  name                 = var.resource_name_prefix
  desired_capacity     = var.desired_capacity
  min_size             = var.resource_min_size
  max_size             = var.resource_max_size
  health_check_type         = "EC2"
  health_check_grace_period = 900
  termination_policies      = ["OldestInstance"]

  launch_configuration = aws_launch_configuration.aws_test_lconfig.name
  vpc_zone_identifier  =   data.aws_subnet_ids.private_subnets.ids
  tags = [
      {
        key                 = "component"
        value               = var.component
        propagate_at_launch = true
      },
      {
        key                 = "git_url"
        value               = var.git_url
        propagate_at_launch = true
      },
      {
        key                 = "Name"
        value               = var.component
        propagate_at_launch = true
      },
    ]
}


#-----------------------------------------------------------------------------
# Output value exported by a module must be declared using an output block
#-----------------------------------------------------------------------------
# Output section displaying account id TF Assumes into
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}