import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/env/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/home_provider.dart';
import 'features/dashboard/services/firestore_home_service.dart';
import 'features/investments/providers/investment_provider.dart';
import 'features/investments/services/firestore_investment_service.dart';
import 'features/dashboard/providers/ai_insight_provider.dart';
import 'core/services/cas_service.dart';
import 'features/profile/providers/ai_configuration_provider.dart';
import 'features/profile/screens/ai_settings_screen.dart';
import 'features/analyzer/providers/bank_analyzer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseServices();

}


Future<void> initFirebaseServices() async  {

  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey:Env.firebaseAPIKey ,
          appId:Env.firebaseAppId,
          messagingSenderId:Env.senderId,
          projectId:Env.projectId)
  );

 /*var supabaseClient=await Supabase.initialize(
    url:Env.supabaseProjectURL,
    anonKey:Env.supabaseAPIKey,
  );
*/
  runApp(const FinsightApp());


}
//final supabase = Supabase.instance.client;


class FinsightApp extends StatelessWidget {
  const FinsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(FirestoreHomeService())..fetchHomeData(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvestmentProvider(FirestoreInvestmentService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AIInsightProvider>(
          create: (_) => AIInsightProvider(),
          update: (_, auth, aiInsight) => aiInsight!..update(auth),
        ),
        ChangeNotifierProvider(
          create: (_) => AIConfigurationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BankAnalyzerProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Sampatti',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
