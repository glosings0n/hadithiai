import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

import 'widgets/settings_header.dart';
import 'widgets/settings_sections.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRefreshingCatalog = false;

  void _syncSessionPreferences(
    BuildContext context,
    AppPreferencesProvider preferences,
  ) {
    context.read<AppSessionService>().schedulePreferencesUpdate(
      language: PreferenceHelpers.ensureSupportedLanguage(
        preferences.appLanguage,
      ),
      ageGroup: 'child',
      region: PreferenceHelpers.regionFromCulture(preferences.riddleCulture),
    );
  }

  Future<void> _refreshStoryCatalog(BuildContext context) async {
    setState(() => _isRefreshingCatalog = true);
    try {
      await context.read<StoryProvider>().refreshCatalog(forceRemote: true);
      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          message: 'Story catalog refreshed successfully.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingCatalog = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferencesProvider>();

    return AppScaffold(
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: .start,
            spacing: 16,
            children: [
              SettingsHeader(onBackTap: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView(
                  primary: false,
                  children: [
                    ChildSafetySection(preferences: prefs),
                    NarrationLiveSection(
                      preferences: prefs,
                      languageOptions: PreferenceHelpers.supportedLanguages,
                      onVoiceInterruptionsChanged: (value) {
                        prefs.setVoiceInterruptions(value);
                        _syncSessionPreferences(context, prefs);
                      },
                      onLanguageChanged: (value) {
                        prefs.setAppLanguage(value);
                        _syncSessionPreferences(context, prefs);
                        context.read<LiveAudioProvider>().sendControl(
                          action: 'set_language',
                          value: value,
                        );
                      },
                    ),
                    RiddleSection(
                      preferences: prefs,
                      languageOptions: PreferenceHelpers.supportedLanguages,
                      riddleDifficulties: PreferenceHelpers.riddleDifficulties,
                      riddleCultures: PreferenceHelpers.riddleCultures,
                      onSessionSync: () {
                        _syncSessionPreferences(context, prefs);
                      },
                      onRiddleReload: () {
                        unawaited(
                          context.read<RiddleProvider>().loadFirstQuestion(),
                        );
                      },
                    ),
                    HabitsSection(
                      preferences: prefs,
                      isRefreshingCatalog: _isRefreshingCatalog,
                      onRefreshCatalog: () => _refreshStoryCatalog(context),
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
