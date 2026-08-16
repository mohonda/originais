import 'package:flutter/material.dart';

class CustomFloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomFloatingAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 16.0,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withValues( alpha: 0.05),
          // color: Colors.grey,
          
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.transparent.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          title, 
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
