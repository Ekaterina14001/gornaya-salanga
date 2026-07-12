import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownContent extends StatelessWidget {
  const MarkdownContent({
    super.key,
    required this.data,
    this.style,
  });

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final bodyStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: bodyStyle,
        listBullet: bodyStyle,
        h1: Theme.of(context).textTheme.titleLarge,
        h2: Theme.of(context).textTheme.titleMedium,
        h3: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
