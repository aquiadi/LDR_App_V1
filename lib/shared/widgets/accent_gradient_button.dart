import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class AccentGradientButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  
  const AccentGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<AccentGradientButton> createState() => _AccentGradientButtonState();
}

class _AccentGradientButtonState extends State<AccentGradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.accentGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                blurRadius: _glowAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: widget.isLoading 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.text,
                          style: AppTypography.headlineMd.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.icon, color: Colors.white, size: 20),
                        ]
                      ],
                    ),
              ),
            ),
          ),
        );
      }
    );
  }
}
