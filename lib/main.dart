import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_theme.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/data/repositories/ai_repository_impl.dart';
import 'package:chatrizz/data/repositories/match_repository_impl.dart';
import 'package:chatrizz/data/repositories/memory_repository_impl.dart';
import 'package:chatrizz/data/repositories/message_repository_impl.dart';
import 'package:chatrizz/data/repositories/subscription_repository_impl.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';
import 'package:chatrizz/domain/repositories/memory_repository.dart';
import 'package:chatrizz/domain/repositories/message_repository.dart';
import 'package:chatrizz/domain/repositories/subscription_repository.dart';
import 'package:chatrizz/features/auth/screens/auth_screen.dart';
import 'package:chatrizz/features/matches/controllers/match_list_controller.dart';
import 'package:chatrizz/features/settings/controllers/settings_controller.dart';
import 'package:chatrizz/features/settings/screens/settings_screen.dart';
import 'package:chatrizz/features/splash/splash_screen.dart';
import 'package:chatrizz/services/ai_service.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/core/constants/api_config.dart';
import 'package:chatrizz/services/ocr_service.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/services/payment_service.dart';
import 'package:chatrizz/services/overlay_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localDataSource = LocalDataSource();
  await localDataSource.init();
  runApp(ChatRizzApp(localDataSource: localDataSource));
}

class ChatRizzApp extends StatefulWidget {
  final LocalDataSource localDataSource;

  const ChatRizzApp({super.key, required this.localDataSource});

  @override
  State<ChatRizzApp> createState() => _ChatRizzAppState();
}

class _ChatRizzAppState extends State<ChatRizzApp> with WidgetsBindingObserver {
  late final LocalDataSource _localDataSource;
  late final PaymentService _paymentService;
  late final AiService _aiService;
  late final AdService _adService;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localDataSource = widget.localDataSource;
    _paymentService = PaymentService();
    _paymentService.init();
    _aiService = AiService();
    _adService = AdService();
    _adService.init();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentService.dispose();
    _adService.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _apiService.refreshCredits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalDataSource>.value(value: _localDataSource),
        ChangeNotifierProvider<ApiService>.value(value: _apiService),
        Provider<OcrService>(create: (_) => OcrService()),
        Provider<AiService>.value(value: _aiService),
        ChangeNotifierProvider<AdService>.value(value: _adService),
        Provider<PaymentService>.value(value: _paymentService),
        Provider<MatchRepository>(
          create: (_) => MatchRepositoryImpl(_localDataSource),
          dispose: (_, repo) => (repo as MatchRepositoryImpl).dispose(),
        ),
        Provider<MessageRepository>(
          create: (_) => MessageRepositoryImpl(_localDataSource),
          dispose: (_, repo) => (repo as MessageRepositoryImpl).dispose(),
        ),
        Provider<MemoryRepository>(
          create: (_) => MemoryRepositoryImpl(_localDataSource),
          dispose: (_, repo) => (repo as MemoryRepositoryImpl).dispose(),
        ),
        Provider<SubscriptionRepository>(
          create: (_) => SubscriptionRepositoryImpl(_paymentService),
        ),
        Provider<AiRepository>(
          create: (_) => AiRepositoryImpl(_aiService),
        ),
        ChangeNotifierProvider<MatchListController>(
          create: (ctx) => MatchListController(
            ctx.read<MatchRepository>(),
            ctx.read<LocalDataSource>(),
            ctx.read<AdService>(),
            ctx.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (ctx) => SettingsController(
            ctx.read<SubscriptionRepository>(),
            ctx.read<LocalDataSource>(),
          ),
        ),
        ChangeNotifierProvider<OverlayService>(
          create: (ctx) {
            final overlay = OverlayService();
            final ds = ctx.read<LocalDataSource>();
            final user = ds.getUser();
            if (user != null && user.categories.isNotEmpty) {
              overlay.setCategories(user.categories);
            }
            overlay.setGroqApiKey(ApiConfig.groqApiKey);
            overlay.onCreditUsed = (int amount) async {
              await ctx.read<ApiService>().deductCredits(amount);
              await overlay.clearPendingCredits();
            };
            overlay.deductPendingCredits();
            return overlay;
          },
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settingsController, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsController.themeMode,
            home: const GatewayScreen(),
            routes: {
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        if (api.loading) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return api.isSignedIn ? const SplashScreen() : const AuthScreen();
      },
    );
  }
}
