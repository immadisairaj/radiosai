import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:radiosai/bloc/media/media_screen_bloc.dart';
import 'package:radiosai/helper/media_helper.dart';

class DownloadHelper {
  static List<DownloadTaskInfo> downloadTasks = [];
  static ReceivePort port = ReceivePort();

  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  static MediaScreenBloc mediaScreenBloc = MediaScreenBloc();

  static List<DownloadTaskInfo> getDownloadTasks() {
    return downloadTasks;
  }

  /// returns the scaffold key which is used by the whole app
  ///
  /// attaches to the base page of the app
  static GlobalKey<ScaffoldState> getScaffoldKey() {
    return scaffoldKey;
  }

  /// returns the bloc for media screen
  /// which is used by the whole app
  ///
  /// attaches to the initialize providers of the app
  static MediaScreenBloc getMediaScreenBloc() {
    return mediaScreenBloc;
  }

  /// Bind the background task for the whole app to download
  ///
  /// also listens to the progress
  static void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      // unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    // _downloadTasks = [];
    port.listen((data) {
      String id = data[0];
      // DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (downloadTasks != null && downloadTasks.isNotEmpty) {
        final task =
            downloadTasks.firstWhere((element) => element.taskId == id);

        // task.status = status;
        task.progress = progress;

        // if (status == DownloadTaskStatus.failed) {
        // remove the file if the task failed
        // FlutterDownloader.remove(taskId: id);
        _showSnackBar(scaffoldKey.currentContext, 'failed downloading',
            const Duration(seconds: 1));
        return;
      }

      // if (status == DownloadTaskStatus.complete) {
      // print('downloaded ${task.name}');
      // show that it is downloaded
      _showSnackBar(
          scaffoldKey.currentContext, 'downloaded', Duration(seconds: 1));

      // _replaceMedia(task);

      // update the media screen state
      bool currentValue = mediaScreenBloc.getCurrentValue() ?? false;
      mediaScreenBloc.changeMediaScreenState.add(!currentValue);
      return;
      // }
      // }
    });
  }

  /// shows the snack bar using the global scaffold key
  static void _showSnackBar(
      BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  /// replace the media item with updated source if the item is in playing queue
  static _replaceMedia(DownloadTaskInfo task) async {
    // replace the uri to downloaded if present in playing queue
    MediaItem mediaItem =
        await MediaHelper.generateMediaItem(task.name, task.link, false);
    if (AudioService.queue == null) return;
    int index = AudioService.queue.indexOf(mediaItem);
    if (index != -1) {
      String uri = await MediaHelper.changeLinkToFileUri(task.link);
      String id = await MediaHelper.getFileIdFromUri(task.link);
      Map<String, dynamic> _params = {
        'id': id,
        'name': task.name,
        'index': index,
        'uri': uri,
      };
      AudioService.customAction('editUri', _params);
    }
  }

  /// callback for the download regarding the status
  // static void downloadCallback(
  //     String id, DownloadTaskStatus status, int progress) {
  //   final SendPort send =
  //       IsolateNameServer.lookupPortByName('downloader_send_port');
  //   send.send([id, status, progress]);
  // }

  // /// Unbind the background task for the whole app to download
  // static void unbindBackgroundIsolate() {
  //   IsolateNameServer.removePortNameMapping('downloader_send_port');
  // }
}

class DownloadTaskInfo {
  final String name;
  final String link;

  String taskId = '';
  int progress = 0;
  // DownloadTaskStatus status = DownloadTaskStatus.undefined;

  DownloadTaskInfo({this.name, this.link});
}
