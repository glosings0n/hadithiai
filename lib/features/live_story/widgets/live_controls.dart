import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

class LiveControls extends StatelessWidget {
  const LiveControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveAudioProvider>();
    final canControl = provider.state == LiveState.connected;
    final mainAppButtonText = 'STOP';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              provider.isRecording ? AppIcons.mic : AppIcons.micOff,
              color: AppColors.primary,
              size: 30,
            ),
            onPressed: canControl
                ? () {
                    provider.toggleRecording();
                  }
                : null,
          ),

          IconButton(
            icon: Icon(
              provider.isConversationPaused ? AppIcons.play : AppIcons.pause,
              color: AppColors.primary,
              size: 30,
            ),
            onPressed: canControl
                ? () async {
                    await provider.toggleConversationPause();
                  }
                : null,
          ),

          IconButton(
            icon: Icon(
              provider.isMuted ? AppIcons.volumeOff : AppIcons.volumeOn,
              color: AppColors.primary,
              size: 30,
            ),
            onPressed: canControl
                ? () async {
                    await provider.toggleMute();
                  }
                : null,
          ),
          MainAppButton(
            width: 100,
            onTap: () async {
              await Provider.of<LiveAudioProvider>(
                context,
                listen: false,
              ).endSession();
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            color: AppColors.primary,
            text: mainAppButtonText,
          ),
        ],
      ),
    );
  }
}
