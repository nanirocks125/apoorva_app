import 'package:apoorva_app/localDB/category_local_db.dart';
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
  // 🟢 1. టెస్టింగ్ కోసం లోకల్ DB ఫ్యూచర్‌ని బయటి నుండి పంపేలా ఆప్షనల్ పారామీటర్
  final Future<List<Category>> Function()? categoriesFetcher;

  const HotkeyRowSection({super.key, this.service, this.categoriesFetcher});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PosProvider>();
    final orgId = context.select<PosProvider, String>((p) => p.orgId);

    if (orgId.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // 🟢 2. ఒకవేళ టెస్ట్ అయితే ఇచ్చిన ఫంక్షన్ వాడతాం, లేదంటే రియల్ లోకల్ DB వాడతాం
    final futureToFetch = categoriesFetcher != null
        ? categoriesFetcher!()
        : CategoryLocalDatabase.instance.getCachedCategories();

    return FutureBuilder<List<Category>>(
      future: futureToFetch,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text('Unable to load quick items from local DB'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data!;
        final hotkeys = categories.where((c) => c.isHotkey).toList();
        final double screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth > 900 ? 10 : 4;

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
                        height: 140,
                        child: GridView.builder(
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.0,
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
                      height: 120,
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
