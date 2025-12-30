import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/subscription_service.dart';

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionState {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiryDate;
  final int remainingDays;
  final bool isLoading;

  SubscriptionState({
    required this.tier,
    required this.isActive,
    this.expiryDate,
    required this.remainingDays,
    this.isLoading = false,
  });

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isActive,
    DateTime? expiryDate,
    int? remainingDays,
    bool? isLoading,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      remainingDays: remainingDays ?? this.remainingDays,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get canAccessOnlineBackups => isActive;

  String get statusText {
    if (!isActive) {
      return 'Free Plan';
    }
    if (remainingDays <= 0) {
      return 'Expired';
    }
    if (remainingDays <= 7) {
      return 'Expires in $remainingDays days';
    }
    return 'Premium Active';
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;

  SubscriptionNotifier({SubscriptionService? subscriptionService})
      : _subscriptionService = subscriptionService ?? SubscriptionService(),
        super(SubscriptionState(
          tier: SubscriptionTier.free,
          isActive: false,
          remainingDays: 0,
        )) {
    _init();
  }

  Future<void> _init() async {
    await checkSubscription();
  }

  Future<void> checkSubscription() async {
    state = state.copyWith(isLoading: true);

    final tier = await _subscriptionService.getSubscriptionTier();
    final isActive = await _subscriptionService.isSubscriptionActive();
    final expiryDate = await _subscriptionService.getSubscriptionExpiry();
    final remainingDays = await _subscriptionService.getRemainingDays();

    state = SubscriptionState(
      tier: tier,
      isActive: isActive,
      expiryDate: expiryDate,
      remainingDays: remainingDays,
      isLoading: false,
    );
  }

  /// Activate premium subscription (test mode)
  Future<void> activatePremium() async {
    await _subscriptionService.setSubscriptionTier(SubscriptionTier.premium);
    await checkSubscription();
  }

  /// Deactivate subscription
  Future<void> deactivate() async {
    await _subscriptionService.setSubscriptionTier(SubscriptionTier.free);
    await checkSubscription();
  }

  /// Clear subscription data
  Future<void> clearSubscription() async {
    await _subscriptionService.clearSubscription();
    await checkSubscription();
  }
}
