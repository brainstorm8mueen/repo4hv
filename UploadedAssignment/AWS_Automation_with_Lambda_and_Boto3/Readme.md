# AWS Serverless Assignments (Low Cost & Easy to Complete)

## Recommended 4 Assignments
1. Automated S3 Bucket Cleanup
2. Automated EBS Snapshot Creation and Cleanup
3. Auto-Tagging EC2 Instances on Launch
4. Daily AWS Cost Alert Using Cost Explorer API and SNS

These four are easiest to demonstrate, require minimal AWS cost, and can be completed using Lambda, EventBridge, SNS, S3 and a small EC2 instance.

---

# Assignment 1: Automated S3 Bucket Cleanup

## Architecture
S3 Bucket -> Lambda -> Deletes Old Objects

## Important Screenshots and Files
1. S3 bucket created and Files uploaded
2. IAM Role permissions
3. Lambda test execution result
4. Invoke Lambda manually
5. Bucket after cleanup

## Step 1: Create S3 Bucket
- Open S3
- Create bucket: mab-s3-cleanup-demo
- Upload 3-5 test files

## Step 2: Create IAM Role
Policy:
- s3:ListBucket
- s3:DeleteObject

## Step 3: Create Lambda
Runtime: Python 3.12

Environment Variable:
BUCKET_NAME=mab-s3-cleanup-demo

## Lambda Code
```python
import boto3
from datetime import datetime, timezone, timedelta

s3 = boto3.client('s3')

BUCKET_NAME = 'mab-s3-cleanup-demo'
DAYS = 30


def lambda_handler(event, context):
    cutoff = datetime.now(timezone.utc) - timedelta(days=DAYS)

    paginator = s3.get_paginator('list_objects_v2')

    deleted = []

    for page in paginator.paginate(Bucket=BUCKET_NAME):
        for obj in page.get('Contents', []):
            if obj['LastModified'] < cutoff:
                s3.delete_object(
                    Bucket=BUCKET_NAME,
                    Key=obj['Key']
                )
                deleted.append(obj['Key'])
                print(f'Deleted: {obj["Key"]}')

    return {
        'deleted_objects': deleted
    }
```

## Testing
Use minutes instead of 30 days temporarily.
Invoke Lambda manually.
Verify old files removed.

## Discussion
S3 Lifecycle Rules are preferred for simple expiration. Lambda is useful when deletion depends on naming patterns, metadata, approval checks, notifications, or cross-service actions.

---
# Assignment 2: Automated EBS Snapshot Creation and Cleanup

## Important Screenshots
1. EBS Volume ID
2. IAM Role Permission
3. Lambda test execution result
4. Invoke Lambda manually
5. Snapshot created
6. EventBridge schedule

## Step 1: Create Volume
Use root volume of existing EC2.
Note Volume ID. That is vol-0cadd439219dddbaf

## Step 2: IAM Role
Permissions:
- ec2:CreateSnapshot
- ec2:DescribeSnapshots
- ec2:DeleteSnapshot
- ec2:CreateTags

## Step 3: Lambda
Runtime Python 3.12

## Lambda Code
```python
import boto3
from datetime import datetime, timezone, timedelta

ec2 = boto3.client('ec2')
VOLUME_ID = 'vol-0cadd439219dddbaf'


def lambda_handler(event, context):

    snapshot = ec2.create_snapshot(
        VolumeId=VOLUME_ID,
        Description='Lambda Backup Snapshot'
    )

    snapshot_id = snapshot['SnapshotId']

    ec2.create_tags(
        Resources=[snapshot_id],
        Tags=[{'Key':'CreatedBy','Value':'Lambda-Backup'}]
    )

    print('Created:', snapshot_id)

    retention = datetime.now(timezone.utc) - timedelta(minutes=5)

    snapshots = ec2.describe_snapshots(
        OwnerIds=['self'],
        Filters=[
            {
                'Name':'tag:CreatedBy',
                'Values':['Lambda-Backup']
            }
        ]
    )

    for snap in snapshots['Snapshots']:
        if snap['StartTime'] < retention:
            ec2.delete_snapshot(
                SnapshotId=snap['SnapshotId']
            )
            print('Deleted:', snap['SnapshotId'])

    return {'snapshot': snapshot_id}
```

