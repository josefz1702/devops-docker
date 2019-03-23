pipeline {

    agent none

    environment {
	    AWS_DEFAULT_REGION = "us-west-2"
      git_repository = "https://github.com/rauccapuclla/devops-docker.git"
      docker_registry = "309160247445.dkr.ecr.us-west-2.amazonaws.com/devops-docker"
      sonarhost = credentials('sonarhost')
      sonarkey = credentials('sonar')
      
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
        stage('Sonarqube Analysis') {
            agent {
               docker { image 'maven:3-alpine' }
            }
            steps {
            sh 'mvn sonar:sonar -Dsonar.host.url=${sonarhost} -Dsonar.login=${sonarkey}'
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
              sh 'docker run --rm --name build -w /var/jenkins_home/jobs/spring-boot-pipeline/workspace --volumes-from jenkins maven:3.3-jdk-8 mvn clean package -Dmaven.test.skip=true'
              sh 'docker build -t "${docker_registry}:${BUILD_NUMBER}" .'
              sh 'docker run --rm -d -p 32000:8080 --name app "${docker_registry}:${BUILD_NUMBER}"'
            }

            post {
                success {
                  echo 'Integration test run successfully !!!'
                  sh 'docker stop app'
                }
                failure {
                  echo 'Integration test failure'
                  sh 'docker stop app'
                }
            }
        }

        stage('Docker push') {
            agent any
            steps {
              script{
                docker.withRegistry('https://309160247445.dkr.ecr.us-west-2.amazonaws.com', 'aws') {
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
