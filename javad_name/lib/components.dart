import 'package:flutter/material.dart';
import 'animations.dart';
import 'constants.dart';

class AppComponents {
  // Modern card with elevation and rounded corners
  static Widget modernCard({
    required Widget child,
    Color? backgroundColor,
    double elevation = 2.0,
    double borderRadius = 12.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor ?? AppColors.surface,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  // Modern button with animation
  static Widget modernButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 8.0,
    EdgeInsetsGeometry? padding,
    bool isFullWidth = false,
  }) {
    return AppAnimations.scaleIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: isFullWidth ? double.infinity : null,
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.primary,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern text input field
  static Widget modernTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double borderRadius = 8.0,
    Color? borderColor,
  }) {
    return AppAnimations.fadeIn(
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textDark, fontSize: 16.0),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: borderColor ?? AppColors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? AppColors.primary.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? AppColors.primary,
              width: 2.0,
            ),
          ),
          labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.7)),
          hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
        ),
      ),
    );
  }

  // Modern list tile with animation
  static Widget modernListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
    double borderRadius = 8.0,
  }) {
    return AppAnimations.slideIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surface,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 16.0)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textDark.withOpacity(0.7),
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16.0),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern loading indicator
  static Widget modernLoadingIndicator({Color? color, double size = 24.0}) {
    return AppAnimations.fadeIn(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? AppColors.primary,
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  // Modern divider
  static Widget modernDivider({
    Color? color,
    double thickness = 1.0,
    double height = 1.0,
  }) {
    return Divider(
      color: color ?? AppColors.divider,
      thickness: thickness,
      height: height,
    );
  }

  // Modern chip
  static Widget modernChip({
    required String label,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 16.0,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.primary,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
