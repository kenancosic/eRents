import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            icon: SvgPicture.asset('assets/icons/profile-icon.svg'),
            activeIcon: SvgPicture.asset('assets/icons/profile-active.svg'),
            label: '',
          ),
        ],
        selectedFontSize: 0,
        unselectedFontSize: 0,
        currentIndex: currentIndex,
        onTap: onTap,
        showSelectedLabels: false,
        showUnselectedLabels: false, // Hide labels for unselected items
      ),
    );
  }
}
