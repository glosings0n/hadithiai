import 'package:flutter/widgets.dart';
import 'package:hadithi_ai/core/core.dart';

class LiveMethods {
  static Color statusColor(LiveAudioProvider provider) {
    final message = provider.statusMessage.toLowerCase();

    if (message.contains('interrupted')) {
      return AppColors.error;
    }

    if (isConnectingStatus(provider.statusMessage)) {
      return AppColors.warning;
    }

    if (provider.state == LiveState.connected) {
      return AppColors.success;
    }

    if (provider.state == LiveState.error) {
      return AppColors.error;
    }

    return AppColors.background;
  }

  static bool isConnectingStatus(String statusMessage) {
    final message = statusMessage.toLowerCase();
    return message.contains('connecting') || message.contains('reconnecting');
  }
}
