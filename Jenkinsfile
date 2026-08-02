pipeline {
    agent any

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'uat', 'prod'],
            description: 'Select Environment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform Action'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Git branch'
        )
        string(
            name: 'AMI_ID',
            defaultValue: '',
            description: 'AMI ID to deploy (required for plan/apply, ignored for destroy)'
        )
    }

    stages {

        stage('Show Selected AMI') {
            steps {
                echo "Selected AMI: ${params.AMI_ID}"
            }
        }

        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: "*/${params.BRANCH}"]],
                    userRemoteConfigs: [[url: 'https://github.com/akashmhetre12/Devops_project-nexus-jenkins-sonarqube.git']]
                )
            }
        }

        stage('Validate AMI ID') {
            when {
                expression { params.ACTION != 'destroy' }
            }
            steps {
                script {
                    if (!params.AMI_ID?.trim()) {
                        error "AMI_ID parameter is required for ${params.ACTION}"
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                terraform init -reconfigure \
                -backend-config="key=${params.ENV}/terraform.tfstate"
                """
            }
        }

        stage('Terraform Action') {
            steps {
                script {
                    def tfvarsFile = "envs/${params.ENV}.tfvars"

                    if (params.ACTION == 'plan') {
                        echo "Running PLAN for ${params.ENV}"
                        sh """terraform plan -var-file=${tfvarsFile} -var="ami_id=${params.AMI_ID}" """
                    }
                    else if (params.ACTION == 'apply') {
                        echo "Running APPLY for ${params.ENV}"
                        sh """terraform apply -auto-approve -var-file=${tfvarsFile} -var="ami_id=${params.AMI_ID}" """
                    }
                    else if (params.ACTION == 'destroy') {
                        echo "Running DESTROY for ${params.ENV}"
                        sh """terraform destroy -auto-approve -var-file=${tfvarsFile} -var="ami_id=${params.AMI_ID}" """
                    }
                    else {
                        error "Unknown ACTION: ${params.ACTION}. Expected plan, apply, or destroy."
                    }
                }
            }
        }
    }
}