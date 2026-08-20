import 'package:flutter/material.dart';

class NullPhoneFrame extends StatelessWidget {
  final Widget child;
  final double aspectRatio;
  final bool showDeviceBezel;

  const NullPhoneFrame({
    super.key,
    required this.child,
    this.aspectRatio = 9 / 16,
    this.showDeviceBezel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDeviceBezel) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: child,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32.0),
          border: Border.all(
            color: const Color(0xFF2C2C2E),
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
              blurRadius: 30.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF64D2FF).withValues(alpha: 0.06),
              blurRadius: 50.0,
              spreadRadius: -10.0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: Stack(
            children: [
              // Main content
              Positioned.fill(child: child),

              // Top camera punch-hole & speaker indicator
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    width: 70.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                ),
              ),

              // Subtle inner screen border
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
