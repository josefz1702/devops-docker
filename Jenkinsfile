pipeline {

    agent none

    environment {
	    AWS_DEFAULT_REGION = "us-west-2"
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
              sh 'docker run --network="host" --rm -d -p 32000:8080 --name app "${docker_registry}:${BUILD_NUMBER}"'
              sh './tests/integration_test.sh'
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
                docker.build('"${docker_registry}:${BUILD_NUMBER}"')
                docker.withRegistry('https://309160247445.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:aws') {
                  docker.image('"${docker_registry}:${BUILD_NUMBER}"').push('${BUILD_NUMBER}')
                  docker.image('"${docker_registry}:${BUILD_NUMBER}"').push('latest')
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
          steps {
          withCredentials(
                [[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    credentialsId: 'aws',  // ID of credentials in Jenkins
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

          sh '''
            AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            sed -e  's;app_image;${docker_registry}:${BUILD_NUMBER};g' app.json
            '''

          sh '''                                  \
            aws ecs register-task-definition  --family ${taskFamily} --cli-input-json app.json
            '''

          def taskRevision = sh (
            returnStdout: true,
            script: '''
              aws ecs describe-task-definition  --task-definition ${taskFamily} | egrep 'revision' | tr ',' ' ' | awk '{print \$2}'
            '''
          ).trim()

          sh '''
            aws ecs update-service  --cluster ${clusterName}                        \
                                    --service ${serviceName}                        \
                                    --task-definition ${taskFamily}:${taskRevision} \
                                    --desired-count 1                               \
            '''
          }
         }
        }
    }
}
