import 'package:flutter/material.dart';

/// No Data - a widget to show that no data is present
///
/// returns the widget with a text and a retry button
///
/// [backgroundColor] - specify the background color
///
/// [text] - specify the text to display above retry button
///
/// [onPressed] - specify the function to do when press retry button
class NoData extends StatefulWidget {
  const NoData({
    super.key,
    required this.backgroundColor,
    required this.text,
    required this.onPressed,
  });

  final Color backgroundColor;
  final String text;
  final Function onPressed;

  @override
  State<NoData> createState() => _NoData();
}

class _NoData extends State<NoData> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: widget.onPressed as void Function()?,
              child: const Text('Retry', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
