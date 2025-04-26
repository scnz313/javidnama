import 'package:flutter/material.dart';

class AppAnimations {
  // Page transition animations
  static const pageTransitionDuration = Duration(milliseconds: 300);
  static const pageTransitionCurve = Curves.easeInOut;

  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeIn,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  // Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  // Slide animation
  static Widget slideIn({
    required Widget child,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }

  // Combined animation (fade + scale)
  static Widget fadeScaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        // Ensure opacity is strictly between 0.0 and 1.0
        final safeValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: safeValue,
          child: Transform.scale(scale: safeValue, child: child),
        );
      },
      child: child,
    );
  }

  // Custom page route with animations
  static PageRouteBuilder customPageRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: duration,
    );
  }

  // Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }

  // Custom animated container
  static Widget animatedContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  // Custom animated opacity
  static Widget animatedOpacity({
    required Widget child,
    required bool visible,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedOpacity(
      duration: duration,
      curve: curve,
      opacity: visible ? 1.0 : 0.0,
      child: child,
    );
  }

  // Custom animated cross fade
  static Widget animatedCrossFade({
    required Widget firstChild,
    required Widget secondChild,
    required bool showFirst,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedCrossFade(
      duration: duration,
      firstCurve: curve,
      secondCurve: curve,
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState:
          showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
