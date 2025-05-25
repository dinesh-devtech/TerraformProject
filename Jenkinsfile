pipeline {
  agent any

  environment {
    REPO_URL = https://github.com/dinesh-devtech/TerraformProject.git
    BRANCH = 'main'
    EC2_USER = 'ec2-user'
    EC2_IP = ''
    EC2_DEPLOY_PATH = '/home/ec2-use/app'
    SSH_CREDENTIAL_ID = 'ec2-key'
    SONARQUBE_ENV = 'MySonarqube'
    SONAR_PROJECT_KEY = 'my-project'
    
  }
  tools {
    maven 'maven3' //defined in jenkins Tools config
  }

  stages {
    stage('Git Checkout') {
      steps {
        git branch: "${BRANCH}", url: "${REPO_URL}"
      }
    }

    stage(Build & Test) {
      steps {
        sh 'mvn clean install'
      }
    }

    stage(Sonarqube Analysis) {
      steps {
        withSonarqubeEnv("${SONARQUBE_ENV}") {
          sh 
            'mvn sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY} -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_AUTH_TOKEN'
           
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time:5, unit:'MINUTES') {
          waitForQualityGate abortPipeline:true
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent (credentials:[SSH_CREDENTIAL_ID]) {
          sh """
            echo "Updating artifact to EC2"
            scp -o StrictHOstKeyChecking=no target/*.jar ${EC2_USER}@${EC2_IP}:${EC2_DEPLOY_PATH}/app.jar
            echo "Restarting application on EC2"
            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << EOF
            # Kill existing java proccess
            pkill -f "java -jar" || true
            # Run new version in Background
            nohup java -jar ${EC2_DEPLOY_PATH}/app.jar > ${EC2_DEPLOY_PATH}/app.log 2>&1 &
            EOF
          """
        }
      }
    }
  }

  post {
    success {
      echo 'Deployment successfull'
    }
    failure {
      echo 'Pipeline Failed'
    }
  }
}
