variable "region" {
  default = "ca-central-1"
}

variable "profile" {
  default = "saml"
}

variable "bucket" {
  default = "jupyterhub-codebuild"
}

variable "codebuildrole" {
  default = "codebuild-role"
}

variable "repoaccesstoken" {
  default = "github-personaltoken"
}

variable "codebuild_projectname" {
  default = "jupyterhub-singleuser-imagebuild"
}

variable "codebuild_projectdescription" {
  default = "To build single user image for jupyterhub"
}

variable "codebuild_timeout" {
  default = "120"
}

variable "codebuild_computetype" {
  default = "BUILD_GENERAL1_MEDIUM"
}

variable "sourcecode_location" {
  default = "https://github.com/ubc/jupyteropen-single-user-image.git"
}

variable "buildenv_vpc" {
  default = "vpc-abc"
}

variable "buildenv_subnets" {
  type = list
  default = ["subnet-x", "subnet-y"]
}

variable "buildenv_sg" {
  type = list
  default = ["sg-x"]
}

variable "codepipeline_name" {
  default = "jupyterhub-singleuserimage-build"
}

variable "codepipeline_bucket" {
  default = "jupyterhub-codepipeline"
}

variable "codepipeline_role" {
  default = "codepipeline-role"
}

variable "codepipeline_policy" {
  default = "codepipeline_policy"
}