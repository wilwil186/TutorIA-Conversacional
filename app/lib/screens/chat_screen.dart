import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../storage.dart';
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
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// History sent to the backend: only role + text, no UI-only feedback.
  List<ChatMessage> get _history => _messages
      .map((m) => ChatMessage(sender: m.sender, text: m.text))
      .toList();

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(sender: Sender.user, text: text));
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
        // Attach feedback to the user message we just added.
        final idx = _messages.length - 1;
        _messages[idx] = ChatMessage(
          sender: Sender.user,
          text: _messages[idx].text,
          corrections: turn.corrections,
          grammarTip: turn.grammarTip,
        );
        _messages.add(ChatMessage(sender: Sender.tutor, text: turn.reply));
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
    _scrollToEnd();
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
            child: _messages.isEmpty
                ? _EmptyHint(scenario: widget.scenario)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _MessageItem(message: _messages[i]),
                  ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          _Composer(controller: _controller, enabled: !_sending, onSend: _send),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final Scenario scenario;
  const _EmptyHint({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48),
            const SizedBox(height: 12),
            Text(scenario.description, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Escribe en inglés para empezar. Te corregiré con cariño. 🙂',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
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
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
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
  final VoidCallback onSend;
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
              onPressed: enabled ? onSend : null,
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
