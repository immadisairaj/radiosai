import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio_index_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class RadioStreamSelect extends StatefulWidget {
  RadioStreamSelect({
    Key key,
    this.panelController,
  }) : super(key: key);

  final PanelController panelController;

  @override
  _RadioStreamSelect createState() => _RadioStreamSelect();
}

class _RadioStreamSelect extends State<RadioStreamSelect> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RadioIndexBloc>(
      builder: (context, _radioIndexBloc, child) {
        return StreamBuilder<int>(
          stream: _radioIndexBloc.radioIndexStream,
          builder: (context, snapshot) {
            int index = snapshot.data ?? 0;
            return slide(_radioIndexBloc, index);
          },
        );
      },
    );
  }

  Widget slide(RadioIndexBloc _radioIndexBloc, int index) {
    return Padding(
      // TODO: change the number 25 to automatic scale (or keep it as it is)
      padding: const EdgeInsets.only(top: 25),
      child: GridView.builder(
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 5 / 4,
        ),
        itemCount: MyConstants.of(context).radioStreamName.length,
        primary: false,
        shrinkWrap: true,
        itemBuilder: (context, widgetIndex) {
          return Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              elevation: 1.4,
              shadowColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  // update only if the index differes from actual index
                  // to avoid unnecessary update of streams
                  if (widgetIndex != index) {
                    _radioIndexBloc.changeRadioIndex.add(widgetIndex);
                  }
                  // close the panel and update handling is done in the player
                  widget.panelController.close();
                },
                child: Container(
                  child: Center(
                    child: Text(MyConstants.of(context).radioStreamName[widgetIndex]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}