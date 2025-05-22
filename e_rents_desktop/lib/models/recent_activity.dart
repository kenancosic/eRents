import 'package:flutter/material.dart';

enum ActivityType { maintenance, message, system }

class RecentActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final DateTime date;
  final IconData icon;
  final String? onTapRoute; // e.g., '/maintenance/issue-id'
  final Map<String, String>? onTapRouteParams;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
    required this.icon,
    this.onTapRoute,
    this.onTapRouteParams,
  });
}
