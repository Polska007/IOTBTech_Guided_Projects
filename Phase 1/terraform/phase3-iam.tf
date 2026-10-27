###############################################################################
# Phase 3 - GitHub Actions OIDC and CI/CD permissions
###############################################################################

data "aws_caller_identity" "current" {}

###############################################################################
# GitHub Actions OIDC Provider
###############################################################################

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name    = "${var.project_name}-github-actions-oidc"
    Project = var.project_name
    Phase   = "Phase-3"
  }
}

###############################################################################
# GitHub Actions IAM Role
#
# Trust is restricted to:
# Repository: Polska007/IOTBTech_Guided_Projects
# Branch: main
###############################################################################

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowGitHubActionsOIDC"
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:Polska007/IOTBTech_Guided_Projects:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-github-actions-role"
    Project = var.project_name
    Phase   = "Phase-3"
  }
}

###############################################################################
# GitHub Actions Deployment Policy
###############################################################################

resource "aws_iam_policy" "github_actions_deployment" {
  name        = "${var.project_name}-github-actions-deployment"
  description = "Allows GitHub Actions to push ZeetaFin images to ECR and deploy through SSM"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      #########################################################################
      # Authenticate to Amazon ECR
      #########################################################################
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      #########################################################################
      # Push backend and frontend Docker images
      #########################################################################
      {
        Sid    = "ECRPushZeetaFinImages"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = [
          "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/zeetafin-be",
          "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/zeetafin-fe"
        ]
      },

      #########################################################################
      # Send deployment command to managed EC2 through Systems Manager
      #########################################################################
      {
        Sid    = "SendSSMDeploymentCommand"
        Effect = "Allow"

        Action = [
          "ssm:SendCommand"
        ]

        Resource = concat(
          [
            "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
          ],
          aws_instance.managed[*].arn
        )
      },

      #########################################################################
      # Read deployment command results
      #########################################################################
      {
        Sid    = "ReadSSMDeploymentResults"
        Effect = "Allow"

        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:ListCommands"
        ]

        Resource = "*"
      },

      #########################################################################
      # Verify the managed instance is online in SSM
      #########################################################################
      {
        Sid    = "DescribeSSMManagedInstances"
        Effect = "Allow"

        Action = [
          "ssm:DescribeInstanceInformation"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-github-actions-deployment"
    Project = var.project_name
    Phase   = "Phase-3"
  }
}

###############################################################################
# Attach deployment permissions to GitHub Actions role
###############################################################################

resource "aws_iam_role_policy_attachment" "github_actions_deployment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_deployment.arn
}