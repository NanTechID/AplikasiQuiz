import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/theme.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({super.key, required this.child});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<NotificationProvider>(context);
    if (_notificationProvider != provider) {
      _notificationProvider = provider;
      _notificationProvider!.addListener(_onNotificationChanged);
    }
  }

  @override
  void dispose() {
    _notificationProvider?.removeListener(_onNotificationChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNotificationChanged() {
    if (!mounted) return;
    if (_notificationProvider?.currentNotification != null) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final notification = provider.currentNotification;
            if (notification == null && _controller.isDismissed) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _offsetAnimation,
                child: Material(
                  elevation: 12,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Icon / Badge
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notification?.title ?? 'Notification',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification?.body ?? '',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            provider.clearCurrentNotification();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
