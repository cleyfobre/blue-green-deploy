pipeline {
    agent any

    environment {
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build image') {
            steps {
                sh "ls -al"
                sh "sudo docker image prune --filter until=12h -f"
                sh "sudo docker build --no-cache --build-arg MODE=prod -t yangcheon-road-api:${env.BUILD_NUMBER} ."
                sh "sudo docker tag yangcheon-road-api:${env.BUILD_NUMBER} yangcheon-road-api:latest"
            }
        }

        stage('Deploy ECR') {
            steps {
                sh 'rm  ~/.dockercfg || true'
                sh 'rm ~/.docker/config.json || true'
                script {
                    docker.withRegistry('https://087124035214.dkr.ecr.ap-northeast-2.amazonaws.com', 'ecr:ap-northeast-2:jenkinsCredentials') {
                        docker.image("yangcheon-road-api:${env.BUILD_NUMBER}").push()
                        docker.image("yangcheon-road-api:latest").push()
                    }
                }
            }
        }

        stage('Remove image') {
            steps {
                sh '''
                    sudo docker rmi -f `docker images | awk '$1 ~ /yangcheon/ {print $3}'`
                '''
            }
        }

        stage('Send deploy files') {
            steps {
                sh "sudo sed -i 's/:latest/:${env.BUILD_NUMBER}/' ./deploy/docker-compose.blue.yml"
                sh "sudo sed -i 's/:latest/:${env.BUILD_NUMBER}/' ./deploy/docker-compose.green.yml"
                sh 'sudo scp -i /home/ubuntu/plkdev.pem -r ./deploy ubuntu@172.31.24.241:/home/ubuntu/backend'
            }
        }

        stage('Deploy') {
            steps{
                sh 'sudo ssh -i /home/ubuntu/plkdev.pem ubuntu@172.31.24.241 -T "cd /home/ubuntu/backend/deploy | sh /home/ubuntu/backend/deploy/setting.sh | aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 087124035214.dkr.ecr.ap-northeast-2.amazonaws.com | sh /home/ubuntu/backend/deploy/deploy.sh"'
            }
        }

        stage('Remove caches created by docker') {
            steps{
                sh 'sudo docker system prune -af'
            }
        }
    }
}