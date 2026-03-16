import 'package:hadithi_ai/core/core.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/features/home/widgets/grid_menu.dart';
import 'package:hadithi_ai/features/home/widgets/hero_section.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storyProvider = context.watch<StoryProvider>();
    final stories = storyProvider.stories;

    return Padding(
      padding: const .all(20.0),
      child: Column(
        spacing: 16,
        children: [
          HeroSection(
            storyOfTheDay: stories.isNotEmpty ? stories.first : .empty,
          ),
          GridMenu(stories: stories),
        ],
      ),
    );
  }
}
