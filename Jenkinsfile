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
              sh 'docker run --rm --name build -w /var/jenkins_home/workspace/devops-docker --volumes-from jenkins maven:3.3-jdk-8 mvn clean package'
              sh 'docker build -t "${docker_registry}:${BUILD_NUMBER}" .'
              sh 'docker run --network="host" --rm -d -p 8080:8080 --name app "${docker_registry}:${BUILD_NUMBER}"'
              sh './tests/integration_test.sh'
            }

            post {
                success {
                  echo 'Integration test run successfully !!!'
                  sh 'docker stop app'
                  sh 'docker rm app'
                  sh 'docker rmi "${docker_registry}:${BUILD_NUMBER}"'
                }
                failure {
                    sh 'docker stop app'
                    sh 'docker rm build'
                    sh 'docker rm app'
                    sh 'docker "${docker_registry}:${BUILD_NUMBER}"'
                }
            }
        }

        stage('Docker push') {
            agent any
            steps {
              docker.build('"${docker_registry}:${BUILD_NUMBER}"')
              docker.image('"${docker_registry}:${BUILD_NUMBER}"').push('${BUILD_NUMBER}')
              docker.image('"${docker_registry}:${BUILD_NUMBER}"').push('latest')
            }
            post {
                success {
                    echo 'Docker image successfully pushed to AWS'
                }
                failure {
                    echo 'Error pushing to AWS ECR'
                }
            }
        }
    }
}
