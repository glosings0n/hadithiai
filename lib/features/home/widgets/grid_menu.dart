import 'package:hadithi_ai/core/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/features/features.dart';

class GridMenu extends StatelessWidget {
  final List<StoryModel> stories;

  const GridMenu({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    final labels = ["DayStory", "Riddle Game", "Culture", "Settings"];

    final icons = [
      AppIcons.book,
      AppIcons.puzzle,
      Icons.public_rounded,
      AppIcons.settings,
    ];

    final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple];

    final onTaps = [
      () {
        if (stories.isEmpty || stories.first.isEmpty) {
          UIHelpers.showSnackBar(
            context,
            message: "Still generating the day's story.",
          );
          return;
        }

        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => StoryScreen(story: stories.first)),
        );
      },
      () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const RiddleScreen()),
        );
      },
      () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const CultureScreen()),
        );
      },
      () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    ];

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(labels.length, (index) {
          return MainGridCard(
            label: labels[index],
            icon: icons[index],
            backgroundColor: colors[index],
            onTap: onTaps[index],
          );
        }),
      ),
    );
  }
}
