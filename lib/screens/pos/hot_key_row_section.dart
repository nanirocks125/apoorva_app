import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:apoorva_app/screens/pos/find_button.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/screens/pos/pos_ui_helpers.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HotkeyRowSection extends StatelessWidget {
  final OrganizationService? service;
  const HotkeyRowSection({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PosProvider>();
    final orgId = context.select<PosProvider, String>((p) => p.orgId);
    final orgService = service ?? OrganizationService();

    if (orgId.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return StreamBuilder<List<Category>>(
      stream: orgService.getLiveCategories(orgId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text('Unable to load quick items'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final categories = snapshot.data!;
        final hotkeys = categories.where((c) => c.isHotkey).toList();

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  "QUICK ITEMS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. COMPACT GRID (Left Side)
                    Expanded(
                      child: SizedBox(
                        // హైట్ అడ్జస్ట్మెంట్: (Card height * 2) + spacing
                        height: 150,
                        child: GridView.builder(
                          // Vertical scrolling enabled within the fixed height
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    4, // 4 columns for smaller cards
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.0, // Square cards
                              ),
                          itemCount: hotkeys.length,
                          itemBuilder: (context, index) {
                            return CategoryCard(
                              category: hotkeys[index],
                              onTap: () => PosUIHelpers.openCalculator(
                                context,
                                provider,
                                category: hotkeys[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. DOUBLE HEIGHT MORE BUTTON (Right Side)
                    SizedBox(
                      width: 70,
                      height: 120, // Matches the grid height
                      child: FindButton(
                        onTap: () => PosUIHelpers.showCategoryPicker(
                          context,
                          provider,
                          categories,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
