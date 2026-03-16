import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class AppHelpers {
  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Returns true if the device can reach butikiangu.app (internet access).
  static Future<bool> checkConnectivity() async {
    final timeout = const Duration(seconds: 5);
    const host = 'google.com';
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Removes accents and special characters.
  // Useful for friendlier search and matching behavior.
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[œ]'), 'oe')
        .replaceAll(RegExp(r'[æ]'), 'ae')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  }
}