## EventBridge Schedule
Schedule: One time schedule

## Testing
Run Lambda manually.
Check EC2 -> Snapshots.

## Discussion
AWS DLM is preferred for basic retention. Lambda is better for custom retention logic, cross-account copies, Teams/Email alerts and business rules.

---

# Assignment 3: Auto-Tagging EC2 Instances on Launch

## Important Screenshots
1. EventBridge Rule
2. IAM Role
3. Lambda code
4. EC2 instance created
5. Tags automatically added

## IAM Permissions
- ec2:DescribeInstances
- ec2:CreateTags

## Lambda Code
```python
import boto3
from datetime import datetime

ec2 = boto3.client('ec2')


def lambda_handler(event, context):

    instance_id = event['detail']['instance-id']

    launch_date = datetime.utcnow().strftime('%Y-%m-%d')

    ec2.create_tags(
        Resources=[instance_id],
        Tags=[
            {
                'Key': 'LaunchDate',
                'Value': launch_date
            },
            {
                'Key': 'Environment',
                'Value': 'Dev'
            }
        ]
    )

    print(f'Tagging completed for {instance_id}')
```

## EventBridge Event Pattern
```json
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["running"]
  }
}
```

## Testing
Launch t2.micro or t3.micro instance.
Wait 1-2 minutes.
Verify tags.

## Bonus
Use CloudTrail event data to identify creator and auto-add Owner tag.

---

# Assignment 4: Daily AWS Cost Alert Using Cost Explorer and SNS

## Important Screenshots
1. SNS Topic
2. Email Subscription confirmed
3. IAM Role
4. Lambda code
5. EventBridge schedule
6. SNS email alert received

## Step 1: Create SNS Topic
Topic Name:
aws-cost-alert

Subscribe your email.
Confirm subscription.

## IAM Permissions
- ce:GetCostAndUsage
- sns:Publish

## Lambda Code
```python
import boto3
from datetime import date

sns = boto3.client('sns')
ce = boto3.client('ce', region_name='us-east-1')

THRESHOLD = 50
TOPIC_ARN = 'SNS_TOPIC_ARN'


def lambda_handler(event, context):

    start = date.today().replace(day=1).strftime('%Y-%m-%d')
    end = date.today().strftime('%Y-%m-%d')

    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start,
            'End': end
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost']
    )

    amount = float(
        response['ResultsByTime'][0]
        ['Total']['UnblendedCost']['Amount']
    )

    print('Current Spend:', amount)

    if amount > THRESHOLD:
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject='AWS Cost Alert',
            Message=f'Current spend is ${amount}'
        )

    return {'cost': amount}
```

## EventBridge Schedule
rate(1 day)

## Testing
Set threshold = 0.01
Run Lambda manually.
Verify SNS email.

## Discussion
AWS Budgets is the managed solution. Lambda is preferred when you need service-wise analysis, custom logic, Slack/Teams integration, or anomaly detection.

---

# Submission Checklist

## Assignment 1
- Bucket Created
- Files Uploaded
- Lambda Executed
- Old Files Deleted

## Assignment 2
- Snapshot Created
- Snapshot Tagged
- Cleanup Tested
- EventBridge Added

## Assignment 3
- EventBridge Rule Created
- Lambda Triggered
- Tags Added Automatically

## Assignment 4
- SNS Configured
- Cost Explorer Working
- Email Alert Received
- EventBridge Schedule Added

---

# Cost Optimization

Use:
- Free Tier S3
- Existing EC2 Volume
- t2.micro or t3.micro
- Lambda Free Tier
- SNS Free Tier
- EventBridge Free Tier

Delete test resources after screenshots are taken.