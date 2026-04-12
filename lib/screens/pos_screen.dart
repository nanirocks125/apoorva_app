import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/screens/pos/cart_list_section.dart';
import 'package:apoorva_app/screens/pos/cart_summary_footer.dart';
import 'package:apoorva_app/screens/pos/customer_data_header.dart';
import 'package:apoorva_app/screens/pos/draft_badge_action.dart';
import 'package:apoorva_app/screens/pos/hot_key_row_section.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key, this.initialSale});
  // final Organization organization;
  final Sale? initialSale; // Add this

  @override
  Widget build(BuildContext context) {
    // 1. Watch the OrganizationProvider for changes
    // watch() makes this build method rerun whenever the organization updates
    final orgProvider = context.watch<OrganizationProvider>();
    final organization = orgProvider.currentOrganization;

    // 2. Show Loader if organization is still null
    if (organization == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider(
      key: ValueKey(organization.id),
      create: (_) =>
          PosProvider(orgId: organization.id, initialSale: initialSale),
      child: Consumer<PosProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Apoorva POS'),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.pause_circle_filled_outlined,
                  color: Colors.orange,
                ),
                onPressed: provider.cart.items.isEmpty
                    ? null
                    : provider.holdCurrentBill,
              ),
              const DraftsBadgeAction(), // Separate widget for stream
              IconButton(
                icon: const Icon(Icons.history_outlined, color: Colors.teal),
                onPressed: () => _viewPurchaseHistory(context),
              ),
            ],
          ),
          drawer: GlobalDrawer(),
          body: const Column(
            children: [
              CustomerDataHeader(), // Separate Stateless Widget
              Expanded(
                child: CustomScrollView(
                  slivers: [HotkeyRowSection(), CartListSection()],
                ),
              ),
              CartSummaryFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPurchaseHistory(BuildContext context) {
    Navigator.pushNamed(context, '/sales-history');
  }
}
