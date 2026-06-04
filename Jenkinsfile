// Declarative pipeline: build, test, push the VAT calculator image, then provision infra.
pipeline {
    // Run on any available Jenkins agent/node.
    agent any

    // Pipeline-wide environment variables (also exported to shell steps).
    environment {
        // Jenkins credential ID for the GCP service-account key file.
        gcpCreds = 'gcp_credentials'
        // Docker Hub login; exposes dockerCreds_USR and dockerCreds_PSW.
        dockerCreds = credentials('dockerhub_login')
        // Target image repo: <dockerhub-user>/vatcal.
        registry = "${dockerCreds_USR}/vatcal"
        // Credential ID used when authenticating to the registry on push.
        registryCredentials = "dockerhub_login"
        // Holds the built image object; populated in the Build stage.
        dockerImage = ""
        // Terraform variables (TF_VAR_* are auto-read by Terraform).
        TF_VAR_gcp_project = "<your project ID from qwiklabs>"
        TF_VAR_docker_registry = "${registry}"
    }

    stages {
        // Install deps and run the test suite; fails the build on test failure.
        stage('Run Tests') {
            steps {
                sh 'npm install'
                sh 'CI=true npm test'
            }
        }

        // Build the Docker image from the repo Dockerfile.
        stage('Build Image') {
            steps {
                script {
                    dockerImage = docker.build(registry)
                }
            }
        }

        // Push the image to the registry under build-number and 'latest' tags.
        stage('Push Image') {
            steps {
                script {
                    docker.withRegistry("", registryCredentials) {
                        dockerImage.push("${env.BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        // Reclaim disk: remove all images older than 48h.
        stage('Clean Up') {
            steps {
                sh "docker image prune --all --force --filter 'until=48h'"
            }
        }

        // Provision/update infrastructure with Terraform using the GCP creds.
        stage('Provision Server') {
            steps {
                script {
                    withCredentials([file(credentialsId: gcpCreds, variable: 'GCP_CREDENTIALS')]) {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS=$GCP_CREDENTIALS
                            terraform init
                            terrascan scan -i terraform -t gcp -d . --non-recursive
                            terrascan scan -i terraform -t gcp -p .
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }
    }
}
