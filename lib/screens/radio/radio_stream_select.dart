import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/widgets/radio/slider_handle.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class RadioStreamSelect extends StatefulWidget {
  const RadioStreamSelect({
    super.key,
    this.panelController,
    this.radius,
  });

  final PanelController? panelController;
  final Radius? radius;

  @override
  _RadioStreamSelect createState() => _RadioStreamSelect();
}

class _RadioStreamSelect extends State<RadioStreamSelect> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RadioIndexBloc>(
      builder: (context, _radioIndexBloc, child) {
        return StreamBuilder<int?>(
          stream: _radioIndexBloc.radioIndexStream as Stream<int?>?,
          builder: (context, snapshot) {
            int index = snapshot.data ?? 0;
            return GestureDetector(
              // handle open panel on tap, when small screen
              onTap: () => widget.panelController!.open(),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.all(widget.radius!),
                ),
                margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const SliderHandle(),
                    _slide(_radioIndexBloc, index),
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
  Widget _slide(RadioIndexBloc _radioIndexBloc, int radioIndex) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: width * 0.4 / (height * 0.27 / 2),
      ),
      itemCount: MyConstants.of(context)!.radioStreamHttps.length,
      // override the default top padding
      padding: const EdgeInsets.only(top: 10),
      primary: false,
      shrinkWrap: true,
      itemBuilder: (context, widgetIndex) {
        // check if the radio selected index matches the widget
        bool isMatch = (widgetIndex == radioIndex);
        String radioName = MyConstants.of(context)!
            .radioStreamHttps
            .keys
            .toList()[widgetIndex];
        return Padding(
          padding:
              isBigScreen ? const EdgeInsets.all(4) : const EdgeInsets.all(2),
          child: Card(
            elevation: 1.5,
            shadowColor: Theme.of(context).colorScheme.onSecondary,
            color: isMatch
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () async {
                // change only if panel is open
                if (widget.panelController!.isPanelOpen) {
                  // update only if the index differes from actual index
                  // to avoid unnecessary update of streams
                  if (!isMatch) {
                    _radioIndexBloc.changeRadioIndex.add(widgetIndex);
                    // close the panel if different stream is selected
                    widget.panelController!.close();
                  }
                }
              },
              child: Center(
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text(
                      radioName,
                      style: TextStyle(
                        fontSize: 16.5,
                        color: isMatch
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
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
