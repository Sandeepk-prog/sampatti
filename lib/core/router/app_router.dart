import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/analyzer/screens/ai_chat_screen_v2.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/main_layout.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/dashboard/screens/home_page_v2.dart';
import '../../features/investments/screens/investments_screen.dart';
import '../../features/investments/screens/category_distribution_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/providers/ai_configuration_provider.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/faq_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/support_query_details_screen.dart';
import '../../features/profile/screens/questionnaire_screen.dart';
import '../../features/profile/screens/raise_ticket_screen.dart';
import '../../features/profile/screens/meeting_list_screen.dart';
import '../../features/profile/screens/rating_screen.dart';
import '../../features/profile/screens/ai_settings_screen.dart';
import '../../features/profile/screens/manage_keys_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/analyzer/screens/upload_screen.dart';
import '../../features/analyzer/screens/processing_screen.dart';
import '../../features/analyzer/screens/analyzer_dashboard.dart';
import '../../features/analyzer/screens/transaction_list_screen.dart';
import '../../features/dashboard/screens/demat_section.dart';

import '../../features/analyzer/screens/ai_chat_screen.dart';
import '../../features/analyzer/providers/chat_provider.dart';
import '../../features/analyzer/models/bank_statement_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) {
                  final aiConfig = context.read<AIConfigurationProvider>();
                  final authProvider = context.read<AuthProvider>();
                  final extra = state.extra as Map<String, dynamic>?;
                  
                  final transactions = extra?['transactions'] as List<BankTransaction>?;
                  final apiKey = extra?['apiKey'] as String? ?? aiConfig.currentKey;
                  final casUrl = extra?['casUrl'] as String?;
                  
                  return ChangeNotifierProxyProvider<AIConfigurationProvider, ChatProvider>(
                    create: (_) => ChatProvider(
                      transactions: transactions,
                      apiKey: apiKey,
                      userId: authProvider.user?.id,
                      casUrl: casUrl,
                    ),
                    update: (context, aiConfig, chatProvider) {
                      chatProvider?.updateConfig(apiKey: aiConfig.currentKey);
                      return chatProvider!;
                    },
                    child: const AiChatScreenV2(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePageV2(),
      ),
      GoRoute(
        path: '/demat_demat',
        builder: (context, state) => const DematSection(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const AnalyzerDashboard(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/query-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SupportQueryDetailsScreen(
            ticketId: extra?['ticketId'] ?? 'TKT-770',
            isClosed: extra?['isClosed'] ?? true,
          );
        },
      ),
      GoRoute(
        path: '/questionnaire',
        builder: (context, state) => const QuestionnaireScreen(),
      ),
      GoRoute(
        path: '/raise-ticket',
        builder: (context, state) => const RaiseTicketScreen(),
      ),
      GoRoute(
        path: '/meeting-notes',
        builder: (context, state) => const MeetingListScreen(),
      ),
      GoRoute(
        path: '/rating',
        builder: (context, state) => const RatingScreen(),
      ),
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const AISettingsScreen(),
      ),
      GoRoute(
        path: '/manage-keys',
        builder: (context, state) => const ManageKeysScreen(),
      ),
      GoRoute(
        path: '/category-distribution',
        builder: (context, state) => const CategoryDistributionScreen(),
      ),
      GoRoute(
        path: '/analyzer/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/analyzer/processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/analyzer/dashboard',
        builder: (context, state) => const AnalyzerDashboard(),
      ),
      GoRoute(
        path: '/analyzer/transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/analyzer/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final transactions = extra['transactions'] as List<BankTransaction>?;
          final apiKey = extra['apiKey'] as String;
          final casUrl = extra['casUrl'] as String?;
          
          // Get userId from AuthProvider
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.user?.id;
          
          return ChangeNotifierProxyProvider<AIConfigurationProvider, ChatProvider>(
            create: (_) => ChatProvider(
              transactions: transactions,
              apiKey: apiKey,
              userId: userId,
              casUrl: casUrl,
            ),
            update: (context, aiConfig, chatProvider) {
              chatProvider?.updateConfig(apiKey: aiConfig.currentKey);
              return chatProvider!;
            },
            child: const AiChatScreen(),
          );
        },
      ),
    ],
  );
}
