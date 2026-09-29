From the `CFT` directory, package the root and nested templates to an existing S3 bucket, then create the stack:

```sh
aws cloudformation package \
  --template-file main.yml \
  --s3-bucket <TEMPLATE_BUCKET> \
  --output-template-file packaged.yml \
  --region us-east-1

aws cloudformation validate-template \
  --template-body file://packaged.yml \
  --region us-east-1

aws cloudformation create-stack \
  --stack-name spendsmart-dev \
  --template-body file://packaged.yml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Inspect status, resources, parameters, events, and outputs:

```sh
aws cloudformation describe-stacks --stack-name spendsmart-dev --region us-east-1 --query 'Stacks[0].StackStatus' --output text
aws cloudformation list-stack-resources --stack-name spendsmart-dev --region us-east-1 --output table
aws cloudformation describe-stacks --stack-name spendsmart-dev --region us-east-1 --query 'Stacks[0].Parameters' --output table
aws cloudformation describe-stack-events --stack-name spendsmart-dev --region us-east-1 --output table
aws cloudformation describe-stacks --stack-name spendsmart-dev --region us-east-1 --query 'Stacks[0].Outputs' --output table
```

For an update, run `aws cloudformation package` again and pass the resulting `packaged.yml` to `aws cloudformation update-stack` with the same parameters and capabilities. Delete the stack with:

```sh
aws cloudformation delete-stack --stack-name spendsmart-dev --region us-east-1
aws cloudformation wait stack-delete-complete --stack-name spendsmart-dev --region us-east-1
```

# 1. Validate the local root template
aws cloudformation create-stack \
  --stack-name spendsmart-dev \
  --template-body file://CFT/main.yml \
  --parameters ParameterKey=Ec2KeyName,ParameterValue=mukesh \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1



# 2. Package the local modules
aws cloudformation package \
  --template-file CFT/main.yml \
  --s3-bucket spendsmart-cfn-packages \
  --output-template-file packaged-template.yaml \
  --region us-east-1

# 3. Deploy
aws cloudformation deploy \
  --stack-name spendsmart-dev \
  --template-file packaged-template.yaml \
  --parameter-overrides Ec2KeyName=mukesh \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# 4. Wait
aws cloudformation wait stack-create-complete \
  --stack-name spendsmart-dev \
  --region us-east-1


# packaged commands

aws cloudformation package \
  --template-file CFT/main.yml \
  --s3-bucket spendsmart-cfn-packages \
  --output-template-file packaged-template.yaml \
  --region us-east-1

  
aws cloudformation deploy \
  --template-file /home/mukesh/Desktop/spendsmart/packaged-template.yaml \
  --stack-name spendsmart-dev \
  --parameter-overrides Ec2KeyName=mukesh \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1