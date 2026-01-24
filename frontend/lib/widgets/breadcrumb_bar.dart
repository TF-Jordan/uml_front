import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constantes/modern_palette.dart';
import '../constantes/theme_extension.dart';
import '../l10n/app_localizations.dart';

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
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(items.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Text(
            '→',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: CurrentTheme.inkMuted,
            ),
          );
        }
        final itemIndex = index ~/ 2;
        final isActive = itemIndex == activeIndex;
        final isClickable = itemIndex < activeIndex;
        final label = items[itemIndex];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isClickable
              ? () => _confirmAndNavigate(context, itemIndex)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? CurrentTheme.accent.withOpacity(0.12)
                  : CurrentTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? CurrentTheme.accent : CurrentTheme.border,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? CurrentTheme.accent : CurrentTheme.inkSoft,
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
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${l10n.returnTo} "$target" ?',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        content: Text(
          '${l10n.abandonChanges} "$current". ${l10n.continueQuestion}',
          style: GoogleFonts.spaceGrotesk(color: CurrentTheme.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CurrentTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.returnAction),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
