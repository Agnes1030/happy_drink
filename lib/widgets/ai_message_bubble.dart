import 'package:flutter/material.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.meta,
    this.loading = false,
    this.isError = false,
    this.suggestions = const [],
    this.onSuggestionTap,
  });

  final String text;
  final bool isUser;
  final String? meta;
  final bool loading;
  final bool isError;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isUser
        ? scheme.primary
        : isError
            ? const Color(0xFFFDECEC)
            : scheme.surfaceContainerHighest;
    final textColor = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isUser ? Colors.white : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('思考中...', style: TextStyle(color: textColor)),
                  ],
                )
              else
                Text(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4)),
              if (meta != null && !loading) ...[
                const SizedBox(height: 8),
                Text(meta!, style: TextStyle(color: textColor.withValues(alpha: 0.75), fontSize: 12)),
              ],
            ],
          ),
        ),
        if (suggestions.isNotEmpty && onSuggestionTap != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (q) => ActionChip(
                    label: Text(q),
                    onPressed: () => onSuggestionTap!(q),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
