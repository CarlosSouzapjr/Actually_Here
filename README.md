# Actually-Here

Sistema automatizado de controle de frequência acadêmica baseado em proximidade física, utilizando tecnologias de iBeacon (Bluetooth Low Energy), protocolo MQTT para comunicação em tempo real e backend robusto em Spring Boot.

## 📋 Requisitos do Sistema

### Hardware e Permissões
*   **Bluetooth LE (BLE):** Dispositivos móveis devem suportar Bluetooth 4.0 ou superior.
*   **Localização:** Necessária para o escaneamento de dispositivos Bluetooth (requisito do sistema Android/iOS).
*   **Permissões:** O aplicativo solicita acesso a Bluetooth Advertise (Professor), Bluetooth Scan (Aluno) e Localização Fina.

### Ambiente de Desenvolvimento
*   **Docker & Docker Compose:** Para execução do banco de dados e broker MQTT.
*   **Flutter SDK:** Versão ^3.11.5.
*   **JDK 21:** Para execução do backend em Kotlin/Spring Boot.
*   **PostgreSQL 15:** Persistência de dados.
*   **Mosquitto:** Broker de mensagens MQTT.

## 🔄 Fluxos Principais

### 👨‍🏫 Fluxo do Professor (Transmissor)
1.  **Criação de Turma:** O professor cadastra uma nova disciplina via interface Flutter.
2.  **Início da Sessão:** Ao iniciar uma aula, o backend gera uma \`AttendanceSession\`.
3.  **Broadcast iBeacon:** O dispositivo do professor inicia a transmissão de um sinal iBeacon contendo um UUID específico da turma/professor.
4.  **Monitoramento:** O professor recebe atualizações em tempo real via MQTT sobre os alunos que entraram no raio de proximidade.

### 🎓 Fluxo do Aluno (Receptor)
1.  **Entrada em Aula:** O aluno seleciona a aula ativa em seu dispositivo.
2.  **Scan de Proximidade:** O aplicativo inicia a busca pelo sinal iBeacon do professor.
3.  **Cálculo de Distância:** O sinal RSSI é processado para estimar a distância (em metros) entre o aluno e o professor.
4.  **Publicação de Presença:** Caso a distância seja válida (ex: < 5 metros), o app publica "pings" de presença no tópico MQTT \`presenca/{classId}/{studentId}\` em intervalos regulares.

## 🚀 Próximos Passos (Roadmap)

### 1. Infraestrutura e Comunicação
- [x] Configurar Broker MQTT (Mosquitto) no Docker.
- [x] Implementar cliente MQTT base no Frontend.
- [ ] Implementar cliente MQTT no Backend para consumo de pings.
- [ ] Configurar persistência histórica de mensagens MQTT.

### 2. Gestão de Dados e Persistência
- [x] Definição de entidades base no Backend (Class, User).
- [ ] Implementar cache local (SQLite) no Flutter para funcionamento offline parcial.
- [ ] Gerenciamento dinâmico de UUIDs de Beacon por turma.
- [ ] Sincronização automática entre banco local e remoto.

### 3. Inteligência de Frequência
- [ ] Algoritmo de validação de presença (mínimo de X pings recebidos durante a aula).
- [ ] Dashboard de frequência para professores com gráficos de tempo de permanência.
- [ ] Sistema de tolerância por distância configurável por disciplina.

### 4. Segurança e Identidade
- [ ] Integração com Provedor de Identidade (OIDC/Auth0).
- [ ] Criptografia de payloads MQTT para evitar spoofing de presença.
- [ ] Validação de geofencing (opcional) em conjunto com o Bluetooth.

### 5. Reconhecimento Facial
- [ ] PoC de check-in inicial via reconhecimento facial (Google ML Kit).
- [ ] Integração do token de face com o ID do aluno no ping de presença.

## 🛠️ Instruções de Configuração de Serviços

### Inicialização da Infraestrutura
Certifique-se de que o Docker está rodando e execute:
\`\`\`bash
docker compose up -d
\`\`\`

### Configuração de Ambiente (Frontend)
Crie um arquivo \`.env\` na raiz da pasta \`frontend/\` seguindo o modelo:
\`\`\`env
SERVER_IP=192.168.x.x
API_PORT=8080
MQTT_PORT=1883
\`\`\`
*Nota: Utilize o IP da sua máquina na rede local para testes em dispositivos físicos.*

### Execução do Backend
\`\`\`bash
cd backend
./gradlew bootRun
\`\`\`

### Execução do Frontend
\`\`\`bash
cd frontend
flutter pub get
flutter run
\`\`\`
