import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Subscription tiers for PropLedger
enum SubscriptionTier {
  free,
  premium,
}

/// Subscription Service
/// Manages user subscription status and feature access
class SubscriptionService {
  final FlutterSecureStorage _secureStorage;

  static const String _subscriptionTierKey = 'subscription_tier';
  static const String _subscriptionExpiryKey = 'subscription_expiry';

  SubscriptionService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get current subscription tier
  Future<SubscriptionTier> getSubscriptionTier() async {
    final tierString = await _secureStorage.read(key: _subscriptionTierKey);
    if (tierString == null || tierString == 'free') {
      return SubscriptionTier.free;
    }
    return SubscriptionTier.premium;
  }

  /// Set subscription tier (for testing)
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    await _secureStorage.write(
      key: _subscriptionTierKey,
      value: tier == SubscriptionTier.premium ? 'premium' : 'free',
    );

    // Set expiry to 30 days from now for premium
    if (tier == SubscriptionTier.premium) {
      final expiry = DateTime.now().add(const Duration(days: 30));
      await _secureStorage.write(
        key: _subscriptionExpiryKey,
        value: expiry.toIso8601String(),
      );
    } else {
      await _secureStorage.delete(key: _subscriptionExpiryKey);
    }
  }

  /// Check if subscription is active
  Future<bool> isSubscriptionActive() async {
    final tier = await getSubscriptionTier();
    if (tier == SubscriptionTier.free) {
      return false;
    }

    // Check expiry
    final expiryString = await _secureStorage.read(key: _subscriptionExpiryKey);
    if (expiryString == null) {
      return false;
    }

    final expiry = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiry);
  }

  /// Get subscription expiry date
  Future<DateTime?> getSubscriptionExpiry() async {
    final expiryString = await _secureStorage.read(key: _subscriptionExpiryKey);
    if (expiryString == null) {
      return null;
    }
    return DateTime.parse(expiryString);
  }

  /// Check if user can access online backups
  Future<bool> canAccessOnlineBackups() async {
    return await isSubscriptionActive();
  }

  /// Get remaining days of subscription
  Future<int> getRemainingDays() async {
    final expiry = await getSubscriptionExpiry();
    if (expiry == null) {
      return 0;
    }
    final remaining = expiry.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Clear subscription (for testing/logout)
  Future<void> clearSubscription() async {
    await _secureStorage.delete(key: _subscriptionTierKey);
    await _secureStorage.delete(key: _subscriptionExpiryKey);
  }
}
