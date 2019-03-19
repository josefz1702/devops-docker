pipeline {
    agent none

    environment {
	    region = "us-west-2"
      git_repository = "https://github.com/rauccapuclla/devops-docker.git"
      docker_registry = "309160247445.dkr.ecr.us-west-2.amazonaws.com/devops-docker"
    }
    stages {
        stage('build') {
            agent {
               docker { image 'maven:3-alpine' }
            }
            steps {
              git url: "${git_repository}", branch: 'develop'
              sh "mvn clean install -Dmaven.test.skip=true"
            }
        }
        stage('Test') {
            agent {
               docker { image 'maven:3-alpine' }
            }
            steps {
            sh 'mvn clean test'
            }
            post {
            success {
              junit 'target/surefire-reports/**/*.xml'
              }
           }
        }
        stage('Integration Test') {
            agent any
            steps {
              sh 'docker run --rm --name build -v "$(pwd)":/usr/src/app/ -w /usr/src/app/ maven:3.3-jdk-8 ls -la'
            }
            post {
                success {
                    sh 'docker rm build'
                    echo 'Integration test run successfully'
                }
                failure {
                    sh 'docker stop app'
                    sh 'docker rm build'
                    sh 'docker rm app'
                    sh 'docker rmi -devops-docker'
                }
            }
        }
        stage('Docker push') {
            agent any
            steps {
              sh 'docker run --rm --name build -v "$(pwd)":/usr/src/app/ -w /usr/src/app/ maven:3.3-jdk-8 mvn clean package'
              sh 'docker build -t ${docker_registry}:${BUILD_NUMBER} .'
              sh 'aws ecr get-login --no-include-email'
              sh 'docker push "${docker_registry}:${BUILD_NUMBER}"'
            }
            post {
                success {
                    sh 'docker rm build'
                    echo 'Docker image successfully pushed to AWS'
                }
                failure {
                    sh 'docker rm build'
                    sh 'docker rmi "${docker_registry}:${BUILD_NUMBER}"'
                }
            }
        }
    }
}
