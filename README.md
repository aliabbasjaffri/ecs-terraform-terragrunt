# ecs-terraform-terragrunt
This repository contains terraform code to deploy a simple ghost api container on ECS Fargate cluster with an application load balancer and autoscaling group

## Methodology
- I am using [terraform](https://www.terraform.io/) and [terragrunt](https://terragrunt.gruntwork.io/) for expressing the infrastructure resources in AWS cloud.
- `terraform` is used to express resources in the cloud using its `aws` provider whereas `terragrunt` is being used to keep the `terraform` code clean and dry of configuration.
- I would be creating all resources, including VPC and subnets, routing and internet gateways, so that a dedicated, isolated environment can be established for the task.
- `terragrunt` allows a single click deployment of all terraform code, using `terragrunt run-all apply` that can detect changes in the `terragrunt` configuration and apply the diff.
- `terragrunt` allows code to be organised in a heirarchical manner so that resources can be organised.

## Prerequisites
__NOTE__: These instructions are for Linux
- `aws`: v2.0

    ```bash
    sudo apt install unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```
- `terraform`: v1.2.1

    ```bash
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install terraform==1.2.1
    ```
- `terragrunt`: v0.37.1

    ```bash
    TERRAGRUNT_VERSION=0.37.1
    wget https://github.com/gruntwork-io/terragrunt/releases/download/v$TERRAGRUNT_VERSION/terragrunt_linux_amd64
    chmod +x terragrunt_linux_amd64
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
    ```

## Infrastructure deployment and testing
- Please configure your `aws` credentials by running `aws configure` after installing the cli utility.
- After that, please cd into the `terragrunt/` folder, and execute, `terragrunt run-all apply` command. `terragrunt` with the help of `terraform` would detect that the configuration was never applied and would print out a plan of deployment. Please enter `y` followed by enter to proceed. It will take few minutes for the entire deployment to be complete.
- The application load balancer DNS name acts as a test-endpoint for the deployment. The DNS endpoint, `alb_url`, is emitted as an output during the `aws_alb` deployment.
- Please copy the DNS endpoint and enter it in a browser, followed by the port, `80` in the format, `alb_url:80`.

## Folder Structure
- Folder structure of my code is as follows:

    ```bash
    ├── README.md
    ├── terraform
    │   ├── aws_alb
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── ecs_application
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── ecs_cluster
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── vpc_subnet_module
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── terragrunt
        ├── base-infrastructure
        │   ├── dev
        │   │   ├── aws_alb
        │   │   │   └── terragrunt.hcl
        │   │   ├── ecs_application
        │   │   │   └── terragrunt.hcl
        │   │   ├── ecs_cluster
        │   │   │   └── terragrunt.hcl
        │   │   ├── stage.hcl
        │   │   └── vpc_subnet_module
        │   │       └── terragrunt.hcl
        │   └── staging
        ├── root-config.hcl
        └── terragrunt.hcl
    ```
- Every terraform resource has a corresponding `terragrunt.hcl` configuration stored in terragrunt folder. This allows all resources to be created and configured indepenedently of each other.
- In this project, we created resources only for a `dev` environment. We can always extend this project for other environments (`staging` and `production`) by creating their respective terragrunt configurations.
- Code for `ecs_application` does not belong in `base_infrastructure` rather in a `application` folder at the same level as `base_infrastructure`. This would have looked as follows:

    ```bash
    |── terragrunt
    ├── applications
    │   └── ecs_application
    │       └── terragrunt.hcl
    ├── base-infrastructure
    │   ├── dev
    │   │   ├── aws_alb
    │   │   │   └── terragrunt.hcl
    │   │   ├── ecs_cluster
    │   │   │   └── terragrunt.hcl
    │   │   ├── stage.hcl
    │   │   └── vpc_subnet_module
    │   │       └── terragrunt.hcl
    │   └── staging
    ├── root-config.hcl
    └── terragrunt.hcl
    ```
    I was unable to do this during the challenge because i was running under time constraint after resolving an annoying issue on the way.

## Future improvements
- [pre-commit](https://pre-commit.com/) hook could be installed and configured to format and lint the code (`terragrunt hclfmt` and `terraform fmt -recursive`) before committing it to the git repo.
- The code can be tested for validity, using `terragrunt validate` prior to being pushed into the git repo.
- This project could be set to have its own domain, which can be registered using [AWS Route53](https://aws.amazon.com/route53/). This domain can serve as a static endpoint through which the `ghost` application can be reached directly.
- The project could be set to be available at `HTTPS` endpoint, using an SSL certificate generated by [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) against the domain issued via the `Route53`
- Automated autoscaling of tasks could be configured using [aws_appautoscaling_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) and [aws_appautoscaling_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) resources.
- A dockerfile for the application could be added to the `terragrunt/applications/ecs_application` folder which would be built, using [docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest) provider and deployed to `Fargate`.