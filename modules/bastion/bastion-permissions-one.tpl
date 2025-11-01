{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:AccessKubernetesApi",
                "eks:AssociateEncryptionConfig",
                "eks:AssociateIdentityProviderConfig",
                "eks:CreateAddon",
                "eks:CreateNodegroup",
                "eks:DescribeCluster",
                "eks:DescribeUpdate",
                "eks:ListAddons",
                "eks:ListIdentityProviderConfigs",
                "eks:ListNodegroups",
                "eks:ListTagsForResource",
                "eks:ListUpdates",
                "eks:TagResource",
                "eks:UntagResource",
                "eks:UpdateClusterConfig",
                "eks:UpdateClusterVersion"
            ],
            "Resource": "${eks-cluster-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DeleteNodegroup",
                "eks:DescribeNodegroup",
                "eks:DescribeUpdate",
                "eks:ListTagsForResource",
                "eks:ListUpdates",
                "eks:TagResource",
                "eks:UntagResource",
                "eks:UpdateNodegroupConfig",
                "eks:UpdateNodegroupVersion"
            ],
            "Resource": "${eks-nodegroup-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DeleteAddon",
                "eks:DescribeAddon",
                "eks:DescribeUpdate",
                "eks:ListTagsForResource",
                "eks:ListUpdates",
                "eks:TagResource",
                "eks:UntagResource",
                "eks:UpdateAddon"
            ],
            "Resource": "${eks-addon-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeIdentityProviderConfig",
                "eks:DisassociateIdentityProviderConfig",
                "eks:ListTagsForResource",
                "eks:TagResource",
                "eks:UntagResource"
            ],
            "Resource": "${eks-identity-provider-config-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeAddonVersions"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
                "elasticloadbalancing:AttachLoadBalancerToSubnets",
                "elasticloadbalancing:ConfigureHealthCheck",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateLoadBalancerListeners",
                "elasticloadbalancing:CreateLoadBalancerPolicy",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteLoadBalancerListeners",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeLoadBalancerPolicies",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DetachLoadBalancerFromSubnets",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
                "elasticloadbalancing:SetLoadBalancerPoliciesOfListener"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:Backup",
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientRootAccess",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:CreateMountTarget",
                "elasticfilesystem:CreateTags",
                "elasticfilesystem:DeleteMountTarget",
                "elasticfilesystem:DeleteTags",
                "elasticfilesystem:DescribeBackupPolicy",
                "elasticfilesystem:DescribeFileSystemPolicy",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeLifecycleConfiguration",
                "elasticfilesystem:DescribeMountTargets",
                "elasticfilesystem:DescribeTags",
                "elasticfilesystem:ListTagsForResource",
                "elasticfilesystem:PutBackupPolicy",
                "elasticfilesystem:PutFileSystemPolicy",
                "elasticfilesystem:PutLifecycleConfiguration",
                "elasticfilesystem:Restore",
                "elasticfilesystem:TagResource",
                "elasticfilesystem:UntagResource",
                "elasticfilesystem:UpdateFileSystem"
            ],
            "Resource": "${efs-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:AddTagsToResource",
                "rds:ApplyPendingMaintenanceAction",
                "rds:CreateDBInstanceReadReplica",
                "rds:CreateDBSnapshot",
                "rds:DescribeDBInstanceAutomatedBackups",
                "rds:DescribeDBInstances",
                "rds:DescribeDBLogFiles",
                "rds:DescribeDBSnapshots",
                "rds:DescribeDBSubnetGroups",
                "rds:DescribePendingMaintenanceActions",
                "rds:DescribeValidDBInstanceModifications",
                "rds:DownloadDBLogFilePortion",
                "rds:ListTagsForResource",
                "rds:ModifyDBInstance",
                "rds:PromoteReadReplica",
                "rds:RebootDBInstance",
                "rds:RemoveTagsFromResource",
                "rds:RestoreDBInstanceFromDBSnapshot",
                "rds:RestoreDBInstanceToPointInTime",
                "rds:StartDBInstance",
                "rds:StartDBInstanceAutomatedBackupsReplication",
                "rds:StopDBInstance",
                "rds:StopDBInstanceAutomatedBackupsReplication"
            ],
            "Resource": ["${rds-filter}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:CreateRepository",
                "ecr:TagResource",
                "ecr:UntagResource"
            ],
            "Resource": "${ecr-filter}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}