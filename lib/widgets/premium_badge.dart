import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  final bool showText;
  final String text;

  const PremiumBadge({
    super.key,
    this.size = 16,
    this.showText = true,
    this.text = 'Premium',
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.5,
          vertical: size * 0.25,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars,
              size: size,
              color: Colors.white,
            ),
            SizedBox(width: size * 0.25),
            Text(
              text,
              style: TextStyle(
                fontSize: size * 0.75,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(size * 0.25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.stars,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

class PremiumChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    this.label = 'PRO',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
