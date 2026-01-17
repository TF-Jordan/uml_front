import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constantes/modern_palette.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    Key? key,
    required this.items,
    required this.activeIndex,
    required this.onNavigate,
  }) : super(key: key);

  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(items.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Text(
            '→',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: ModernPalette.inkMuted,
            ),
          );
        }
        final itemIndex = index ~/ 2;
        final isActive = itemIndex == activeIndex;
        final isClickable = itemIndex < activeIndex;
        final label = items[itemIndex];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isClickable
              ? () => _confirmAndNavigate(context, itemIndex)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? ModernPalette.accent.withOpacity(0.12)
                  : ModernPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? ModernPalette.accent : ModernPalette.border,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? ModernPalette.accent : ModernPalette.inkSoft,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _confirmAndNavigate(BuildContext context, int index) async {
    final confirmed = await _confirmBack(context, items[index], items[activeIndex]);
    if (confirmed) {
      onNavigate(index);
    }
  }

  Future<bool> _confirmBack(
    BuildContext context,
    String target,
    String current,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Revenir à "$target" ?',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            color: ModernPalette.ink,
          ),
        ),
        content: Text(
          'Cela va abandonner les modifications depuis "$current". Continuer ?',
          style: GoogleFonts.spaceGrotesk(color: ModernPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernPalette.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revenir'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
