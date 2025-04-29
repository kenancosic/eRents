import 'package:flutter/material.dart';

class CustomSnackBar {
  static SnackBar showSnackBar({
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xff89C5B7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor ?? const Color(0xff99D6C7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static SnackBar showSuccessSnackBar(String message) {
    return showSnackBar(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xff89C5B7),
      iconColor: const Color(0xff99D6C7),
    );
  }

  static SnackBar showErrorSnackBar(String message) {
    return showSnackBar(
      message: message,
      icon: Icons.error,
      backgroundColor: const Color(0xffCB7676),
      iconColor: const Color(0xffCB7676),
    );
  }
}
