
import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';
import '../constantes/app_strings.dart';

class RatingSection extends StatefulWidget {
  const RatingSection({Key? key}) : super(key: key);

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  int _hoveredStar = 0;
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.rateApp,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 24),
          Row(
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              final isFilled = starNumber <= (_hoveredStar > 0 ? _hoveredStar : _selectedRating);

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredStar = starNumber),
                onExit: (_) => setState(() => _hoveredStar = 0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRating = starNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: AppColors.primaryOrange,
                      size: 32,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          const Text(
            '4.8 / 5 - 126503 votes',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryGray,
            ),
          ),
        ],
      ),
    );
  }
}