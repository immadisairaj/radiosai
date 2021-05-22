import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// To be used when no data is available
class NoData extends StatefulWidget {
  NoData({
    key,
    @required this.backgroundColor,
    @required this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
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
                'No Data Available,\ncheck your internet and try again',
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
