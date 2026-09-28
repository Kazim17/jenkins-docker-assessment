pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'my-assessment-app'
        APP_PORT     = '3000'
        TRIVY_REPORT = 'trivy-report.html'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
    }

    stages {
        stage('1. Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('2. Build & Unit Test') {
            steps {
                sh 'docker build --target builder -t ${DOCKER_IMAGE}:test .'
            }
        }

        stage('3. Build Production Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        stage('4. Trivy Security Scan') {
            steps {
                script {
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                        --format template --template "@contrib/html.tpl" \
                        -o ${TRIVY_REPORT} ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
                    """
                }
            }
        }

        stage('5. Deploy via Docker Compose') {
            steps {
                script {
                    sh """
                        BUILD_NUMBER=${BUILD_NUMBER} \
                        DOCKER_IMAGE=${DOCKER_IMAGE} \
                        APP_PORT=${APP_PORT} \
                        docker-compose up -d --remove-orphans
                    """
                }
            }
        }

        stage('6. Health Check & Verification') {
            steps {
                script {
                    timeout(time: 2, unit: 'MINUTES') {
                        waitUntil {
                            def status = sh(
                                script: "docker inspect --format='{{.State.Health.Status}}' cicd_assessment_app || echo 'starting'",
                                returnStdout: true
                            ).trim()
                            return status == 'healthy'
                        }
                    }
                }
            }
        }
    }

    post {
        failure {
            script {
                sh """
                    PREV_BUILD=\$((\${BUILD_NUMBER} - 1))
                    if [ \$PREV_BUILD -gt 0 ]; then
                        BUILD_NUMBER=\$PREV_BUILD \
                        DOCKER_IMAGE=\${DOCKER_IMAGE} \
                        APP_PORT=\${APP_PORT} \
                        docker-compose up -d
                    fi
                """
            }
        }
        always {
            sh 'docker image prune -f'
            cleanWs()
        }
    }
}
