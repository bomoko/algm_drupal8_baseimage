  parameters {
    booleanParam(name: 'testgit', defaultValue: false, description: 'Should I test the SSH private key for pushing into Git?')
    booleanParam(name: 'cli', defaultValue: false, description: 'Should I rebuild the cli Docker image?')
    booleanParam(name: 'nginx', defaultValue: false, description: 'Should I rebuild the nginx Docker image?')
    booleanParam(name: 'php', defaultValue: false, description: 'Should I rebuild the php Docker image?')
    booleanParam(name: 'debug', defaultValue: false, description: 'Should I enable debug mode for verbose logging?')
  }

    stage('Test Git') {
      when { expression { return params.testgit } }
      steps {
        /* sshagent(credentials : ['denpal']) { */
        withCredentials([sshUserPrivateKey(credentialsId: 'denpal', keyFileVariable: 'KEY_FILE')]) {
          sh '''
          eval `ssh-agent -s`
          ssh-add ${KEY_FILE}
          ssh-add -L
          git commit --allow-empty -m "test withCredentials"
          git push origin feature/Jenkinsfile
          '''
        }
      }
    }
    stage('Git clone') {
      /*
      This is needed for local development, because Jenkins uses locally pasted pipeline code in a textarea box and doesn't know where the Git repo is.
      This also means we have no multibranch, but that's no problem for local development.
      */
      steps {
        git branch: 'feature/Jenkinsfile',
          credentialsId: 'denpal',
          url: 'git@github.com:dennisarslan/denpal.git'
        /*
        git url: 'github.com/dennisarslan/denpal', branch: 'feature/Jenkinsfile'
        */
      }
    }
    stage('Build Image: cli') {
      when { expression { return params.cli } }
      steps {
        sh """
        docker build -t dennisarslan/denpal-cli -f Dockerfile.cli .
        docker push dennisarslan/denpal-cli
        """
      }
    }
    stage('Build Image: nginx') {
      when { expression { return params.nginx } }
      steps {
        sh """
        docker build -t dennisarslan/denpal-nginx -f Dockerfile.nginx --build-arg CLI_IMAGE=dennisarslan/denpal-cli .
        docker push dennisarslan/denpal-nginx
        """
      }
    }
    stage('Build Image: php') {
      when { expression { return params.php } }
      steps {
        sh """
        docker build -t dennisarslan/denpal-php -f Dockerfile.php --build-arg CLI_IMAGE=dennisarslan/denpal-cli .
        docker push dennisarslan/denpal-php
        """
      }
    }
    stage('Debug') {
      when { expression { return params.debug } }
      steps {
        sh """
        docker-compose ps
        docker network list
        docker ps | head
        docker images | head
        docker-compose ps
        docker logs denpal_cli_1
        docker logs denpal_mariadb_1
        docker inspect denpal_php_1  | grep -i DB_
        docker exec denpal_cli_1 mysql -hmariadb -udrupal -pdrupal
        docker-compose logs
        """
      }
    }
    stage('Tagging') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'denpal', keyFileVariable: 'KEY_FILE')]) {
          sh '''
          eval `ssh-agent -s`
          ssh-add ${KEY_FILE}
          ssh-add -L
          git config --global user.name "Dennis Arslan (Jenkins)"
          git config --global user.email "dennis.arslan@amazee.com"
          ./archive/tag_git_repo.sh
          '''
        }
      }
    }
  post {
    always {
      script {
        currentBuild.setDescription("CLI: ${params.cli} - NGINX: ${params.nginx} - PHP: ${params.php}")
      }
      echo 'I will always say Hello again!'
    }
  }