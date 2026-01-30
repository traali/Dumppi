/// Dumppi - Snow Forecast & Ski Resort Weather App
///
/// Main entry point and composition root.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dumppi/src/features/core/ui/app_layout.dart';
import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';
import 'package:dumppi/src/features/map/logic/forecast_provider.dart';

void main() {
  runApp(const DumppiApp());
}

/// Root application widget.
class DumppiApp extends StatelessWidget {
  const DumppiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ForecastProvider()),
        ChangeNotifierProvider(create: (_) => ResortProvider()..loadResorts()),
      ],
      child: MaterialApp(
        title: 'Dumppi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D12),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0DB9F2),
            secondary: Color(0xFF7B61FF),
            surface: Color(0xFF16161E),
            surfaceContainerHigh: Color(0xFF1E1E28),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const AppLayout(),
      ),
    );
  }
}
