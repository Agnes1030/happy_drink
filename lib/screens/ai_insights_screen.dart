import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/ai_message_bubble.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({
    super.key,
    required this.apiClient,
    required this.userId,
  });

  final ApiClient apiClient;
  final String userId;

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  static const _defaultPrompts = [
    '这个月我喝咖啡花了多少钱？',
    '这周我喝了几杯？',
    '我最常买的品牌是什么？',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  Future<void> _ask([String? preset]) async {
    final q = (preset ?? _controller.text).trim();
    if (q.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add(_ChatMessage.user(q));
      _messages.add(_ChatMessage.assistant('思考中...', loading: true));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final data = await widget.apiClient.askAi(userId: widget.userId, question: q);
      final qa = data['qa_result'] as Map<String, dynamic>;
      final answer = qa['answer']?.toString() ?? '没有得到回答';
      final meta = '${data['parsed_time_range']} · 置信度 ${(data['parser_confidence'] ?? 0)}';
      final fallback = data['fallback_needed'] == true;
      final suggestions = (data['suggestions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage.assistant(
            answer,
            meta: meta,
            suggestions: suggestions,
            fallback: fallback,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(_ChatMessage.assistant('请求失败：$e', isError: true));
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('AI 洞察', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('像聊天一样问我：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _defaultPrompts
                                  .map((q) => ActionChip(label: Text(q), onPressed: () => _ask(q)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text('AI 洞察', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                      );
                    }
                    final message = _messages[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: AiMessageBubble(
                          text: message.text,
                          isUser: message.isUser,
                          meta: message.meta,
                          loading: message.loading,
                          isError: message.isError,
                          suggestions: message.suggestions,
                          onSuggestionTap: _ask,
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(hintText: '输入你的问题...'),
                    onSubmitted: (_) => _ask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _ask,
                  child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.meta,
    this.loading = false,
    this.isError = false,
    this.suggestions = const [],
    this.fallback = false,
  });

  final String text;
  final bool isUser;
  final String? meta;
  final bool loading;
  final bool isError;
  final List<String> suggestions;
  final bool fallback;

  factory _ChatMessage.user(String text) => _ChatMessage(text: text, isUser: true);

  factory _ChatMessage.assistant(
    String text, {
    String? meta,
    bool loading = false,
    bool isError = false,
    List<String> suggestions = const [],
    bool fallback = false,
  }) =>
      _ChatMessage(
        text: fallback ? '$text\n\n建议确认问题意图后再查询。' : text,
        isUser: false,
        meta: meta,
        loading: loading,
        isError: isError,
        suggestions: suggestions,
        fallback: fallback,
      );
}
