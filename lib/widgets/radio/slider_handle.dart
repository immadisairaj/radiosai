import 'package:flutter/material.dart';

/// Slider Handle - small oval shape widget
class SliderHandle extends StatelessWidget {
  const SliderHandle({super.key});

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    // bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 5,
      width: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
