// ============================================================
// widgets/star_rating.dart — Interactive star rating widget
// ============================================================
import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 36,
  });
  

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () {
            setState(() => _currentRating = starValue);
            widget.onRatingChanged(starValue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              _currentRating >= starValue
                  ? Icons.star_rounded
                  : _currentRating >= starValue - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              color: _currentRating >= starValue
                  ? const Color(0xFFFFD700)
                  : Colors.white30,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}

// Read-only display star rating
class StarDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const StarDisplay({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return Icon(
          rating >= starValue
              ? Icons.star_rounded
              : rating >= starValue - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: const Color(0xFFFFD700),
          size: size,
        );
      }),
    );
  }
}
