import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/flash_deals_provider.dart';
import 'widgets/deal_card.dart';

class FlashDealsScreen extends HookConsumerWidget {
  const FlashDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashDealsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        title: Text(
          '⚡ Flash Deals',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C3CE1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(flashDealsProvider);
        },
        child: state.when(
          data: (deals) {
            if (deals.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No flash deals right now.\nCheck back soon!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final deal = deals[index];
                return DealCard(deal: deal)
                    .animate(delay: (80 * index).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
              },
            ).animate().fadeIn(duration: 400.ms);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C3CE1)),
          ),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
