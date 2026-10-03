import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/payment_provider.dart';
import 'providers/person_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final databaseService = DatabaseService();

  await databaseService.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonProvider()),

        ChangeNotifierProvider(create: (_) => TransactionProvider()),

        ChangeNotifierProvider(create: (_) => PaymentProvider()),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SmartInterestXApp(),
    ),
  );
}
