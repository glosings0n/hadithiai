import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hadithi_ai/core/core.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(AppImages.background, fit: .cover),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
