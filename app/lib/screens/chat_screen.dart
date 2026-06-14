import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../storage.dart';
import '../tts.dart';
import '../widgets/feedback_card.dart';

class ChatScreen extends StatefulWidget {
  final String level;
  final Scenario scenario;
  const ChatScreen({super.key, required this.level, required this.scenario});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = TutorApi();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  List<String> _suggestions = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchOpening(); // the tutor speaks first
  }

  @override
  void dispose() {
    Tts.stop();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<ChatMessage> get _history => _messages
      .map((m) => ChatMessage(sender: m.sender, text: m.text))
      .toList();

  Future<void> _fetchOpening() async {
    setState(() => _sending = true);
    try {
      final llm = await Storage.getLlmConfig();
      final turn = await _api.chat(
        history: const [],
        level: widget.level,
        scenario: widget.scenario.expectedTopic,
        llm: llm,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(sender: Sender.tutor, text: turn.reply));
        _suggestions = turn.suggestions;
        _sending = false;
      });
      Tts.speak(turn.reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError(e);
    }
    _scrollToEnd();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(sender: Sender.user, text: text));
      _suggestions = [];
      _sending = true;
    });
    _scrollToEnd();

    try {
      final llm = await Storage.getLlmConfig();
      final turn = await _api.chat(
        history: _history,
        level: widget.level,
        scenario: widget.scenario.expectedTopic,
        llm: llm,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.length - 1; // attach feedback to the user message
        _messages[idx] = ChatMessage(
          sender: Sender.user,
          text: _messages[idx].text,
          corrections: turn.corrections,
          grammarTip: turn.grammarTip,
        );
        _messages.add(ChatMessage(sender: Sender.tutor, text: turn.reply));
        _suggestions = turn.suggestions;
        _sending = false;
      });
      Tts.speak(turn.reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError(e);
    }
    _scrollToEnd();
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scenario.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageItem(message: _messages[i]),
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          if (_suggestions.isNotEmpty && !_sending)
            _Suggestions(suggestions: _suggestions, onPick: (s) {
              _controller.text = s;
              _controller.selection =
                  TextSelection.collapsed(offset: s.length);
            }),
          _Composer(controller: _controller, enabled: !_sending, onSend: _send),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onPick;
  const _Suggestions({required this.suggestions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬 Ideas para responder (toca una):',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => onPick(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final ChatMessage message;
  const _MessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final scheme = Theme.of(context).colorScheme;
    final hasFeedback =
        message.corrections.isNotEmpty || (message.grammarTip?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser && Tts.supported)
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: 'Escuchar',
                onPressed: () => Tts.speak(message.text),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.74),
                decoration: BoxDecoration(
                  color:
                      isUser ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasFeedback)
          FeedbackCard(
            corrections: message.corrections,
            grammarTip: message.grammarTip,
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final void Function([String?]) onSend;
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type in English…',
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: enabled ? () => onSend() : null,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
