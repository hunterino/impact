import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    Key? key,
    required this.icon,
    required this.color,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      padding: EdgeInsets.zero,
      minWidth: 50,
      height: 50,
      shape: const CircleBorder(),
      elevation: 0,
      child: Icon(
        icon,
        color: iconColor ?? Colors.white,
        size: 30,
      ),
    );
  }
}
