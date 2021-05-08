import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SaiImage extends StatefulWidget {
  SaiImage({
    Key key,
    this.heroTag,
    this.imageUrl,
  }) : super(key: key);

  final String heroTag;
  final String imageUrl;

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

  final AppBar appBar = AppBar(
    title: Text('Image'),
    backgroundColor: Colors.transparent,
  );

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
        appBar.preferredSize.height + MediaQuery.of(context).padding.top;
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
                onDoubleTap: () {},
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
                          child: Image.network(
                            widget.imageUrl,
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
                    child: appBar,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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

  // Below all are image animation methods

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
