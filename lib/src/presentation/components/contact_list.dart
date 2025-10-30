import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:flutter/material.dart';

class ContactList extends StatelessWidget {
  final List<User> users;
  final Function(User, Offset) onUserSelected;
    // Llaves para cada usuario
  final Map<int, GlobalKey> itemKeys = {};


  ContactList({
    required this.users,
    required this.onUserSelected,
    super.key,
  }) {
    for (int i = 0; i < users.length; i++) {
      itemKeys[i] = GlobalKey();
    }
  }

   String _getUserInitials(User user) {  // Accept user parameter
    final firstName = user.name?.firstname;
    final lastName = user.name?.lastname;
    
    final firstInitial = (firstName?.isNotEmpty ?? false) ? firstName![0] : '';
    final lastInitial = (lastName?.isNotEmpty ?? false) ? lastName![0] : '';
    
    return '$firstInitial$lastInitial';
  }


  String _getFullName(User user) {
    final firstName = user.name?.firstname ?? '';
    final lastName = user.name?.lastname ?? '';
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final usuario = users[index];
        final key = itemKeys[index];
        return ListTile(
  key: key,
  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
  leading: ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          _getUserInitials(usuario),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
  title: Text(
    _getFullName(usuario),
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        usuario.username,
        style: const TextStyle(color: Colors.grey),
      ),
      if (usuario.phone?.isNotEmpty ?? false)
        Text(
          usuario.phone!,
          style: const TextStyle(color: Colors.grey),
        ),
    ],
  ),
  onTap: () {
    final RenderBox renderBox = key!.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    onUserSelected(usuario, position);
  },
);

      },
    );
  }
}