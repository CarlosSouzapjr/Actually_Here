# Inicializar Serviço Backend
Subir container docker (inicialização do banco de dados):
```bash
docker compose up -d
```


Ir para a pasta do backend:
```bash
cd ./backend
```

Executar o comando do Gradle Wrapper para abrir o servidor:

```bash
./gradlew bootRun   
```