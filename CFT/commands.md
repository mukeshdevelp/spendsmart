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