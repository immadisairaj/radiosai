import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// To be used inside stack (at top) to display overlay behaviour
class InternetAlert extends StatefulWidget {
  InternetAlert({
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
      duration: Duration(milliseconds: 500),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.red,
              ),
              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Text(
                'No Internet, please check your connection',
                style: TextStyle(
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
