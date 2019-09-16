 pipeline {
  agent {
    docker {
      image cli
      args '--tmpfs /.config'
    }
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
        if [ ! "$(docker network inspect amazeeio-network | grep amazeeio-network)" ]; then
      		docker network create amazeeio-network || true
      	else
        	echo "amazeeio-network network exists."
      	fi
        docker-compose config -q
        docker-compose down
        DOCKER_REPO=algmprivsecops BUILDTAG=latest docker-compose up -d --build
        '''
      }
    }
    stage('Docker Push') {
    steps {


        sh '''
        #variables we need
        #tag - if any
        #Branch

        '''
      }
    }
   /* Below are the default Denpal stages, we'll recreate these
    stage('Waiting') {
      steps {
        sh """
        sleep 5s
        """
      }
    }
    */
    stage('Verification') { //This stage needs to be extended - in particular, we should be running a basic site installation to ensure that this base image actually works
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

        // Install drupal db.
        docker-compose exec cli drush site-install --verbose config_installer config_installer_sync_configure_form.sync_directory=/config/sync/ --yes
        docker-compose exec cli drush cr
        docker-compose exec cli drush uli

        docker-compose down
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
