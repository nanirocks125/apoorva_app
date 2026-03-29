import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformStats {
  final int activeOrgs;
  final int globalUsers;
  final int newRequests;
  final String systemHealth;

  PlatformStats({
    required this.activeOrgs,
    required this.globalUsers,
    required this.newRequests,
    this.systemHealth = 'Optimal',
  });
}

class PlatformStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<PlatformStats> getLivePlatformStats() async {
    // 1. Count Organizations (Tenants)
    final orgsCount = await _db
        .collection('organizations')
        .where('status', isEqualTo: 'Active')
        .count()
        .get();

    // 2. Count Global Users
    final usersCount = await _db.collection('users').count().get();

    // 3. Count New Requests (e.g., Orgs with 'Pending' status)
    final requestsCount = await _db
        .collection('organizations')
        .where('status', isEqualTo: 'Pending')
        .count()
        .get();

    return PlatformStats(
      activeOrgs: orgsCount.count ?? 0,
      globalUsers: usersCount.count ?? 0,
      newRequests: requestsCount.count ?? 0,
    );
  }
}
