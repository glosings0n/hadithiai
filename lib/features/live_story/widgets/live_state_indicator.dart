import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

import 'live_methods.dart';

class LiveStateIndicator extends StatelessWidget {
  const LiveStateIndicator({super.key, required this.provider});

  final LiveAudioProvider provider;

  @override
  Widget build(BuildContext context) {
    final bool isConnected = provider.state == .connected;
    final bool isSpeaking = provider.isAiSpeaking;
    final bool isInterrupted = provider.statusMessage.toLowerCase().contains(
      'interrupted',
    );
    final bool isConnecting = LiveMethods.isConnectingStatus(
      provider.statusMessage,
    );

    final Color chipColor = isSpeaking
        ? AppColors.primary
        : isInterrupted
        ? AppColors.error
        : isConnecting
        ? AppColors.warning
        : isConnected
        ? AppColors.success
        : provider.state == LiveState.error
        ? AppColors.error
        : AppColors.textSecondary;

    final String label = isSpeaking
        ? 'AI Speaking'
        : isInterrupted
        ? 'Interrupted'
        : isConnecting
        ? 'Connecting'
        : isConnected
        ? 'Listening'
        : 'Offline';
    final String? agentState = provider.agentState?.trim();
    final String? agentName = provider.activeAgent?.trim();
    final String agentSuffix = (agentName != null && agentName.isNotEmpty)
        ? '$agentName:$agentState'
        : 'agent:$agentState';
    final String compactAgentSuffix = agentSuffix.length > 24
        ? '${agentSuffix.substring(0, 24)}...'
        : agentSuffix;
    final String effectiveLabel =
        (isConnected && agentState != null && agentState.isNotEmpty)
        ? '$label • $compactAgentSuffix'
        : label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipColor.withAlpha(46),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipColor.withAlpha(186), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: chipColor.withAlpha(10),
                  blurRadius: isSpeaking ? 14 : 8,
                  spreadRadius: isSpeaking ? 1 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: .center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isSpeaking ? 12 : 9,
                  height: isSpeaking ? 12 : 9,
                  decoration: BoxDecoration(color: chipColor, shape: .circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    effectiveLabel,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: chipColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
