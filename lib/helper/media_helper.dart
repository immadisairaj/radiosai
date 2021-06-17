import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// Media Helper is useful to handle common methods used by media/media player
class MediaHelper {
  // Generates and returns a future media item
  // name - file name without any '_'
  // link - file link which includes dl......
  // mediaBaseUrl - string which contains dl...../
  // directory - path where the file is being saved
  // isFileExists - mention if the file exists to set uri for audio
  static Future<MediaItem> generateMediaItem(String name, String link,
      String mediaBaseUrl, String directory, bool isFileExists) async {
    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    // if file exists, then add file uri
    if (isFileExists) {
      link = changeLinkToFileUri(link, mediaBaseUrl, directory);
    }

    String fileId = getFileIdFromUri(link, mediaBaseUrl, directory);

    Map<String, dynamic> _extras = {
      'uri': link,
    };

    // Set media item to tell the clients what is playing
    // extras['uri'] contains the audio source
    final tempMediaItem = MediaItem(
      // the file name which includes '_' and file extension is id
      id: fileId,
      album: "Radio Sai Global Harmony",
      // name of the file without '_' or extensions
      title: name,
      // art of the media
      artUri: Uri.parse('file://$path'),
      // extras['uri'] contain the uri of the media
      extras: _extras,
    );

    return tempMediaItem;
  }

  // changes link to file - removes base url and appends directory
  // returns file URI
  static String changeLinkToFileUri(
      String link, String mediaBaseUrl, String directory) {
    link = link.replaceAll(mediaBaseUrl, '');
    return 'file://$directory/$link';
  }

  // changes link to file - removes base url or removes directory
  // returns file with extension
  static String getFileIdFromUri(
      String link, String mediaBaseUrl, String directory) {
    link = link.replaceAll(mediaBaseUrl, '');
    link = link.replaceAll('file://$directory/', '');
    return link;
  }

  // Get notification image stored in file,
  // if not stored, then store the image
  static Future<String> getNotificationImage() async {
    String path = await _getNotificationFilePath();
    File file = File(path);
    bool fileExists = file.existsSync();
    // if the image already exists, return the path
    if (fileExists) return path;
    // store the image into path from assets then return the path
    final byteData =
        await rootBundle.load('assets/sai_listens_notification.jpg');
    // if file is not created, create to write into the file
    file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  // Get the file path of the notification image
  static Future<String> _getNotificationFilePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/sai_listens_notification.jpg';
    return filePath;
  }
}
