import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/otp_screen.dart';

import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050714),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const CineReviewApp(),
    ),
  );
}

class CineReviewApp extends StatelessWidget {
  const CineReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CineReview',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(themeProvider),
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/forgot_password': (_) => const ForgotPasswordScreen(),
            '/otp': (_) => const OtpScreen(),
            '/home': (_) => const HomeScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildTheme(ThemeProvider themeProvider) {
    final primaryColor = themeProvider.themeColor;
    final darkBg = themeProvider.backgroundColor;
    final isLightMode = darkBg.computeLuminance() > 0.5;
    final textColor = isLightMode ? Colors.black87 : Colors.white;

    final textTheme = kIsWeb
        ? ThemeData(brightness: isLightMode ? Brightness.light : Brightness.dark).textTheme
        : GoogleFonts.poppinsTextTheme(ThemeData(brightness: isLightMode ? Brightness.light : Brightness.dark).textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isLightMode ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isLightMode ? Brightness.light : Brightness.dark,
        primary: primaryColor,
        surface: darkBg,
        onPrimary: isLightMode ? Colors.white : Colors.black,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: primaryColor,
        labelColor: primaryColor,
        unselectedLabelColor: textColor.withOpacity(0.4),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLightMode ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
      ),
    );
  }
}
