import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

import 'widgets/live_app_bar.dart';
import 'widgets/live_controls.dart';
import 'widgets/live_methods.dart';
import 'widgets/live_state_indicator.dart';
import 'widgets/pulse_animation.dart';
import 'widgets/vision_preview_widget.dart';

class LiveStoryScreen extends StatefulWidget {
  const LiveStoryScreen({super.key});

  @override
  State<LiveStoryScreen> createState() => _LiveStoryScreenState();
}

class _LiveStoryScreenState extends State<LiveStoryScreen> {
  LiveAudioProvider? _liveAudioProvider;
  LiveVisionProvider? _liveVisionProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveAudioProvider ??= context.read<LiveAudioProvider>();
      _liveVisionProvider ??= context.read<LiveVisionProvider>();
      _liveVisionProvider?.attachTransport(_liveAudioProvider!);
      _liveAudioProvider?.startLiveSession();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _liveAudioProvider ??= context.read<LiveAudioProvider>();
    _liveVisionProvider ??= context.read<LiveVisionProvider>();
    if (_liveAudioProvider != null) {
      _liveVisionProvider?.attachTransport(_liveAudioProvider!);
    }
  }

  @override
  void dispose() {
    final visionProvider = _liveVisionProvider;
    final audioProvider = _liveAudioProvider;

    visionProvider?.prepareForRouteExit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(visionProvider?.shutdownForRouteExit());
      unawaited(audioProvider?.endSession());
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LiveAudioProvider, LiveVisionProvider>(
      builder: (context, audioProvider, visionProvider, _) {
        visionProvider.attachTransport(audioProvider);
        return Scaffold(
          appBar: LiveAppBar(
            isVisionEnabled: visionProvider.isVisionEnabled,
            isVisionBusy: visionProvider.isBusy,
            onVisionToggle: () {
              unawaited(
                visionProvider.toggleVision(!visionProvider.isVisionEnabled),
              );
            },
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(AppImages.background, fit: .cover),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: .blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: AppColors.primary.withAlpha(77)),
                ),
              ),
              SafeArea(
                child: Column(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Expanded(
                      child: ListView(
                        primary: false,
                        children: [
                          LiveStateIndicator(provider: audioProvider),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Text(
                              audioProvider.statusMessage,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: LiveMethods.statusColor(audioProvider),
                                fontWeight: .bold,
                              ),
                            ),
                          ),
                          PulseAnimation(
                            audioLevel: audioProvider.amplitude,
                            isAiSpeaking: audioProvider.isAiSpeaking,
                            isUserSpeaking: audioProvider.isUserSpeaking,
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const .only(
                                top: 8,
                                right: 18,
                                bottom: 6,
                              ),
                              child: VisionPreviewWidget(
                                controller: visionProvider.cameraController,
                                isVisible: visionProvider.isVisionEnabled,
                                isAiSeeing: visionProvider.isAiSeeing,
                              ),
                            ),
                          ),
                          if (audioProvider.lastTextChunk.isNotEmpty)
                            Padding(
                              padding: const .symmetric(horizontal: 24),
                              child: Container(
                                width: double.infinity,
                                padding: const .all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withAlpha(100),
                                  borderRadius: .circular(12),
                                  border: .all(
                                    color: AppColors.primary.withAlpha(80),
                                  ),
                                ),
                                child: MarkdownBody(
                                  data: audioProvider.lastTextChunk,
                                  styleSheet: MarkdownStyleSheet(
                                    p: context.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    strong: context.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const LiveControls(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
