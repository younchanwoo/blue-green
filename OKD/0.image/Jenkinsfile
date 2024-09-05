pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'sessioncookieapp:latest'
        CONTAINER_NAME = 'tomcat_sessioncookieapp'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/younchanwoo/Jenkins.git'
            }
        }

        stage('Build Podman Image') {
            steps {
                script {
                    // Dockerfile을 사용하여 이미지를 빌드합니다.
                    sh 'podman build --no-cache -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    // 기존 컨테이너가 있으면 종료 및 삭제
                    def containerExists = sh(script: "podman ps -aq -f name=${CONTAINER_NAME}", returnStdout: true).trim()
                    if (containerExists) {
                        sh "podman stop ${CONTAINER_NAME} || true"
                        sh "podman rm -f ${CONTAINER_NAME} || true"
                    }
                    
                    // 컨테이너를 실행
                    sh 'podman run -d --restart unless-stopped -p 8080:8080 --name ${CONTAINER_NAME} ${DOCKER_IMAGE}'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
            sh 'podman ps -a'
            sh 'podman images'
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed. Check the logs for details.'
            sh "podman logs ${CONTAINER_NAME}"
        }
    }
}
