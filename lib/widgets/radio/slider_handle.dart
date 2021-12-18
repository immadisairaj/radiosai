import 'package:flutter/material.dart';

/// Slider Handle - small oval shape widget
class SliderHandle extends StatelessWidget {
  const SliderHandle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 5,
      width: 30,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[400] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
