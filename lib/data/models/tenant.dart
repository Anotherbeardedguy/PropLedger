enum LeaseTerm { monthly, annually }

class Tenant {
  final String id;
  final String unitId;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? leaseStart;
  final DateTime? leaseEnd;
  final LeaseTerm leaseTerm;
  final double? depositAmount;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Tenant({
    required this.id,
    required this.unitId,
    required this.name,
    this.phone,
    this.email,
    this.leaseStart,
    this.leaseEnd,
    this.leaseTerm = LeaseTerm.monthly,
    this.depositAmount,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      leaseStart: json['lease_start'] != null ? DateTime.parse(json['lease_start'] as String) : null,
      leaseEnd: json['lease_end'] != null ? DateTime.parse(json['lease_end'] as String) : null,
      leaseTerm: _parseLeaseterm(json['lease_term'] as String? ?? 'monthly'),
      depositAmount: json['deposit_amount'] != null
          ? (json['deposit_amount'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'name': name,
      'phone': phone,
      'email': email,
      'lease_start': leaseStart?.toIso8601String(),
      'lease_end': leaseEnd?.toIso8601String(),
      'lease_term': _leaseTermToString(leaseTerm),
      'deposit_amount': depositAmount,
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static LeaseTerm _parseLeaseterm(String term) {
    return term == 'annually' ? LeaseTerm.annually : LeaseTerm.monthly;
  }

  static String _leaseTermToString(LeaseTerm term) {
    return term == LeaseTerm.annually ? 'annually' : 'monthly';
  }

  bool get isLeaseExpiring {
    if (leaseEnd == null) return false;
    final daysUntilExpiry = leaseEnd!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 60 && daysUntilExpiry >= 0;
  }

  Tenant copyWith({
    String? id,
    String? unitId,
    String? name,
    String? phone,
    String? email,
    DateTime? leaseStart,
    DateTime? leaseEnd,
    LeaseTerm? leaseTerm,
    double? depositAmount,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Tenant(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      leaseStart: leaseStart ?? this.leaseStart,
      leaseEnd: leaseEnd ?? this.leaseEnd,
      leaseTerm: leaseTerm ?? this.leaseTerm,
      depositAmount: depositAmount ?? this.depositAmount,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
