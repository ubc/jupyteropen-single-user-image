resource "aws_s3_bucket" "codebuild" {
  bucket = var.bucket
}

resource "aws_s3_bucket_acl" "codebuildbucket" {
  bucket = aws_s3_bucket.codebuild.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role_codebuild" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuildrole" {
  name               = var.codebuildrole
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}


data "aws_iam_policy_document" "codebuildpolicydocument" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:ca-central-1:032401129069:network-interface/*"]

    condition {
      test     = "StringLike"
      variable = "ec2:Subnet"

      values = [
        "arn:aws:ec2:ca-central-1:032401129069:subnet/*",
        "arn:aws:ec2:ca-central-1:032401129069:subnet/*",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }


  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.codebuild.arn,
      "${aws_s3_bucket.codebuild.arn}/*",
    ]
  }

}

data "aws_iam_policy" "ecr_access" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_access" {
  role       = aws_iam_role.codebuildrole.name
  policy_arn = data.aws_iam_policy.ecr_access.arn
}

resource "aws_iam_role_policy" "codebuildpolicy" {
  role   = aws_iam_role.codebuildrole.name
  policy = data.aws_iam_policy_document.codebuildpolicydocument.json
}

#### Code Build Project ### 

resource "aws_codebuild_source_credential" "repo-access" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.repoaccesstoken
}

resource "aws_codebuild_project" "jupyterhub-singleuser-imagebuild" {
  name          = var.codebuild_projectname
  description   = var.codebuild_projectdescription
  build_timeout = var.codebuild_timeout
  service_role  = aws_iam_role.codebuildrole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild.bucket
  }

  environment {
    compute_type                = var.codebuild_computetype
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }

    # environment_variable {
    #   name  = "SOME_KEY2"
    #   value = "SOME_VALUE2"
    #   type  = "PARAMETER_STORE"
    # }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    # s3_logs {
    #   status   = "ENABLED"
    #   location = "${aws_s3_bucket.example.id}/build-log"
    # }
  }

  source {
    type     = "GITHUB"
    location = var.sourcecode_location


    # git_submodules_config {
    #   fetch_submodules = true
    # }
  }

  source_version = "main"

  vpc_config {
    vpc_id = var.buildenv_vpc

    subnets = var.buildenv_subnets

    security_group_ids = var.buildenv_sg
  }

  tags = {
    Environment = "JupyterHub"
  }
}

