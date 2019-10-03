 pipeline {
  agent any
  environment {
   DOCKER_REPO = 'algmprivsecops'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  triggers {
    // This tells Jenkins to poll for changes in git instead of
    // waiting for webhooks.
    pollSCM('* * * * *')
  }

  stages {
    stage('Docker login') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'algmdockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh '''
                    docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
                '''
          }
      }
    }
    stage('Docker Build') {
      steps {
        sh '''
        make images_build
        '''
      }
    }
    /*
    stage('Start images') {
      steps {
        sh """
        make images_start
        sleep 5s
        """
      }
    }
    stage('Verification') { //This stage needs to be extended - in particular, we should be running a basic site installation to ensure that this base image actually works
      steps {
        sh '''
        make images_test
        '''
      }
    }
    */
    stage('Docker Push') {
    steps {
        sh '''
        make images_publish
        '''
      }
    }
    stage('Docker clean images') {
      steps {
        sh '''
        make images_remove
        '''
      }
    }
    /*
    stage('Docker Push') {
      steps {
        sh '''
        echo "Branch: $GIT_BRANCH"
        docker images | head

        for variant in '' _nginx _php; do
            docker tag denpal$variant amazeeiodevelopment/denpal$variant:$GIT_BRANCH
            docker push amazeeiodevelopment/denpal$variant:$GIT_BRANCH

            if [ $GIT_BRANCH = "develop" ]; then
              docker tag denpal$variant amazeeiodevelopment/denpal$variant:latest
              docker push amazeeiodevelopment/denpal$variant:latest
            fi

        done
        '''
      }
    }
    */
  }
}
