import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Internet Alert - alerts if there is no internet connection
///
/// To be used inside stack (at top) to display overlay behaviour
///
/// takes in [hasInternet] value (have to input with stream of data false/true)
class InternetAlert extends StatefulWidget {
  const InternetAlert({
    key,
    @required this.hasInternet,
  }) : super(key: key);

  final bool hasInternet;

  @override
  _InternetAlert createState() => _InternetAlert();
}

class _InternetAlert extends State<InternetAlert> {
  // Build a widget when there is no internet to alert the user
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.hasInternet ? 0.0 : 1.0,
      duration: Duration(milliseconds: (widget.hasInternet) ? 1000 : 100),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: (widget.hasInternet) ? Colors.green : Colors.red,
              ),
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Text(
                (widget.hasInternet) ? 'Back Online' : 'No Internet connection',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
