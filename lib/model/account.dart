class Account {
  final String id;
  final String name;
  final String type; // Cash, Bank, Digital Wallet
  final double currentBalance;
  final bool isDefaultUpi;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currentBalance,
    this.isDefaultUpi = false,
  });

  factory Account.fromMap(Map<String, dynamic> data, String id) {
    return Account(
      id: id,
      name: data['name'] ?? '',
      type: data['account_type'] ?? 'Cash',
      currentBalance: (data['current_balance'] ?? 0).toDouble(),
      isDefaultUpi: data['is_default_upi'] ?? false,
    );
  }
}
