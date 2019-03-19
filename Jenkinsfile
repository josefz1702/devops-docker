pipeline {
    agent any
    environment {
	    region = "us-west-2"
      git_repository = "https://github.com/rauccapuclla/devops-docker.git"
      docker_registry =
    }
    stages {
        stage('build') {
            steps {
            git url: ${git_repository}, branch: 'develop'
            sh "docker run -it --rm --name devops-docker -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean install"
            }
        }
        stage('Test') {
            steps {
            sh "docker run -it --rm --name devops-docker -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean test"
            }
        }
        stage('Integration Test') {
            steps {
            //Install npm

            }
        }
        stage('Docker push') {
            steps {
            sh "docker run -it --rm --name devops-docker -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-8 mvn clean package"
            sh "docker build -t ${docker_registry}:${BUILD_NUMBER} ."
            sh "aws ecr get-login --no-include-email"
            sh "docker push ${docker_registry}:${BUILD_NUMBER}"
            }
        }
    }
}
