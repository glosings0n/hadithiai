import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'widgets/story_collapsible_app_bar.dart';
import 'widgets/story_content_section.dart';
import 'widgets/story_signature_footer.dart';

class StoryScreen extends StatefulWidget {
  final StoryModel story;

  const StoryScreen({super.key, required this.story});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final StoryNarrationProvider _narrationProvider = StoryNarrationProvider();
  final ScrollController _scrollController = ScrollController();

  static const double _expandedAppBarHeight = 300.0;
  static const double _collapsedAppBarHeight = 70.0;
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final collapseOffset = _expandedAppBarHeight - _collapsedAppBarHeight;
    final nextCollapsed =
        _scrollController.hasClients &&
        _scrollController.offset >= collapseOffset;

    if (nextCollapsed != _isAppBarCollapsed && mounted) {
      setState(() {
        _isAppBarCollapsed = nextCollapsed;
      });
    }
  }

  String _decodeEscapedText(String raw) {
    if (raw.isEmpty) return raw;

    final decoded = raw
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\', '\\');

    // Clean markdown code fences often returned by LLMs for plain story text.
    return decoded
        .replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '');
  }

  Future<void> _stopNarration() async {
    await _narrationProvider.stopReading();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _narrationProvider.dispose();
    super.dispose();
  }

  String _buildStorySignature(StoryProvider storyProvider) {
    final dateLabel = DateFormat('MMM d').format(DateTime.now());
    final region = storyProvider.todayStoryMeta?.region.trim();

    if (region != null && region.isNotEmpty) {
      return 'By HadithiAI • $dateLabel\nInspired by $region Culture';
    }

    return 'By HadithiAI • $dateLabel';
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = context.watch<StoryProvider>();
    final liveStory = storyProvider.stories.isNotEmpty
        ? storyProvider.stories.first
        : widget.story;
    final signature = _buildStorySignature(storyProvider);
    final decodedTitle = _decodeEscapedText(liveStory.title);
    final decodedContent = _decodeEscapedText(liveStory.content);

    return ChangeNotifierProvider.value(
      value: _narrationProvider,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            unawaited(_stopNarration());
          }
        },
        child: AppScaffold(
          child: CustomScrollView(
            controller: _scrollController,
            primary: false,
            slivers: [
              StoryCollapsibleAppBar(
                expandedHeight: _expandedAppBarHeight,
                collapsedHeight: _collapsedAppBarHeight,
                isCollapsed: _isAppBarCollapsed,
                title: decodedTitle,
                imageUrl: liveStory.imageUrl,
                onBackTap: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 24,
                  children: [
                    StoryContentSection(
                      title: decodedTitle,
                      content: decodedContent,
                    ),
                    StorySignatureFooter(signature: signature),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
