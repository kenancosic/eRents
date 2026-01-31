import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/features/notifications/providers/notification_provider.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        
        return Theme(
          data: 
          Theme.of(context).copyWith(
            canvasColor: Colors.white,
          ),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/home-icon.svg'),
                activeIcon: SvgPicture.asset('assets/icons/home-active.svg'),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/explore-icon.svg'),
                activeIcon: SvgPicture.asset('assets/icons/explore-active.svg'),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/chat-icon.svg'),
                activeIcon: SvgPicture.asset('assets/icons/chat-active.svg'),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/save-icon.svg'),
                activeIcon: SvgPicture.asset('assets/icons/save-active.svg'),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildProfileIcon(unreadCount, false),
                activeIcon: _buildProfileIcon(unreadCount, true),
                label: '',
              ),
            ],
            selectedFontSize: 0,
            unselectedFontSize: 0,
            currentIndex: currentIndex,
            onTap: onTap,
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        );
      }
    );
  }

  Widget _buildProfileIcon(int unreadCount, bool isActive) {
    final icon = SvgPicture.asset(
      isActive ? 'assets/icons/profile-active.svg' : 'assets/icons/profile-icon.svg',
    );
    
    if (unreadCount <= 0) return icon;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
