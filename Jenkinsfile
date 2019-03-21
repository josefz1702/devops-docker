pipeline {

    agent none

    environment {
	    AWS_DEFAULT_REGION = "us-west-2"
      git_repository = "https://github.com/rauccapuclla/devops-docker.git"
      docker_registry = "309160247445.dkr.ecr.us-west-2.amazonaws.com/devops-docker"
      cluster="mycluster"
      service="app-service"
      taskFamily="app-task"

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
              sh 'docker run --rm --name build -w /var/jenkins_home/workspace/devops-docker --volumes-from jenkins maven:3.3-jdk-8 mvn clean package -Dmaven.test.skip=true'
              sh 'docker build -t "${docker_registry}:${BUILD_NUMBER}" .'
              sh 'docker run --rm -d -p 32000:8080 --name app "${docker_registry}:${BUILD_NUMBER}"'
              sh './tests/integration_test.sh 54.202.122.79 32000'
            }

            post {
                success {
                  echo 'Integration test run successfully !!!'
                }
                failure {
                  echo 'Integration test failure'
                }
            }
        }

        stage('Docker push') {
            agent any
            steps {
              script{
                docker.withRegistry('https://309160247445.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:aws') {
                  dockerImage=docker.build("${docker_registry}:${BUILD_NUMBER}")
                  dockerImage.push()
                }
              }
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

        stage('Deploy'){
          agent any
          steps {
          withCredentials(
                [[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    credentialsId: 'aws',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

          sh """
            AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            sed -e  "s;app_image;${docker_registry}:${BUILD_NUMBER};g" app.json > app-deployment.json
            """

          sh "aws ecs register-task-definition --family ${taskFamily} --cli-input-json file://\$(pwd)/app-deployment.json"

          sh """
            aws ecs update-service  --cluster ${cluster} --service ${service} --task-definition ${taskFamily} --desired-count 1
            """
          }
         }
        }
    }
}
