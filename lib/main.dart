import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/features.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    .portraitUp,
    .portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppPreferencesProvider.instance),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => AppSessionProvider()..launch(),
        ),
        ChangeNotifierProvider(lazy: false, create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => CultureProvider()..launch(),
        ),
        ChangeNotifierProvider(lazy: false, create: (_) => StoryProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => RiddleProvider()),
        ChangeNotifierProvider(create: (_) => LiveAudioProvider()),
        ChangeNotifierProvider(create: (_) => LiveVisionProvider()),
      ],
      child: const HadithiApp(),
    ),
  );
}

class HadithiApp extends StatelessWidget {
  const HadithiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HadithiAI',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
      home: const WelcomeScreen(),
    );
  }
}
