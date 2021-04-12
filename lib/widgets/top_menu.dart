import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/constants/constants.dart';

class TopMenu extends StatefulWidget {
  TopMenu({
    Key key,
  }) : super(key: key);

  @override
  _TopMenu createState() => _TopMenu();
}

class _TopMenu extends State<TopMenu> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: height * 0.05,
          right: width * 0.02,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              iconSize: 30,
              offset: const Offset(-10, 10),
              itemBuilder: (context) {
                // Takes list of data from constants
                return MyConstants.of(context)
                    .menuTitles
                    .map<PopupMenuEntry<String>>((value) {
                  return PopupMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                    ),
                  );
                }).toList();
              },
              onSelected: (value) {
                // TODO: implement on select of menu
              },
            ),
          ),
        ),
      ),
    );
  }
}
