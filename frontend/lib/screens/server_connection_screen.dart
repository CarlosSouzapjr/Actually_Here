import 'package:flutter/material.dart';

import '../config/server_config.dart';
import '../services/server_discovery_service.dart';
import 'login.dart';

class ServerConnectionScreen extends StatefulWidget {
  const ServerConnectionScreen({super.key});

  @override
  State<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends State<ServerConnectionScreen> {
  final _discoveryService = const ServerDiscoveryService();
  late final TextEditingController _hostController;
  late final TextEditingController _apiPortController;
  late final TextEditingController _mqttPortController;

  bool _isBusy = false;
  String _status = 'Conecte o celular na mesma rede Wi-Fi do servidor.';

  @override
  void initState() {
    super.initState();
    final endpoint = ServerConfig.current;
    _hostController = TextEditingController(text: endpoint.host);
    _apiPortController = TextEditingController(text: '${endpoint.apiPort}');
    _mqttPortController = TextEditingController(text: '${endpoint.mqttPort}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDiscover());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _apiPortController.dispose();
    _mqttPortController.dispose();
    super.dispose();
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isBusy = true;
      _status = 'Procurando servidor ativo na rede local...';
    });

    final endpoint = await _discoveryService.discover(
      apiPort: _apiPort,
      mqttPort: _mqttPort,
      onProgress: (message) {
        if (mounted) setState(() => _status = message);
      },
    );

    if (!mounted) return;

    if (endpoint == null) {
      setState(() {
        _isBusy = false;
        _status = 'Servidor não encontrado. Informe o IP do PC e teste.';
      });
      return;
    }

    ServerConfig.update(
      host: endpoint.host,
      apiPort: endpoint.apiPort,
      mqttPort: endpoint.mqttPort,
    );

    setState(() {
      _isBusy = false;
      _hostController.text = endpoint.host;
      _apiPortController.text = '${endpoint.apiPort}';
      _mqttPortController.text = '${endpoint.mqttPort}';
      _status = 'Servidor encontrado em ${endpoint.host}.';
    });
  }

  Future<void> _testConnection() async {
    final endpoint = ServerEndpoint(
      host: _hostController.text.trim(),
      apiPort: _apiPort,
      mqttPort: _mqttPort,
    );

    setState(() {
      _isBusy = true;
      _status = 'Testando ${endpoint.host}:${endpoint.apiPort}...';
    });

    final ok = await _discoveryService.testEndpoint(endpoint);

    if (!mounted) return;

    if (ok) {
      ServerConfig.update(
        host: endpoint.host,
        apiPort: endpoint.apiPort,
        mqttPort: endpoint.mqttPort,
      );
      setState(() {
        _isBusy = false;
        _status = 'Conexão confirmada com ${endpoint.host}.';
      });
      return;
    }

    setState(() {
      _isBusy = false;
      _status = 'Não foi possível conectar. Verifique Wi-Fi, IP e firewall.';
    });
  }

  void _continue() {
    ServerConfig.update(
      host: _hostController.text,
      apiPort: _apiPort,
      mqttPort: _mqttPort,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  int get _apiPort => int.tryParse(_apiPortController.text.trim()) ?? 8080;
  int get _mqttPort => int.tryParse(_mqttPortController.text.trim()) ?? 1883;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servidor')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Actually Here',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Encontre o backend ativo na rede local.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _hostController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'IP ou host do servidor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apiPortController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porta API',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _mqttPortController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porta MQTT',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isBusy) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text(_status)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : _autoDiscover,
                icon: const Icon(Icons.radar),
                label: const Text('Procurar na rede'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : _testConnection,
                icon: const Icon(Icons.wifi_find),
                label: const Text('Testar conexão'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _continue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
