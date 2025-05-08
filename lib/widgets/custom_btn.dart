import 'package:flutter/material.dart';
class CustomButton extends StatelessWidget {
  final String buttonText;
  final TextStyle textStyle;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color buttonColor;
  final Icon? icon; // Optional icon parameter
  final double? width; // Optional width parameter

  const CustomButton({
    super.key,
    required this.buttonText,
    required this.textStyle,
    required this.onPressed,
    this.borderRadius = 22.0,
    required this.buttonColor,
    this.icon, // Icon is optional
    this.width, // Width is optional
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, // Button background color
        foregroundColor: Colors.white, // Text/icon color (adjust as needed)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        minimumSize: width != null ? Size(width!, 0) : Size(0, 0), // Set width if provided, otherwise no minimum
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce extra padding
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Shrink-wrap the content unless width is specified
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 8), // Space between icon and text
          ],
          Text(
            buttonText,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
