import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:mp3_info/mp3_info.dart';
import 'package:path_provider/path_provider.dart';

/// mentions if the media type is either radio/media
enum MediaType { radio, media }

// Media Helper is useful to handle common methods used by media/media player
class MediaHelper {
  /// returns a constant url for media - https://dl.sssmediacentre.org/
  static String mediaBaseUrl = 'https://dl.sssmediacentre.org';

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
    String name,
    String? link,
    bool isFileExists,
  ) async {
    String finalUri = link ?? '';
    Duration? duration;

    // 1. Handle manually downloaded files first
    if (isFileExists) {
      finalUri = await changeLinkToFileUri(finalUri);
    }
    // 2. Check the Default Cache Manager
    else if (link != null) {
      FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(link);

      if (fileInfo != null) {
        // If cached, use the local file path for instant loading
        finalUri = fileInfo.file.path;
      } else {
        // If not cached, use the URL.
        // The player will cache it during playback if you use LockCachingAudioSource.
        finalUri = link;
      }

      // This is still the bottleneck if the file isn't cached yet.
      // If it is cached, estimateDuration(localPath) is near 0ms.
      duration = await estimateDuration(finalUri);
    }

    return MediaItem(
      id: await getFileIdFromUri(finalUri),
      album: 'Radio Sai Global Harmony',
      title: name,
      artist: 'Radio Sai',
      duration: duration,
      artUri: Uri.parse('file://${await getDefaultNotificationImage()}'),
      extras: {'uri': finalUri},
    );
  }

  static Future<Duration?> estimateDuration(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-200000'},
      );
      final bytes = int.tryParse(response.headers['content-length'] ?? '');
      if (bytes == null) return null;

      if (response.statusCode == 206) {
        // 1. Get the TOTAL size from the "content-range" header (e.g., "bytes 0-200000/1545874")
        final rangeHeader = response.headers['content-range'] ?? '';
        final totalSize = int.parse(rangeHeader.split('/').last);

        // 2. Parse the small chunk to get the bitrate
        final mp3 = MP3Processor.fromBytes(response.bodyBytes);
        final bitrateBps = mp3.bitrate * 1000; // Convert kbps to bps

        // 3. Calculate total duration
        if (bitrateBps > 0) {
          final totalSeconds = (totalSize * 8) / bitrateBps;
          return Duration(seconds: totalSeconds.toInt());
        }
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request or parsing
      debugPrint('Error estimating duration: $e');
    }
    return null;
  }

  /// returns the link for file when provided file id.
  /// Fild Id is "something.mp3"
  static String getLinkFromFileId(String id) {
    return '$mediaBaseUrl$id';
  }

  /// returns the name of file from the given link
  /// Example returns "TEST A" when given "https://dl.sssmediacentre.org/TEST_A.mp3"
  static String getNameFromLink(String link) {
    link = link.replaceAll(mediaBaseUrl, '');
    link = link.replaceAll(mediaFileType, '');
    link = link.replaceAll('_', ' ');
    return link;
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
    const albumName = 'Sai Voice';
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
    Directory pathDirectory = await getApplicationDocumentsDirectory();
    return pathDirectory.path;
  }

  /// Get the file path of the notification image
  static Future<String> _getCachedPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    return appDocPath;
  }

  /// Get notification image stored in file,
  /// if not stored, then store the image
  static Future<String> getDefaultNotificationImage() async {
    String path = await _getNotificationFilePath();
    File file = File(path);
    bool fileExists = file.existsSync();
    // if the image already exists, return the path
    if (fileExists) return path;
    // store the image into path from assets then return the path
    final byteData = await rootBundle.load(
      'assets/sai_listens_notification.jpg',
    );
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
