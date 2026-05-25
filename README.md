# Actually-Here

Sistema de automação de frequência escolar utilizando proximidade (iBeacon), MQTT e Spring Boot.

## 🚀 Próximos Passos (Roadmap)

### 1. Infraestrutura e Comunicação
- [x] Configurar Broker MQTT (Mosquitto) no Docker.
- [ ] Implementar cliente MQTT no Backend (Spring Boot).
- [ ] Implementar cliente MQTT no Frontend (Flutter).
- [ ] Adicionar Zookeeper para coordenação distribuída.

### 2. Lógica de Sessão de Chamada
- [ ] Criar entidade `AttendanceSession` no backend.
- [ ] Implementar endpoints para Professor Iniciar/Encerrar chamada.
- [ ] Desenvolver lógica de expiração automática de sessão.

### 3. Frequência em Tempo Real
- [ ] Fluxo de publicação de "pings" de presença do Aluno (Flutter -> MQTT).
- [ ] Consumo e persistência dos pings no Backend.
- [ ] Algoritmo de cálculo de percentual de presença baseado no tempo da aula.

### 4. Segurança e Identidade
- [ ] Integração com Auth0 no Backend.
- [ ] Fluxo de Login (OIDC) no Flutter.
- [ ] Proteção de rotas e tópicos MQTT.

### 5. Reconhecimento Facial
- [ ] Pesquisa e PoC com Google ML Kit (Flutter).
- [ ] Integração do check-in facial no fluxo de presença.

---

## 🛠️ Como Executar

### Inicializar Serviços (Docker)
```bash
docker compose up -d
```

### Backend (Spring Boot)
```bash
cd ./backend
./gradlew bootRun
```

### Frontend (Flutter)
```bash
cd ./frontend
flutter run
```
