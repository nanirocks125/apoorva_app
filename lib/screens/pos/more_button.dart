import 'package:flutter/material.dart';

class FindButton extends StatelessWidget {
  final VoidCallback onTap;
  const FindButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 1. MODERN GRADIENT (To avoid a flat look)
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5733), Color(0xFFFF7E62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        // 2. PREMIUM ORANGE GLOW
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5733).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3. WHITE ICON FOR HIGH CONTRAST
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Colors.white, // Contrast against orange
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              // 4. BOLD WHITE TEXT
              const Text(
                'FIND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
