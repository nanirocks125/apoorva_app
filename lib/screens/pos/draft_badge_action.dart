import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraftsBadgeAction extends StatelessWidget {
  const DraftsBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);

    return StreamBuilder<List<DraftCart>>(
      stream: DraftCartService().getDraftsStream(provider.orgId),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.length : 0;
        return Badge(
          label: Text(count.toString()),
          child: IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () =>
                _showDraftsList(context, provider, snapshot.data ?? []),
          ),
        );
      },
    );
  }

  void _showDraftsList(
    BuildContext context,
    PosProvider provider,
    List<DraftCart> drafts,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'HOLD BILLS (DRAFTS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: drafts.isEmpty
                  ? const Center(child: Text("No bills on hold"))
                  : ListView.builder(
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return ListTile(
                          title: Text(
                            draft.customerName.isEmpty
                                ? "Walk-in"
                                : draft.customerName,
                          ),
                          subtitle: Text(
                            "${draft.items.length} items • ₹${draft.total}",
                          ),
                          trailing: const Icon(
                            Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onTap: () {
                            provider.resumeDraft(draft.id, draft);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
