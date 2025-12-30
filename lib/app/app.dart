import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/logic/settings_notifier.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/biometric_lock_screen.dart';
import '../features/auth/logic/auth_notifier.dart';
import '../core/services/biometric_service.dart';

class PropLedgerApp extends ConsumerStatefulWidget {
  const PropLedgerApp({super.key});

  @override
  ConsumerState<PropLedgerApp> createState() => _PropLedgerAppState();
}

class _PropLedgerAppState extends ConsumerState<PropLedgerApp> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isLocked = false;
  bool _checkedBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    final shouldLock = await _biometricService.shouldLock();
    setState(() {
      _isLocked = shouldLock;
      _checkedBiometric = true;
    });
  }

  void _onAuthenticated() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'PropLedger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          // User not authenticated - show login
          if (user == null) {
            return const LoginScreen();
          }

          // User authenticated but app is locked - show biometric lock
          if (_checkedBiometric && _isLocked) {
            return BiometricLockScreen(onAuthenticated: _onAuthenticated);
          }

          // User authenticated and unlocked - show dashboard
          return const DashboardScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
