import 'package:flutter/material.dart';
// import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/stream_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class StreamList extends StatefulWidget {
  StreamList({Key key,
              // this.flutterRadioPlayer,
              // this.audioPlayer,
              this.panelController,
              this.animationController,}) : super(key: key);

  // FlutterRadioPlayer flutterRadioPlayer;
  // final AudioPlayer audioPlayer;
  final PanelController panelController;
  final AnimationController animationController;

  @override
  _StreamList createState() => _StreamList(); 
}

class _StreamList extends State<StreamList> {

  @override
  Widget build(BuildContext context) {
    return Consumer<StreamBloc>(
      builder: (context, _streamBloc, child) {
        return StreamBuilder<int>(
          stream: _streamBloc.indexStream,
          builder: (context, snapshot) {
            int streamIndex = snapshot.data;
            return slide(_streamBloc, streamIndex);
          },
        );
      },
    );
  }

  Widget slide(StreamBloc _streamBloc, int streamIndex) {
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
            child: Card(
              elevation: 1.4,
              shadowColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  if(index != streamIndex) {
                    _streamBloc.changeStreamIndex.add(index);
                    try {
                      // await widget.flutterRadioPlayer.isPlaying()
                      // .then((value) {
                      //   widget.flutterRadioPlayer.stop();
                      // })
                      // .then((value) => widget.panelController.close());
                      // if(widget.audioPlayer.playing) widget.audioPlayer.stop();
                      widget.panelController.close();
                    } catch(Exception) {
                      widget.panelController.close();
                    }
                  } else {
                    widget.panelController.close();
                  }
                },
                child: Container(
                  child: Center(
                    child: Text(MyConstants.of(context).streamName[index]),
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
