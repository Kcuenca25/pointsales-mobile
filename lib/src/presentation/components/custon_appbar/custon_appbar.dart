import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class CustonAppBar extends StatelessWidget {
  const CustonAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ....',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Comprador',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const Spacer(),
        badges.Badge(
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          showBadge: true,
          ignorePointer: false,
          onTap: () {},
          badgeContent: const Text(
            '3', 
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeAnimation: const badges.BadgeAnimation.scale(
            animationDuration: Duration(seconds: 5),
            curve: Curves.fastOutSlowIn,
          ),
          badgeStyle: const badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
            elevation: 0,
          ),
          child: InkWell(
            onTap: () {},
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.blue,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
