import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/settings/initial_radio_index_bloc.dart';
import 'package:radiosai/constants/constants.dart';

final String recentlyPlayed = 'Recently played';

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
            return PopupMenuButton(
              child: ListTile(
                contentPadding: widget.contentPadding,
                title: Text('Starting radio stream'),
                subtitle: (initialRadioStreamIndex >= 0)
                    ? Text(MyConstants.of(context)
                        .radioStreamName[initialRadioStreamIndex])
                    : Text(recentlyPlayed),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.arrow_drop_down_outlined),
                ),
              ),
              itemBuilder: (context) {
                // -1: Recently Played and the rest are 6 streams
                return [-1, 0, 1, 2, 3, 4, 5].map<PopupMenuEntry>((value) {
                  return PopupMenuItem(
                    value: value,
                    child: (value >= 0)
                        ? Text(MyConstants.of(context).radioStreamName[value])
                        : Text(recentlyPlayed),
                  );
                }).toList();
              },
              tooltip: 'favourite radio stream to show on app start',
              initialValue: initialRadioStreamIndex,
              // Offset aligns right side to the widget
              offset: const Offset(1, 0),
              onSelected: (value) {
                _initialRadioIndexBloc.changeInitialRadioIndex.add(value);
              },
            );
          });
    });
  }
}
