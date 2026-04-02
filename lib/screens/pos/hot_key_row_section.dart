import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:apoorva_app/screens/pos/more_button.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/screens/pos/pos_ui_helpers.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HotkeyRowSection extends StatelessWidget {
  final OrganizationService? service; // Add this
  const HotkeyRowSection({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PosProvider>();
    final orgId = context.select<PosProvider, String>((p) => p.orgId);

    final orgService = service ?? OrganizationService();

    if (orgId.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: StreamBuilder<List<Category>>(
        stream: orgService.getLiveCategories(orgId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('HotkeyRowSection stream error: ${snapshot.error}');
            return const SizedBox.shrink();
          }
          if (!snapshot.hasData) return const SizedBox.shrink();
          final categories = snapshot.data!;
          final hotkeys = categories.where((c) => c.isHotkey).toList();

          return Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hotkeys.length + 1,
              itemBuilder: (context, index) {
                if (index < hotkeys.length) {
                  final cat = hotkeys[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 120,
                      child: CategoryCard(
                        // Reuse your card widget
                        category: cat,
                        onTap: () => PosUIHelpers.openCalculator(
                          context,
                          provider,
                          category: cat,
                        ),
                      ),
                    ),
                  );
                }
                return MoreButton(
                  onTap: () => PosUIHelpers.showCategoryPicker(
                    context,
                    provider,
                    snapshot.data!,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // logic for _openCalculator and _showAllCategories goes here or in a separate helper
}
