# Overview
This repository holds all terraform configuration for deploying the backbone infrastructure of the tbsequencing web platform. This repository must be deployed first, before any other.  

For serving the terraform backend, an AWS hosted backend using S3 and dynamodb is given as example in **backend-example**. However, you can use a local backend for deploying the solution.

## Terraform variables

Use [environment variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables) or a *terraform.tfvars* file to define the required terraform variables described in *variables.tf*.

| variable| default value | description|
|---|---|---|
|project_name|none|Project name. Used as part of the prefix for naming all resources|
|module_name|main|Infrastructure module name. Used as part of the prefix for naming all resources|
|environment|none|Environment identifier. Used as part of the prefix for naming all resources. It will also impact which GitHub Environments can assume the CICD roles.|
|cf_domain|none|Final web address at which service will be available|
|no_reply_email|none||
|aws_region|us-east-1||
|low_cost_implementation|true|See [below](#low-cost-environment) for the comparison of low versus high cost environments|
|chatbot_notifs_implementation|false|Set to true if you want to deploy error notifications to Microsoft Teams|
|gh_action_roles|false|Set this to true to create (github actions) [CICD](#github-actions-cicd) roles for terraform, backend and frontend jobs.  ⚠️Do not set to true if you do not understand the security implications⚠️|
|github_org_name|empty string|Used for setting up which gh organisation can assume the CICD roles. For the current repo, value would be *finddx*|
|github_repo_prefix|empty string|Used for setting up which repos can assume the CICD roles. For the current repo, value would be *tbsequencing*.|

## Low cost environment
The default low cost environment will bill approximately 3 USD per day. If you set *low_cost_implementation* to false, the environment will cost approximately 18 USD. All VAT excluded and for us-east-1.  

The low cost environment has: 

1. no web application firewall (WAF)
2. no private subnet, no NAT Gateway (i.e. all resources sit in public subnets)
3. lower computational resources for RDS, ECS Fargate task, EC2 bastion


# Checklist for deploying
- Admin access to an AWS vanilla account
- Define all [terraform variables](#terraform-variables)
- An AWS Certificate Manager entry with the chosen domain name verified (see [below](#certificate-verification))
- Access to a Microsoft Entra ID tenant to configure authentication via OIDC
- (**Optional**) If you are planning to use CICD, repositories forked to your own platform/organization
    1. infrastructure
    2. ncbi-sync
    3. bioinfoanalysis
    4. frontend
    5. backend
- (**Optional**) Create a [Microsoft Teams Channel](#aws-chatbot---microsoft-teams-notification-set-up) for error notifications. [AWS Secrets](#creating-aws-secrets) will need to be defined before deployment

# Certificate verification
Once you have chosen your future domain name, login into your AWS Account via the WebConsole and browse to AWS Certificate Manager. Go to *List certificate* and verify that you are browsing in the region you want to deploy into.  

Verify the region on the top right corner. Use the request button. On the next step, choose *Request a public certificate*. On the next and final step, input your desired domain name in the *Fully qualified domain name* and keep the default validation method (*DNS verification*) and algorithm selected.  

You will be redirected to the overview of the new certificate request you just created. Its status will be *Pending verification* until the IT services owning the domain validate the certificate via DNS Validation. For this, email your IT services asking them to insert the CNAME name and values that you can retrieve on the certificate page.  

Share these values with your IT services. Once they have inserted the records, the certificate status should promptly be updated to *Issued*.  

## ⚠️ Deploying somewhere else than us-east-1⚠️
**If you are not deploying to us-east-1, you'll need to create two certificates:**

- One in us-east-1
- One in the region you are deploying to

This is because the Cloudfront CDN distribution is a global service and needs its certificate in us-east-1 ([source](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html#https-requirements-certificate-issuer)).

However, your elastic load balancer listener will need a certificate sitting in the region where all your resources will be deployed. You will then need two certificates. 

# AWS Chatbot - Microsoft Teams notification set up

If you want to set notifications up, you must have administrative rights for the Team you want to create a channel in.  

The aws bot must be invited into the team. Follow Step 1 only of this [tutorial](https://docs.aws.amazon.com/chatbot/latest/adminguide/teams-setup.html#teams-client-setup)

Create the channel on the team. Be careful to set the channel type to *Standard*. The aws bot cannot write in private channels.  

Copy the link of the channel. Browse to [AWS Chatbox](https://us-east-1.console.aws.amazon.com/chatbot). Under *Configure a client*, select MS Teams and paste the channel link copied before.  

You will be redirected to authorize access to AWS. If you don't have enough administrative rights to that, reach out to your IT services.  
 
## Creating AWS Secrets

Browse to AWS Secrets Manager. Click *Store a new secret*. On the first page, select *Other type of secret* and add the following three key pair values (everything is case sensitive!) 

| Key| 	Value (bolded in the example channel URL)|
|---|---|
|TENANT_ID|	https://<span></span>teams.microsoft.com/l/channel/**19%3Ae5eace25j32023jga835103358eapge3t8235%40thread.tacv2**/ChannelName?groupId=0d36500a-6023-419c-8c36-7e21f19b0135&tenantId=5fe61832-9f46-403b-a7db-cf9cf2e38199|
|GROUP_ID|	https://<span></span>teams.microsoft.com/l/channel/19%3Ae5eace25j32023jga835103358eapge3t8235%40thread.tacv2/ChannelName?groupId=**0d36500a-6023-419c-8c36-7e21f19b0135**&tenantId=5fe61832-9f46-403b-a7db-cf9cf2e38199|
|CHANNEL_ID|https://<span></span>teams.microsoft.com/l/channel/19%3Ae5eace25j32023jga835103358eapge3t8235%40thread.tacv2/ChannelName?groupId=0d36500a-6023-419c-8c36-7e21f19b0135&tenantId=**5fe61832-9f46-403b-a7db-cf9cf2e38199**|
 
Browse to the *Next* page. Choose as secret name *ms-teams* (case sensitive). Do not change anything else and click *Next* and *Store* until the secret creation.

# Deployment

## Terraform backend
The terraform backend can be deployed using terraform from the local workstation, using the configuration files provided in **backend-example**. Otherwise you can also use a local provider.  

The data.tf holds the few dependencies needed for the deployment :

```
data "aws_secretsmanager_secret" "ms_teams" {
  count = var.chatbot_notifs_implementation ? 1 : 0
  name  = "ms-teams"
}

data "aws_secretsmanager_secret_version" "ms_teams_current" {
  count     = var.chatbot_notifs_implementation ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.ms_teams[0].id
}

data "aws_acm_certificate" "main-region" {
  domain = var.cf_domain
}
```

If you are not deploying to us-east-1, another certificate will be read, in us-east-1 (see [above](#deploying-somewhere-else-than-us-east-1))
 
```
data "aws_acm_certificate" "us-east-1" {
  count    = var.aws_region != "us-east-1" ? 1 : 0
  domain   = var.cf_domain
  provider = aws.useast1
}
```

You can't deploy until the(/both) ACM Certificate status(es) is(/are) *Issued*.
 

# Post deployment of core infrastructure
## RDS database credentials

After deployment, a new managed Secret will be created automatically by AWS. That secret contains the master username/password credentials for access to the RDS. Retrieve these values for the following section.  

Most of the operations on the database need a user with IAM authentication rights so that it can use temporary tokens to log in into the database. 

As this user hasn't been created via terraform , we need to create it manually. The ECS tasks for the backend and migration expects a user called *rdsiamuser*.

We will make use of the bastion host deployed. We can login to the EC2 Bastion via the AWS WebConsole, using EC2 Instance Connect.  
 
Install the postgresql client on the bastion.

```
sudo yum install postgresql15
```

Retrieve from the terraform output the RDS hostname, database port, and from AWS Secrets Manager the master user password.

```
psql -d tbkbdb -U tbkbmasteruser -p ${DATABASE_PORT} -h ${HOST_NAME}
```

Create the user and grant it IAM authentication and grant rights for creation as well :

```
CREATE ROLE rdsiamuser;
GRANT rds_iam TO rdsiamuser;
ALTER USER rdsiamuser WITH login;
GRANT CREATE ON DATABASE tbkbdb TO rdsiamuser;
```

Rotate the master password via AWS Secrets Manager after the user creation. 

## Setting up redirection
After successful deployment, the Cloudfront distribution of your website will be available. You can retrieve the distribution domain name either from the terraform outputs or from the AWS Web Console by browsing to Cloudfront. Share that distribution domain with your IT services, asking them to insert a CNAME record from your chosen domain name to the Cloudfront distribution.  

Share these values with your IT services for a CNAME record insertion.
 
 
## Filling up secret values
AWS Secrets have been created by the infrastructure repository. 

Values must be filled in accordingly via the Web Console for two of them. The secret *django-secret-key* has been filled up automatically and does not need modifying.

|Name|	Keys (case sensitive)|	Description|
|----|-----|----|
|adfs|ADFS_CLIENT_ID|Secrets for configuring Microsoft Entra ID tenant. Described in the backend repository|
|adfs|ADFS_TENANT_ID|Secrets for configuring Microsoft Entra ID tenant. Described in the backend repository.|
|adfs|ADFS_CLIENT_SECRET|Secrets for configuring Microsoft Entra ID tenant. Described in the backend repository.|
|ncbi-entrez|email|Authenticating for NCBI API. These can be requested automatically by registering an account at the NCBI.|
|ncbi-entrez|api_key|Authenticating for NCBI API. These can be requested automatically by registering an account at the NCBI.|

# GitHub Actions CICD

If you set *gh_action_roles* to true, necessary IAM roles have been created so that everything can now be deployed from GitHub Actions.  
For each repository, you will need to create a new environment matching the value of the tf variable *environment*. Only jobs deployed into that environment will be allowed to assume the CICD roles, which are the following:

 
|role name|	allowed reposistory/github environment| permissions|
|---|---|---|
|my-github-actions-frontend| ${github_org_name}/${github_repo_prefix}-frontend:${environment}|copying static files to S3, invalidating files from Cloudfront distribution|
|my-github-actions-backend|${github_org_name}/${github_repo_prefix}-backend:${environment}|pushing docker images to ECR, copying static files to S3, managing ECS tasks|
|my-github-actions-push-glue|${github_org_name}/${github_repo_prefix}-bioinfoanalysis:${environment}|pushing docker images to ECR, copying glue script files to S3|
|my-github-actions-terraform|${github_org_name}/${github_repo_prefix}-infrastructure:${environment} ${github_org_name}/${github_repo_prefix}-bioinfoanalysis:${environment} ${github_org_name}/${github_repo_prefix}-ncbi-sync:${environment} ${github_org_name}/${github_repo_prefix}-antimalware:${environment}|Admin|

You can check our predefined GitHub Actions Workflows jobs [there](https://github.com/finddx/seq-treat-tbkb-github-workflows/)
