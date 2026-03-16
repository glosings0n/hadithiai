import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

import 'widgets/button_tab_bar.dart';
import 'widgets/library_story_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const List<String> _months = <String>[
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _selectedMonth = 'All';
  bool _requestedLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedLoad) {
        return;
      }
      _requestedLoad = true;
      context.read<StoryProvider>().loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allStories = context.watch<StoryProvider>().libraryStories;
    final stories = _filteredStories(allStories);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          Text(
            'All Stories',
            style: context.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Hanalei',
              color: AppColors.primary,
            ),
          ),
          ButtonTabBar(
            tabs: _months,
            selectedTab: _selectedMonth,
            onTabSelected: (month) => setState(() => _selectedMonth = month),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<StoryProvider>().refreshCatalog(),
              child: stories.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 240,
                          child: Center(
                            child: Text(
                              'No stories found for $_selectedMonth.',
                              style: context.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: stories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return LibraryStoryCard(story: stories[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<StoryModel> _filteredStories(List<StoryModel> source) {
    if (_selectedMonth == 'All') {
      return source;
    }
    return source.where((story) => story.month == _selectedMonth).toList();
  }
}
