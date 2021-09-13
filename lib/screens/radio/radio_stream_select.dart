import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/widgets/radio/slider_handle.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class RadioStreamSelect extends StatefulWidget {
  RadioStreamSelect({
    Key key,
    this.panelController,
    this.radius,
  }) : super(key: key);

  final PanelController panelController;
  final Radius radius;

  @override
  _RadioStreamSelect createState() => _RadioStreamSelect();
}

class _RadioStreamSelect extends State<RadioStreamSelect> {
  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Consumer<RadioIndexBloc>(
      builder: (context, _radioIndexBloc, child) {
        return StreamBuilder<int>(
          stream: _radioIndexBloc.radioIndexStream,
          builder: (context, snapshot) {
            int index = snapshot.data ?? 0;
            return GestureDetector(
              // handle open panel on tap, when small screen
              onTap: () => widget.panelController.open(),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkTheme ? Colors.grey[700] : Colors.white,
                  borderRadius: BorderRadius.all(widget.radius),
                ),
                margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    SliderHandle(),
                    _slide(_radioIndexBloc, index, isDarkTheme),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// widget for slide widget
  ///
  /// shows the selection of different radio streams
  Widget _slide(
      RadioIndexBloc _radioIndexBloc, int radioIndex, bool isDarkTheme) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50);
    return GridView.builder(
      gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: width * 0.4 / (height * 0.27 / 2),
      ),
      itemCount: MyConstants.of(context).radioStream.length,
      // override the default top padding
      padding: EdgeInsets.only(top: 10),
      primary: false,
      shrinkWrap: true,
      itemBuilder: (context, widgetIndex) {
        // check if the radio selected index matches the widget
        bool isMatch = (widgetIndex == radioIndex);
        String radioName =
            MyConstants.of(context).radioStream.keys.toList()[widgetIndex];
        return Padding(
          padding: isBigScreen ? EdgeInsets.all(4) : EdgeInsets.all(2),
          child: Card(
            elevation: 1.5,
            shadowColor:
                isDarkTheme ? Colors.white : Theme.of(context).primaryColor,
            color: isMatch
                ? (isDarkTheme ? Colors.black : Theme.of(context).primaryColor)
                : (isDarkTheme ? Colors.grey[800] : null),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () async {
                // change only if panel is open
                if (widget.panelController.isPanelOpen) {
                  // update only if the index differes from actual index
                  // to avoid unnecessary update of streams
                  if (!isMatch) {
                    _radioIndexBloc.changeRadioIndex.add(widgetIndex);
                    // close the panel if different stream is selected
                    widget.panelController.close();
                  }
                }
              },
              child: Container(
                child: Center(
                  child: Text(
                    radioName,
                    style: TextStyle(
                      fontSize: 16.5,
                      color: isMatch ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
