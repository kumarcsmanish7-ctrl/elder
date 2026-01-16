import 'package:flutter/material.dart';
import 'screens/category_screen.dart';

class CommunityActivityModule {
  static Widget get entryPoint => const CategoryScreen();
  
  static Map<String, WidgetBuilder> get routes => {
    '/community_activity': (context) => const CategoryScreen(),
  };
}
