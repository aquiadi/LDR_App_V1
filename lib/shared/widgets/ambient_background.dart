import 'dart:ui';
import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;
  
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        
        // Ambient glow top-left
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        
        // Ambient glow bottom-right
        Positioned(
          bottom: -150,
          right: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
