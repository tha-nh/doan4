import 'package:flutter/material.dart';

class NotificationPopup extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final Duration duration;

  const NotificationPopup({
    Key? key,
    required this.title,
    required this.body,
    this.onTap,
    this.duration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () {
                    _dismiss();
                    widget.onTap?.call();
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with close button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _dismiss,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _dismiss,
                                    child: const Text('Đóng'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _dismiss();
                                      widget.onTap?.call();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Xem chi tiết'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative: Simple toast-style notification
class NotificationToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;

  const NotificationToast({
    Key? key,
    required this.message,
    this.icon = Icons.notifications,
    this.backgroundColor = const Color(0xFF2196F3),
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<NotificationToast> createState() => _NotificationToastState();

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.notifications,
    Color backgroundColor = const Color(0xFF2196F3),
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => NotificationToast(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _animation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
