import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/notification_provider.dart';
import 'services/service_registry.dart';
import 'screens/splash_screen.dart';
import 'widgets/notification_overlay.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize service registry (Firebase or Mock Fallback auto-detection)
  await ServiceRegistry().initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Quiz Online',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Auto detect system theme mode
        debugShowCheckedModeBanner: false,
        // Wrap MaterialApp's navigator builder with our sliding NotificationOverlay
        builder: (context, child) {
          return NotificationOverlay(child: child ?? const SizedBox.shrink());
        },
        home: const SplashScreen(),
      ),
    );
  }
}
