import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class SaiImage extends StatefulWidget {
  SaiImage({
    Key key,
    this.heroTag,
    this.imageUrl,
    this.fileName,
  }) : super(key: key);

  final String heroTag;
  final String imageUrl;
  final String fileName;

  @override
  _SaiImage createState() => _SaiImage();
}

class _SaiImage extends State<SaiImage> with TickerProviderStateMixin {
  // the animation status took from Stack Overflow answer
  // for the question "Flutter InteractiveViewer
  // onInteractionEnd return to scale of 1.0"
  final TransformationController _transformationController =
      TransformationController();
  Animation<Matrix4> _animationReset;
  AnimationController _controllerReset;
  Matrix4 _initialMatrix4Value;
  double _scale = 1;

  bool _fullScreen = false;
  AnimationController _animationController;

  bool _isCopying = false;

  @override
  void initState() {
    _initialMatrix4Value = _transformationController.value;
    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    _controllerReset.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double appBarSize =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    Size screenSize = MediaQuery.of(context).size;
    bool isScaleFit = _scale <= 1;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              GestureDetector(
                onTap: _toggleFullScreen,
                onDoubleTap: () {
                  // do nothing: to prevent single tap twice
                },
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    onInteractionUpdate: _onInteractionUpdate,
                    onInteractionStart: _onInteractionStart,
                    onInteractionEnd: _onInteractionEnd,
                    panEnabled: (isScaleFit) ? false : true,
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 3,
                    boundaryMargin: (isScaleFit)
                        ? EdgeInsets.all(double.infinity)
                        : EdgeInsets.zero,
                    child: Hero(
                        tag: widget.heroTag,
                        child: SizedBox(
                          height: screenSize.height,
                          width: screenSize.width,
                          child: Image(
                            image: CachedNetworkImageProvider(widget.imageUrl),
                            fit: BoxFit.contain,
                          ),
                        )),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -_animationController.value * appBarSize),
                child: Container(
                  height: appBarSize,
                  child: SafeArea(
                    child: AppBar(
                      title: Text(widget.fileName),
                      backgroundColor: Colors.transparent,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.download_outlined),
                          tooltip: 'Save image',
                          splashRadius: 24,
                          onPressed: () => _saveImage(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Below are image saving to gallery methods

  void _saveImage() async {
    if (!_isCopying) {
      _isCopying = true;
      final publicDirectoryPath = await _getPublicPath();
      final albumName = 'Sai Voice/Sai Inspires';
      final imageDirectoryPath = '$publicDirectoryPath/$albumName';
      var permission = await _canSave();
      if (!permission) {
        _showSnackBar(context, 'Accept storage permission to save image',
            Duration(seconds: 2));
        return;
      }
      await new Directory(imageDirectoryPath).create(recursive: true);
      var imageFilePath = '$imageDirectoryPath/${widget.fileName}.jpg';
      var imageFile = new File(imageFilePath);
      if (imageFile.existsSync()) {
        _showSnackBar(context, 'Image already saved', Duration(seconds: 1));
        return;
      }
      var cacheFile = await _getCachedFile();
      imageFile.writeAsBytesSync(cacheFile.readAsBytesSync());
      // save to gallery after saved to external file
      GallerySaver.saveImage(imageFilePath, albumName: albumName)
          .then((isSave) {
        if (isSave) {
          _showSnackBar(context, 'Saved to gallery', Duration(seconds: 1));
        }
      });
    }
  }

  Future<String> _getPublicPath() async {
    var path = await ExtStorage.getExternalStorageDirectory();
    return path;
  }

  Future<File> _getCachedFile() async {
    return await DefaultCacheManager().getSingleFile(widget.imageUrl);
  }

  Future<bool> _canSave() async {
    var status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) {
      return true;
    } else {
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ))
        .closed
        .then((value) {
      _isCopying = false;
    });
  }

  // Below are toggling full screen methods

  void _toggleFullScreen() {
    _fullScreen = !_fullScreen;
    _toogleAppBar();
    _toogleStatusBar();
  }

  Future<void> _toogleAppBar() async {
    if (!_fullScreen) {
      await _animationController.reverse();
    } else {
      await _animationController.forward();
    }
  }

  void _toogleStatusBar() {
    if (_fullScreen) {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
  }

  // Below are image animation methods

  void _onAnimateReset() {
    _transformationController.value = _animationReset.value;
    if (!_controllerReset.isAnimating) {
      _animationReset?.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset.reset();
    }
  }

  void _animateResetInitialize() {
    _controllerReset.reset();
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: _initialMatrix4Value,
    ).animate(_controllerReset);
    _animationReset.addListener(_onAnimateReset);
    _controllerReset.forward();
  }

  void _animateResetStop() {
    _controllerReset.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset.reset();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (_controllerReset.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    double endScale = _transformationController.value.getMaxScaleOnAxis();
    if (endScale <= 1) {
      _animateResetInitialize();
    } else {
      _animateResetStop();
    }
  }
}