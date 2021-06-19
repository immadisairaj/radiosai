import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// Media Helper is useful to handle common methods used by media/media player
class MediaHelper {
  /// returns a constant url for media - https://dl.radiosai.org/
  static String mediaBaseUrl = 'https://dl.radiosai.org/';

  /// returns a file type ".mp3"
  static String mediaFileType = '.mp3';

  /// Generates and returns a Future\<MediaItem\>
  ///
  /// Parameters:
  ///
  /// name - file name without any '_'
  ///
  /// link - file link which includes dl......
  ///
  /// mediaBaseUrl - string which contains dl...../
  ///
  /// directory - path where the file is being saved
  ///
  /// isFileExists - mention if the file exists to set uri for audio
  static Future<MediaItem> generateMediaItem(
      String name, String link, bool isFileExists) async {
    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    // if file exists, then add file uri
    if (isFileExists) {
      link = await changeLinkToFileUri(link);
    }

    String fileId = await getFileIdFromUri(link);

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

  /// returns the link for file when provided file id.
  /// Fild Id is "something.mp3"
  static String getLinkFromFileId(String id) {
    return '$mediaBaseUrl$id';
  }

  /// changes http link to file - removes base url and appends directory
  ///
  /// returns file URI
  static Future<String> changeLinkToFileUri(String link) async {
    String directory = await getDirectoryPath();
    link = link.replaceAll(mediaBaseUrl, '');
    return 'file://$directory/$link';
  }

  /// Generate a file uri from file id 'something.mp3'
  ///
  /// Takes in directory path (the external path)
  ///
  /// returns file URI
  static String getFileUriFromFileIdWithDirectory(String id, String directory) {
    return 'file://$directory/$id';
  }

  /// changes link to file - removes base url or removes directory
  ///
  /// returns file with extension
  static Future<String> getFileIdFromUri(String uri) async {
    String directory = await getDirectoryPath();
    uri = uri.replaceAll(mediaBaseUrl, '');
    uri = uri.replaceAll('file://$directory/', '');
    return uri;
  }

  /// changes link to file - removes base url or removes directory
  ///
  /// returns file with extension
  ///
  /// difference form getFileIdFromUri is to provide a directory and remove future
  static String getFileIdFromUriWithDirectory(String uri, String directory) {
    uri = uri.replaceAll(mediaBaseUrl, '');
    uri = uri.replaceAll('file://$directory/', '');
    return uri;
  }

  /// returns the path for media directory
  ///
  /// doesn't care if the directory is created or not
  static Future<String> getDirectoryPath() async {
    final publicDirectoryPath = await _getPublicPath();
    final albumName = 'Sai Voice/Media';
    final mediaDirectoryPath = '$publicDirectoryPath/$albumName';
    return mediaDirectoryPath;
  }

  /// returns the path for cached media directory
  ///
  /// doesn't care if the directory is created or not
  static Future<String> getCachedDirectoryPath() async {
    String cachedPath = await _getCachedPath();
    return '$cachedPath/Media';
  }

  static Future<String> _getPublicPath() async {
    var path = await ExtStorage.getExternalStorageDirectory();
    return path;
  }

  /// Get the file path of the notification image
  static Future<String> _getCachedPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    return appDocPath;
  }

  /// Get notification image stored in file,
  ///
  /// if not stored, then store the image
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

  /// Get the file path of the notification image
  static Future<String> _getNotificationFilePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/sai_listens_notification.jpg';
    return filePath;
  }
}
