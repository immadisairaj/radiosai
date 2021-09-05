import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/settings/initial_radio_index_bloc.dart';
import 'package:radiosai/constants/constants.dart';

final String recentlyPlayed = 'Recently played';

/// StartingRadioStream - Option to change the radio stream open on app start
class StartingRadioStream extends StatefulWidget {
  StartingRadioStream({
    Key key,
    this.contentPadding,
  }) : super(key: key);

  final EdgeInsetsGeometry contentPadding;

  @override
  _StartingRadioStream createState() => _StartingRadioStream();
}

class _StartingRadioStream extends State<StartingRadioStream> {
  @override
  Widget build(BuildContext context) {
    return Consumer<InitialRadioIndexBloc>(
        // listen to change of initial radio stream index
        builder: (context, _initialRadioIndexBloc, child) {
      return StreamBuilder<int>(
          stream: _initialRadioIndexBloc.initialRadioIndexStream,
          builder: (context, snapshot) {
            int initialRadioStreamIndex = snapshot.data ?? -1;

            String subtitle = (initialRadioStreamIndex >= 0)
                ? MyConstants.of(context)
                    .radioStreamName[initialRadioStreamIndex]
                : recentlyPlayed;

            return Tooltip(
              message: 'favourite radio stream to show on app start',
              child: ListTile(
                contentPadding: widget.contentPadding,
                title: Text('Starting radio stream'),
                subtitle: Text(subtitle),
                onTap: () async {
                  showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Starting radio stream'),
                          contentPadding: EdgeInsets.only(top: 10),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Scrollbar(
                              radius: Radius.circular(8),
                              isAlwaysShown: true,
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                    itemCount: MyConstants.of(context)
                                            .radioStreamName
                                            .length +
                                        1,
                                    shrinkWrap: true,
                                    primary: false,
                                    itemBuilder: (context, index) {
                                      int value = index - 1;
                                      return RadioListTile(
                                          activeColor:
                                              Theme.of(context).accentColor,
                                          value: value,
                                          selected:
                                              value == initialRadioStreamIndex,
                                          title: (value >= 0)
                                              ? Text(MyConstants.of(context)
                                                  .radioStreamName[value])
                                              : Text(recentlyPlayed),
                                          groupValue: initialRadioStreamIndex,
                                          onChanged: (value) {
                                            _initialRadioIndexBloc
                                                .changeInitialRadioIndex
                                                .add(value);
                                            Navigator.of(context).pop();
                                          });
                                    }),
                              ),
                            ),
                          ),
                          buttonPadding: EdgeInsets.all(4),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      });
                },
              ),
            );
          });
    });
  }
}
