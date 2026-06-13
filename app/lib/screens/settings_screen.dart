import 'package:flutter/material.dart';

import '../config.dart';
import '../models.dart';
import '../storage.dart';

/// Settings: AI provider (+ key/model), backend URL, and level.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _urlController = TextEditingController(text: Config.baseUrl);
  final _modelController = TextEditingController();
  final _keyController = TextEditingController();

  Provider _provider = Provider.ollama;
  String? _level;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _provider = await Storage.getProvider();
    _level = await Storage.getLevel();
    await _loadProviderFields();
    setState(() => _loading = false);
  }

  Future<void> _loadProviderFields() async {
    _modelController.text = await Storage.getModel(_provider) ?? '';
    _keyController.text = await Storage.getApiKey(_provider) ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _onProviderChanged(Provider p) async {
    // Persist what's typed for the current provider before switching.
    await _saveProviderFields();
    setState(() => _provider = p);
    await Storage.setProvider(p);
    await _loadProviderFields();
    setState(() {});
  }

  Future<void> _saveProviderFields() async {
    await Storage.setModel(_provider, _modelController.text.trim());
    await Storage.setApiKey(_provider, _keyController.text.trim());
  }

  Future<void> _save() async {
    await Config.setBaseUrl(_urlController.text);
    await Storage.setProvider(_provider);
    await _saveProviderFields();
    if (_level != null) await Storage.setLevel(_level!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Guardado.')));
  }

  String get _modelHint => switch (_provider) {
        Provider.ollama => 'ej. qwen2.5:7b, llama3.1 (vacío = el del servidor)',
        Provider.anthropic => 'ej. claude-opus-4-8 (vacío = por defecto)',
        Provider.openai => 'ej. gpt-4o-mini (vacío = por defecto)',
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Motor de IA',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioGroup<Provider>(
            groupValue: _provider,
            onChanged: (v) => v == null ? null : _onProviderChanged(v),
            child: Column(
              children: [
                for (final p in Provider.values)
                  RadioListTile<Provider>(
                    value: p,
                    title: Text(p.label),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          if (_provider == Provider.ollama)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Open source corre en esta máquina con Ollama (gratis). '
                'Si prefieres, usa Claude u OpenAI con tu propia cuenta.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: 'Modelo',
              hintText: _modelHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_provider.needsApiKey) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API key (tu propia cuenta)',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'El consumo se cobra a tu cuenta. La key se guarda solo en este dispositivo.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          const Divider(height: 36),
          const Text('URL del backend',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Normalmente http://localhost:8000 (el backend en esta misma máquina).',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'http://localhost:8000',
            ),
          ),
          const Divider(height: 36),
          const Text('Nivel (MCER)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final l in cefrLevels)
                ChoiceChip(
                  label: Text(l),
                  selected: _level == l,
                  onSelected: (_) => setState(() => _level = l),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
