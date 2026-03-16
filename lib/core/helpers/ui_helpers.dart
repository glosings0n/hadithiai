import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/styles/app_colors.dart';
import 'package:intl/intl.dart';

class UIHelpers {
  static const noInternetMessage =
      "Internet connection problem. Please check your network and try again.";

  static const internetNeededMessage =
      "You must be connected to the internet to perform this action.";

  static const genericErrorMessage = "An error has occurred. Please try again.";

  /// Shows a customized SnackBar with the given message.
  static void showSnackBar(
    BuildContext context, {
    String message = genericErrorMessage,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Fredoka', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showOverlaySnackBar(
    BuildContext context, {
    String message = genericErrorMessage,
    Duration duration = const Duration(seconds: 2),
    double bottomMargin = 75,
  }) {
    final snackBackground = AppColors.primary;
    final snackTextColor = AppColors.background;

    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomMargin,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: snackBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: snackTextColor),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static String formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final isToday =
        now.year == time.year && now.month == time.month && now.day == time.day;
    if (isToday) {
      return DateFormat('HH:mm').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}
