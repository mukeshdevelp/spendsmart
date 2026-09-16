@Library('spendsmart-shared-lib') _
properties([
    parameters([
        choice(
            name: 'TERRAFORM_ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose the Terraform action to perform (apply or destroy).'
        )
    ])
])

node {
    terraformInfra(
        awsRegion: 'us-east-1',
        terraformDir: 'spendsmart',
        stateBucketName: 'spendsmart-terraform-state',
        stateKey: 'aws/infra/terraform.tfstate',
        awsCredentialId: 'aws-creds'
    )
}