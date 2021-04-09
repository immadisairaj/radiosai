import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/stream_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';

class StreamList extends StatefulWidget {
  StreamList({Key key,
              this.panelController,
              this.animationController,}) : super(key: key);

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
            int streamIndex = snapshot.data ?? 0;
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
                  }
                  widget.panelController.close();
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
