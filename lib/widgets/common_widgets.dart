import 'package:flutter/cupertino.dart';
import 'package:evi/theme/app_theme.dart';

class BrandIconBadge extends StatelessWidget {
  const BrandIconBadge({
    super.key,
    required this.label,
    required this.size,
    this.accentColor = AppColors.primary,
  });

  final String label;
  final double size;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          inherit: false,
          fontSize: size * 0.22,
          fontWeight: FontWeight.w700,
          color: accentColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? CupertinoActivityIndicator(color: AppColors.white)
            : Text(
                label,
                style: TextStyle(
                  inherit: false,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            inherit: false,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.separator),
      ),
      child: child,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTheme.body,
      placeholderStyle: AppTheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.separator),
      ),
    );
  }
}
