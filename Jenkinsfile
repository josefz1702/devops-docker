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
              sh 'docker run --rm --network=host --name build -v /var/jenkins_home:/var/jenkins_home maven:3.3-jdk-8 mvn clean package -Dmaven.test.skip=true'
              sh 'docker build -t "${docker_registry}:${BUILD_NUMBER}" .'
              sh 'docker run --rm -d -p 8080:8080 --name app "${docker_registry}:${BUILD_NUMBER}"'
              sh 'apt-get install -y curl'
              sh 'apt-get install -y aws-cli'
              sh './test/integration_test.sh'
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
