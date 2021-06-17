import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:radiosai/bloc/media/media_screen_bloc.dart';
import 'package:radiosai/helper/media_helper.dart';

class DownloadHelper {
  static List<DownloadTaskInfo> _downloadTasks = [];
  static ReceivePort _port = ReceivePort();

  static GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static MediaScreenBloc _mediaScreenBloc = MediaScreenBloc();

  static List<DownloadTaskInfo> getDownloadTasks() {
    return _downloadTasks;
  }

  static GlobalKey<ScaffoldState> getScaffoldKey() {
    return _scaffoldKey;
  }

  static MediaScreenBloc getMediaScreenBloc() {
    return _mediaScreenBloc;
  }

  static void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    // _downloadTasks = [];
    _port.listen((data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (_downloadTasks != null && _downloadTasks.isNotEmpty) {
        final task =
            _downloadTasks.firstWhere((element) => element.taskId == id);

        task.status = status;
        task.progress = progress;

        if (status == DownloadTaskStatus.failed) {
          // remove the file if the task failed
          FlutterDownloader.remove(taskId: id);
          _showSnackBar(_scaffoldKey.currentContext, 'failed downloading',
              Duration(seconds: 1));
          return;
        }

        if (status == DownloadTaskStatus.complete) {
          print('downloaded ${task.name}');
          // show that it is downloaded
          _showSnackBar(
              _scaffoldKey.currentContext, 'downloaded', Duration(seconds: 1));

          _replaceMedia(task);

          // update the media screen state
          bool currentValue = _mediaScreenBloc.getCurrentValue() ?? false;
          _mediaScreenBloc.changeMediaScreenState.add(!currentValue);
          return;
        }
      }
    });
  }

  static void _showSnackBar(
      BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  static _replaceMedia(DownloadTaskInfo task) async {
    // replace the uri to downloaded if present in playing queue
    MediaItem mediaItem = await MediaHelper.generateMediaItem(
        task.name, task.link, task.mediaBaseUrl, task.directory, false);
    if (AudioService.queue == null) return;
    int index = AudioService.queue.indexOf(mediaItem);
    if (index != -1) {
      String uri = MediaHelper.changeLinkToFileUri(
          task.link, task.mediaBaseUrl, task.directory);
      Map<String, dynamic> _params = {
        'name': task.name,
        'index': index,
        'uri': uri,
      };
      AudioService.customAction('editUri', _params);
    }
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  static void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }
}

class DownloadTaskInfo {
  final String name;
  final String link;

  final String mediaBaseUrl;
  final String directory;

  String taskId = '';
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  DownloadTaskInfo({this.name, this.link, this.mediaBaseUrl, this.directory});
}
