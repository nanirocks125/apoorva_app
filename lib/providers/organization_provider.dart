import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';

class OrganizationProvider with ChangeNotifier {
  final OrganizationService _organizationService;

  Organization? _currentOrganization;
  bool _isLoading = false;

  OrganizationProvider({OrganizationService? organizationService})
    : _organizationService = organizationService ?? OrganizationService();

  // Getters
  Organization? get currentOrganization => _currentOrganization;
  bool get isLoading => _isLoading;

  /// Called automatically when the AuthProvider updates the user state.
  Future<void> updateForUser(AppUser? user) async {
    // If logged out, or user has no organizations attached, clear the state.
    // Note: Ensure your AppUser model has a List<String> field named `organizations`.
    if (user == null || user.assignedOrgs.isEmpty) {
      if (_currentOrganization != null) {
        _currentOrganization = null;
        notifyListeners();
      }
      return;
    }

    // Per your requirement, take the first organization ID from the user's array
    final String firstOrgId = user.assignedOrgs.first.orgId;

    // Prevent redundant network calls if the organization is already loaded
    if (_currentOrganization != null &&
        _currentOrganization!.id == firstOrgId) {
      return;
    }

    _isLoading = true;
    // We defer the notifyListeners to avoid build phase errors when proxy provider updates
    Future.microtask(() => notifyListeners());

    try {
      // Fetch from the service you provided
      _currentOrganization = await _organizationService.getOrganizationById(
        firstOrgId,
      );
    } catch (e) {
      print("Failed to fetch current organization: $e");
      _currentOrganization = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optional: A method to manually switch organizations later on
  Future<void> switchOrganization(String orgId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentOrganization = await _organizationService.getOrganizationById(
        orgId,
      );
    } catch (e) {
      print("Failed to switch organization: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
