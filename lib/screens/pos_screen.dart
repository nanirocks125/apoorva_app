import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/screens/pos/cart_list_section.dart';
import 'package:apoorva_app/screens/pos/cart_summary_footer.dart';
import 'package:apoorva_app/screens/pos/customer_data_header.dart';
import 'package:apoorva_app/screens/pos/draft_badge_action.dart';
import 'package:apoorva_app/screens/pos/hot_key_row_section.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apoorva POS', style: TextStyle(fontSize: 18)),
                // Displays the selected time from Provider
                Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(provider.billDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              // NEW: Date Time Picker Button
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blueAccent,
                ),
                onPressed: () => _pickDateTime(context, provider),
              ),
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
            ],
          ),
          drawer: GlobalDrawer(),
          body: Column(
            children: [
              CustomerDataHeader(), // Separate Stateless Widget
              Expanded(
                child: CustomScrollView(
                  slivers: [HotkeyRowSection(), CartListSection()],
                ),
              ),
              CartSummaryFooter(existingSale: initialSale),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context, PosProvider provider) async {
    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.billDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(provider.billDateTime),
    );

    if (pickedTime == null) return;

    // 3. Combine and Update
    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (context.mounted) {
      provider.updateBillDateTime(finalDateTime);
    }
  }
}
