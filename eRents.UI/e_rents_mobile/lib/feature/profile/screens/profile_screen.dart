import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchBar_1 extends StatelessWidget {
  const SearchBar_1({super.key});

  @override
  Widget build(BuildContext context) {
    return  const BaseScreen(
      title: 'Profile', // Title for the app bar if shown
      body:LocationWidget(title: 'title', 
      location: 'New Orelans', 
      )
    );
  }
}