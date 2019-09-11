 pipeline {
  agent any
  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  environment {
    DOCKER_USERNAME = credentials('amazeeiojenkins-dockerhub-username') //These are set in Jenkins itself
    DOCKER_PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
  }
  stages {
   /* Below are the default Denpal stages, we'll recreate these
    stage('Docker login') {
      steps {
        sh '''
        docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
        '''
      }
    }
    stage('Docker Build') {
      steps {
        sh '''
        docker network create amazeeio-network || true
        docker-compose config -q
        docker-compose down
        docker-compose up -d --build "$@"
        '''
      }
    }
    stage('Waiting') {
      steps {
        sh """
        sleep 5s
        """
      }
    }
    stage('Verification') {
      steps {
        sh '''
        docker-compose exec -T cli drush status
        docker-compose exec -T cli curl http://nginx:8080 -v
        if [ $? -eq 0 ]; then
          echo "OK!"
        else
          echo "FAIL"
          /bin/false
        fi
        docker-compose down
        '''
      }
    }
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
