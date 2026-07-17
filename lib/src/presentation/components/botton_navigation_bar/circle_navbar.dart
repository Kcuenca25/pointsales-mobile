// import 'package:flutter/material.dart';
// import 'package:circle_nav_bar/circle_nav_bar.dart';

// class CustomCircleNavBar extends StatelessWidget {
//   final int selectedIndex;
//   final ValueChanged<int> onItemTapped;

//   const CustomCircleNavBar({
//     super.key,
//     required this.selectedIndex,
//     required this.onItemTapped,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CircleNavBar(
//       activeIndex: selectedIndex, 
//       onTap: onItemTapped,
//       color: Colors.white,

//       activeIcons: const [
//         Icon(Icons.home, color: Colors.white),
//         Icon(Icons.groups_outlined, color: Colors.white),
//         Icon(Icons.add_shopping_cart, color: Colors.white),
//         Icon(Icons.file_copy_outlined, color: Colors.white),
//         Icon(Icons.person_2_outlined, color: Colors.white),
//         Icon(Icons.map_outlined, color: Colors.white), 
//       ],
//       inactiveIcons: const [
//         Icon(Icons.home, color: Colors.grey),
//         Icon(Icons.groups_outlined, color: Colors.grey),
//         Icon(Icons.add_shopping_cart, color: Colors.grey),
//         Icon(Icons.file_copy_outlined, color: Colors.grey),
//         Icon(Icons.person_2_outlined, color: Colors.grey),
//         Icon(Icons.map_outlined, color: Colors.grey),
        
//       ],
//       height: 60,
//       circleWidth: 60,
//       padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
//       cornerRadius: const BorderRadius.only(
//         topLeft: Radius.circular(8),
//         topRight: Radius.circular(8),
//         bottomRight: Radius.circular(0),
//         bottomLeft: Radius.circular(0),
//       ),
//       shadowColor: Colors.black54,
//       circleShadowColor: Colors.black54,
//       elevation: 10,
//       circleColor: const Color.fromARGB(255, 228, 56, 156), 
//     );
//   }
// }
