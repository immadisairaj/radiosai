import 'package:flutter/material.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class StreamList extends StatefulWidget {
  StreamList({Key key, this.flutterRadioPlayer,
              this.panelController,
              this.animationController,}) : super(key: key);

  FlutterRadioPlayer flutterRadioPlayer;
  PanelController panelController;
  AnimationController animationController;

  @override
  _StreamList createState() => _StreamList(); 
}

class _StreamList extends State<StreamList> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> setStream(int index) async {
    final SharedPreferences prefs = await _prefs;
    final int streamIndex = index;
    setState(() {
      prefs.setInt('stream', streamIndex).then((bool success) {
        return streamIndex;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: GridView.builder(
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 5/4,
        ),
        itemCount: MyConstants.of(context).streamName.length,
        primary: false,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () async {
              setStream(index);
              await widget.flutterRadioPlayer.isPlaying()
              .then((value) {
                widget.flutterRadioPlayer.stop();
              })
              .then((value) => widget.panelController.close());
            },
              child: Card(
                elevation: 1.8,
                child: Center(
                  child: Text(MyConstants.of(context).streamName[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
