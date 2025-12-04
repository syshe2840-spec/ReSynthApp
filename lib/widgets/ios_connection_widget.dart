import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:resynth/common/ios_theme.dart';

class IOSConnectionWidget extends StatefulWidget {
  const IOSConnectionWidget({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.status,
  });

  final bool isLoading;
  final GestureTapCallback onTap;
  final String status;

  @override
  State<IOSConnectionWidget> createState() => _IOSConnectionWidgetState();
}

class _IOSConnectionWidgetState extends State<IOSConnectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for connected state
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
    
    // Scale animation for tap feedback
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    
    // Rotate animation for loading
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
    
    _updateAnimations();
  }

  @override
  void didUpdateWidget(IOSConnectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status || oldWidget.isLoading != widget.isLoading) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isLoading) {
      _pulseController.stop();
      _rotateController.repeat();
    } else if (widget.status == "CONNECTED") {
      _rotateController.stop();
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _rotateController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    if (widget.isLoading) {
      return IOSColors.systemOrange;
    } else if (widget.status == "CONNECTED") {
      return IOSColors.systemGreen;
    } else {
      return IOSColors.systemRed;
    }
  }

  IconData _getIcon() {
    if (widget.isLoading) {
      return CupertinoIcons.arrow_2_circlepath;
    } else if (widget.status == "CONNECTED") {
      return CupertinoIcons.shield_fill;
    } else {
      return CupertinoIcons.shield;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Connection Button
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.isLoading ? null : widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer rings (only when connected)
                if (widget.status == "CONNECTED" && !widget.isLoading)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final opacity = 1 - _pulseController.value;
                      final scale = 1 + (_pulseController.value * 0.3);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getPrimaryColor().withOpacity(opacity * 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Main button container
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        IOSColors.secondarySystemGroupedBackground,
                        IOSColors.secondarySystemGroupedBackground.withOpacity(0.95),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getPrimaryColor().withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getPrimaryColor().withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getPrimaryColor().withOpacity(0.15),
                              _getPrimaryColor().withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: widget.isLoading
                            ? RotationTransition(
                                turns: _rotateController,
                                child: Icon(
                                  _getIcon(),
                                  color: _getPrimaryColor(),
                                  size: 60,
                                ),
                              )
                            : Icon(
                                _getIcon(),
                                color: _getPrimaryColor(),
                                size: 60,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Status Label
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey('${widget.status}_${widget.isLoading}'),
            children: [
              Text(
                widget.isLoading
                    ? context.tr('connecting')
                    : widget.status == "DISCONNECTED"
                        ? context.tr('disconnected')
                        : context.tr('connected'),
                style: IOSTypography.title3.copyWith(
                  color: _getPrimaryColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              if (!widget.isLoading)
                Text(
                  widget.status == "DISCONNECTED"
                      ? 'Tap to connect'
                      : 'Protected connection',
                  style: IOSTypography.footnote.copyWith(
                    color: IOSColors.secondaryLabel,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
