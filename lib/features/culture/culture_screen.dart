import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

import 'widgets/culture_agent_card.dart';
import 'widgets/culture_regions_section.dart';
import 'widgets/culture_screen_header.dart';

class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cultureProvider = context.watch<CultureProvider>();

    return AppScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CultureScreenHeader(onBackTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    CultureAgentCard(
                      title: cultureProvider.title,
                      summary: cultureProvider.summary,
                      region: cultureProvider.region,
                    ),
                    const SizedBox(height: 16),
                    CultureRegionsSection(
                      stories: StoryMockData.getDailyStories(),
                    ),
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
