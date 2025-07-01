import 'package:flutter/material.dart';

class InfoCard {
  /// Shows an information card as an animated overlay
  static void showInfoCard(
    BuildContext context,
    String message,
    Color color, {
    IconData icon = Icons.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Create an overlay entry
    final overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 50.0,
          right: 20.0,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 350,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (overlayEntry != null) {
                          overlayEntry?.remove();
                          overlayEntry = null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Add overlay entry to overlay
    overlayState.insert(overlayEntry!);

    // Remove after duration
    Future.delayed(duration).then((_) {
      if (overlayEntry != null && overlayEntry!.mounted) {
        overlayEntry?.remove();
      }
    });
  }
}
