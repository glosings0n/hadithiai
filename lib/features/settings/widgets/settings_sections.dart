import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

import 'settings_dropdown_tile.dart';
import 'settings_section_card.dart';
import 'settings_toggle_tile.dart';

class ChildSafetySection extends StatelessWidget {
  final AppPreferencesProvider preferences;

  const ChildSafetySection({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Child Safety',
      subtitle:
          'Controls for age-appropriate storytelling and game interactions.',
      children: [
        SettingsToggleTile(
          icon: AppIcons.shieldCheck,
          title: 'Safe mode (strict)',
          subtitle: 'Filter content and keep child-friendly responses.',
          value: preferences.safeMode,
          onChanged: preferences.setSafeMode,
        ),
        SettingsToggleTile(
          icon: AppIcons.star,
          title: 'Show cultural notes',
          subtitle: 'Display grounded cultural references with stories.',
          value: preferences.showCulturalNotes,
          onChanged: preferences.setShowCulturalNotes,
        ),
      ],
    );
  }
}

class NarrationLiveSection extends StatelessWidget {
  final AppPreferencesProvider preferences;
  final List<String> languageOptions;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onVoiceInterruptionsChanged;

  const NarrationLiveSection({
    super.key,
    required this.preferences,
    required this.languageOptions,
    required this.onLanguageChanged,
    required this.onVoiceInterruptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Narration and Live AI',
      subtitle: 'Audio behavior for read-aloud and real-time conversation.',
      children: [
        SettingsToggleTile(
          icon: AppIcons.volumeOn,
          title: 'Auto read aloud',
          subtitle: 'Automatically start narration when opening a story.',
          value: preferences.autoReadAloud,
          onChanged: preferences.setAutoReadAloud,
        ),
        SettingsToggleTile(
          icon: AppIcons.mic,
          title: 'Allow interruptions in live mode',
          subtitle: 'Let children interrupt AI naturally while speaking.',
          value: preferences.voiceInterruptions,
          onChanged: onVoiceInterruptionsChanged,
        ),
        SettingsDropdownTile(
          icon: AppIcons.ai,
          title: 'App language',
          subtitle: 'Used for story session and generation requests.',
          value: preferences.appLanguage,
          options: languageOptions,
          onChanged: onLanguageChanged,
        ),
        SettingsDropdownTile(
          icon: AppIcons.book,
          title: 'Story catalog language',
          subtitle: 'Language sent to /api/v1/stories/generate.',
          value: preferences.storyCatalogLanguage,
          options: languageOptions,
          onChanged: preferences.setStoryCatalogLanguage,
        ),
      ],
    );
  }
}

class RiddleSection extends StatelessWidget {
  final AppPreferencesProvider preferences;
  final List<String> languageOptions;
  final List<String> riddleDifficulties;
  final List<String> riddleCultures;
  final VoidCallback onRiddleReload;
  final VoidCallback onSessionSync;

  const RiddleSection({
    super.key,
    required this.preferences,
    required this.languageOptions,
    required this.riddleDifficulties,
    required this.riddleCultures,
    required this.onRiddleReload,
    required this.onSessionSync,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Riddle Game',
      subtitle:
          'Tune generation parameters for faster and better puzzle rounds.',
      children: [
        SettingsDropdownTile(
          icon: AppIcons.target,
          title: 'Difficulty',
          subtitle: 'Sent to /api/v1/riddles/generate.',
          value: preferences.riddleDifficulty,
          options: riddleDifficulties,
          onChanged: (value) {
            preferences.setRiddleDifficulty(value);
            onSessionSync();
            onRiddleReload();
          },
        ),
        SettingsDropdownTile(
          icon: AppIcons.star,
          title: 'Culture focus',
          subtitle: 'Regional flavor used when generating riddles.',
          value: preferences.riddleCulture,
          options: riddleCultures,
          onChanged: (value) {
            preferences.setRiddleCulture(value);
            onSessionSync();
            onRiddleReload();
          },
        ),
        SettingsDropdownTile(
          icon: AppIcons.ai,
          title: 'Riddle language',
          subtitle: 'Language sent to riddle generation endpoint.',
          value: preferences.riddleLanguage,
          options: languageOptions,
          onChanged: (value) {
            preferences.setRiddleLanguage(value);
            onRiddleReload();
          },
        ),
      ],
    );
  }
}

class HabitsSection extends StatelessWidget {
  final AppPreferencesProvider preferences;
  final bool isRefreshingCatalog;
  final Future<void> Function() onRefreshCatalog;

  const HabitsSection({
    super.key,
    required this.preferences,
    required this.isRefreshingCatalog,
    required this.onRefreshCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Habits and Notifications',
      subtitle: 'Daily consistency and reading streak experience.',
      children: [
        SettingsToggleTile(
          icon: AppIcons.target,
          title: 'Daily reminder',
          subtitle: 'Receive one gentle reminder to keep the streak.',
          value: preferences.dailyReminder,
          onChanged: preferences.setDailyReminder,
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              iconColor: AppColors.primary,
              backgroundColor: AppColors.background.withAlpha(170),
              shadowColor: AppColors.background.withAlpha(170),
              foregroundColor: AppColors.primary,
              textStyle: TextStyle(
                color: AppColors.primary,
                fontFamily: "Fredoka",
              ),
            ),
            onPressed: () {
              if (!isRefreshingCatalog) onRefreshCatalog();
            },
            icon: isRefreshingCatalog
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 1,
                    ),
                  )
                : const Icon(AppIcons.refresh),
            label: Text(
              isRefreshingCatalog
                  ? 'Refreshing catalog...'
                  : 'Refresh story catalog now',
            ),
          ),
        ),
      ],
    );
  }
}
