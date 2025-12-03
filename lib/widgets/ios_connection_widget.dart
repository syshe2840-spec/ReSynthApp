import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: false);
    
    // Scale animation (for tap feedback)
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    if (widget.isLoading) {
      return Color(0xFFFF9500); // iOS Orange
    } else if (widget.status == "CONNECTED") {
      return Color(0xFF34C759); // iOS Green
    } else {
      return Color(0xFFFF3B30); // iOS Red
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
        // Button with iOS style
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.isLoading ? null : widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Outer glow (pulsing)
                      BoxShadow(
                        color: _getPrimaryColor().withOpacity(0.3 * (1 - _pulseController.value)),
                        blurRadius: 40 + (40 * _pulseController.value),
                        spreadRadius: 0 + (10 * _pulseController.value),
                      ),
                      // Inner shadow (always visible)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF2F2F7),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: widget.isLoading
                      ? CupertinoActivityIndicator(
                          radius: 20,
                          color: _getPrimaryColor(),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPrimaryColor().withOpacity(0.1),
                          ),
                          child: Icon(
                            CupertinoIcons.power,
                            color: _getPrimaryColor(),
                            size: 60,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Status text with iOS style
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Text(
            widget.isLoading
                ? context.tr('connecting')
                : widget.status == "DISCONNECTED"
                    ? context.tr('disconnected')
                    : context.tr('connected'),
            key: ValueKey(widget.status + widget.isLoading.toString()),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.41,
              color: _getPrimaryColor(),
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Subtitle
        if (!widget.isLoading)
          Text(
            widget.status == "DISCONNECTED"
                ? 'Tap to connect'
                : 'Connected securely',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.08,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
      ],
    );
  }
}
