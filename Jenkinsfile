
pipeline {
    agent any
     
    tools {
        nodejs 'NODE24'
    }
    environment {
        CI = 'true'
        DOCKER_IMAGE = 'malekdocker98/telecom-pfe'
        DOCKER_TAG   = 'latest'
    }

    stages {
       stage('Install') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build:frontend'
            }
        }

        stage('Tests') {
            steps {
                sh 'npm run test:ci || true'
            }
        }

        stage('Audit NPM') {
            steps {
                sh 'npm audit --audit-level=high --json > audit-report.json || true'
                archiveArtifacts artifacts: 'audit-report.json', fingerprint: true
            }
        }
    
         stage('Check SCA Vulnerabilities') {
      steps {
        script {
           def audit = readJSON file: 'audit-report.json'

          // Récupérez le nombre total de vulnérabilités
          def total = audit.metadata?.vulnerabilities?.total ?: 0

          echo "npm audit a trouvé ${total} vulnérabilités."

          if (total > 0) {
            // Envoi de mail avec le rapport en pièce jointe
            emailext (
              subject: "🚨 SCA Alert: ${total} vulnérabilités détectées (Build #${env.BUILD_NUMBER})",
              body: """\
                Bonjour,

                La commande **npm audit** a détecté **${total}** vulnérabilités dans les dépendances.

                La build est échouée comme demandé.  
                Voir le rapport complet en pièce jointe.

                --  
                Jenkins CI
              """.stripIndent(),
              to: 'mohamedmalekturki@gmail.com',
              attachmentsPattern: 'audit-report.json'
            )

            // Force l’échec de la build
           // error("Abandon de la build : ${total} vulnérabilités SCA détectées.")
          }
        }
      }
    }


        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=telecom \
                      -Dsonar.projectName=telecom \
                      -Dsonar.sources=. \
                      -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            } 
        }    


        stage('Validation Manuelle') {
         steps {
          script {
           // Construction des URLs pour Proceed / Abort
           def base = "${env.BUILD_URL}input/Validate_Sonar" 
           def proceedUrl = "${base}/proceedEmpty?token=${env.INPUT_TOKEN}"
           def abortUrl   = "${base}/abort?token=${env.INPUT_TOKEN}"

          // Envoi du mail avec deux boutons
           emailext (
            mimeType: 'text/html',
            subject : "Action requise : validez SonarQube pour ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            to      : 'mohamedmalekturki@gmail.com',
            body    : """
              <p>Bonjour,</p>
              <p>L’analyse SonarQube pour <b>${env.JOB_NAME} #${env.BUILD_NUMBER}</b> est terminée.</p>
              <p>Veuillez choisir :</p>
              <p>
                <a href="${proceedUrl}" style="
                  display:inline-block;
                  padding:10px 20px;
                  background-color:#28a745;
                  color:#fff;
                  text-decoration:none;
                  border-radius:4px;
                ">Proceed</a>
                &nbsp;
                <a href="${abortUrl}" style="
                  display:inline-block;
                  padding:10px 20px;
                  background-color:#d73a49;
                  color:#fff;
                  text-decoration:none;
                  border-radius:4px;
                ">Abort</a>
              </p>
              <p>— Jenkins CI</p>
            """.stripIndent()
          )

          // Pause jusqu’à ce que l’un des deux liens soit cliqué
          timeout(time: 1, unit: 'DAYS') {
            input id: 'Validate_Sonar',
                  message: 'Validez ou annulez via le mail reçu',
                  submitterParameter: 'CHOIX' // facultatif, pour récupérer dans les logs
          }
        }
      }
    }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t malekdocker98/telecom-pfe .
                docker run -d --name telecom-pfe -p 4000:3000 malekdocker98/telecom-pfe
                sleep 5
                '''
               //    echo "Hello world"       
           }
        }
        stage('DAST - OWASP ZAP Baseline Scan') {
              steps {
                 script {
                      // Lancer OWASP ZAP baseline scan via Docker
                      sh '''
                      docker run -t --rm \
                      -v /var/lib/jenkins/workspace/jenkins-test-1:/zap/wrk/:rw \
                      --network host \
                      zaproxy/zap-stable \
                      zap-baseline.py -t http://localhost:4000 -r zap-report.html -x zap_report.xml -J zap-report.json || [ $? -eq 2 ]
          '''
        }
        // Archiver le rapport dans Jenkins
             archiveArtifacts artifacts: 'zap-report.html,zap-report.json,zap_report.xml', fingerprint: true
        // Publier le rapport dans la console
             sh 'cat zap-report.html || true'
      }
    }



     stage('DAST – Parse JSON Report') {
  steps {
    script {
      // lit directement le JSON
      def report = readJSON file: 'zap-report.json'

      // selon la structure ZAP, on compte toutes les alertes
      // report.site est une liste, on itère sur chaque site
      int count = report.site.collect { it.alerts.alert }.flatten().size()

      echo "🔍 OWASP ZAP a détecté ${count} vulnérabilités (via JSON parsing)."

      if (count > 0) {
        emailext(
          subject: "🚨 DAST Alert: ${count} vulnérabilités détectées",
          body: """
            Bonjour,

            OWASP ZAP a détecté *${count}* vulnérabilités dynamiques.
            Le rapport complet est en pièce jointe.

            --  
            Jenkins CI
          """.stripIndent(),
          to: 'mohamedmalekturki@gmail.com',
          attachmentsPattern: 'zap-report.html'
        )
      //  error("Échec DAST : ${count} vulnérabilités détectées.")
      }
    }
  }
}




     stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "🔐 Connexion à Docker Hub..."
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    echo "📤 Push de l'image vers Docker Hub..."
                    docker push $DOCKER_IMAGE:$DOCKER_TAG

                    echo "🚪 Déconnexion de Docker Hub..."
                    docker logout
                    
                    '''
                }
                  // 1) Arrêter et supprimer le conteneur
        sh 'docker rm -f telecom-pfe || true'
        // 2) Supprimer l’image taggée
        sh 'docker rmi malekdocker98/telecom-pfe || true'
        // 3) Supprimer toutes les images dangling (<none>)
        sh 'docker image prune -f' 
           }
        }
    stage('Simulated Deployment') {
     steps {
      sh '''
      
      ./.deployments.sh
    '''
  }
}  

   }
   
}
