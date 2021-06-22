import 'package:flutter/cupertino.dart';
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
  NoData({
    key,
    @required this.backgroundColor,
    @required this.text,
    @required this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
  final String text;
  final Function onPressed;

  @override
  _NoData createState() => _NoData();
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
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              onPressed: widget.onPressed,
            )
          ],
        ),
      ),
    );
  }
}
