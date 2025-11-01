{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ChangeTagsForResource",
                "route53:GetHostedZone",
                "route53:GetHostedZoneLimit",
                "route53:ListResourceRecordSets",
                "route53:ListTagsForResource",
                "route53:ListTagsForResources",
                "route53:ListTrafficPolicyInstancesByHostedZone",
                "route53:UpdateHostedZoneComment"
            ],
            "Resource": ["${hostedzone-filter}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:CreateHealthCheck",
                "route53:ChangeTagsForResource",
                "route53:DeleteHealthCheck",
                "route53:GetHealthCheck",
                "route53:GetHealthCheckCount",
                "route53:GetHealthCheckLastFailureReason",
                "route53:GetHealthCheckStatus",
                "route53:UpdateHealthCheck"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate"
            ],
            "Resource": [ "${certificate-arn}" ]
        },
        {
            "Effect": "Allow",
            "Action": [
				"ec2:CreateTags",
				"ec2:CreateVolume",
				"ec2:ModifyInstanceAttribute",
				"ec2:AttachNetworkInterface",
				"ec2:AttachVolume",
				"ec2:CreateInstanceExportTask",
				"ec2:CreateSnapshots",
				"ec2:GetConsoleOutput",
				"ec2:GetConsoleScreenshot",
				"ec2:ModifyInstanceCapacityReservationAttributes",
				"ec2:ModifyInstanceMetadataOptions",
				"ec2:MonitorInstances",
				"ec2:RebootInstances",
				"ec2:ReportInstanceStatus",
				"ec2:ResetInstanceAttribute",
				"ec2:RunInstances",
				"ec2:SendDiagnosticInterrupt",
				"ec2:StartInstances",
				"ec2:StopInstances",
				"ec2:TerminateInstances",
				"ec2:UnmonitorInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Deployment-ID": "${deployment-id}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "ArnEquals": {
                    "ec2:Vpc": "${vpc-filter}"
                }
            }
        },
        {
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeStaleSecurityGroups",
                "ec2:DescribeVpcs"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}