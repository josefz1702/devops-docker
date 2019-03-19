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
              sh 'docker run -it --rm --name devops-docker -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean package'
              sh 'docker build -t devops-docker .'
              sh 'docker run --rm -d -p 8080:8080 --name app devops-docker'
              sh './test/integration_test.sh'
            }
            post {
                success {
                    echo 'Integration test run successfully'
                }
                failure {
                    sh 'docker stop app'
                    sh 'docker rm app'
                    sh 'docker rmi -devops-docker'
                }
            }
        }
        stage('Docker push') {
            agent any
            steps {
              sh 'docker run -it --rm --name devops-docker -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean package'
              sh 'docker build -t ${docker_registry}:${BUILD_NUMBER} .'
              sh 'aws ecr get-login --no-include-email'
              sh 'docker push ${docker_registry}:${BUILD_NUMBER}'
            }
        }
    }
}
