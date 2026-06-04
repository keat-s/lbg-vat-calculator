pipeline {
    // Run this pipeline on any available Jenkins agent.
    agent any

    environment {
        // Load Docker Hub credentials stored in Jenkins as "dockerhub_login".
        dockerCreds = credentials('dockerhub_login')

        // Build the target Docker image name from the Docker Hub username.
        registry = "${dockerCreds_USR}/vatcal"
        registryCredentials = "dockerhub_login"

        // Holds the built Docker image so later stages can push it.
        dockerImage = ""
    }

    stages {
        stage('Run Tests') {
            steps {
                // Install dependencies and run the test suite in CI mode.
                sh 'npm install'
                sh 'CI=true npm test'
            }
        }

        stage('Build Image') {
            steps {
                script {
                    // Build the Docker image from the repository Dockerfile.
                    dockerImage = docker.build(registry)
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    // Authenticate to Docker Hub and publish both immutable and latest tags.
                    docker.withRegistry("", registryCredentials) {
                        dockerImage.push("${env.BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage('Clean Up') {
            steps {
                // Remove old local Docker images from the Jenkins agent to save disk space.
                sh "docker image prune --all --force --filter 'until=48h'"
            }
        }
    }
}
