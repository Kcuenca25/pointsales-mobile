import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:flutter/material.dart';

class ContactList extends StatelessWidget {
  final List<User> users; 
  final Function(User) onUserSelected; 

  const ContactList({required this.users, required this.onUserSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: users.length, 
      itemBuilder: (context, index) {
        final usuario = users[index]; 
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.grey[300], 
              child: Center(
                child: Text(
                  '${usuario.name?.firstname?.substring(0, 1) ?? ''}${usuario.name?.lastname?.substring(0, 1) ?? ''}', // Iniciales
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          title: Text(
            '${usuario.name?.firstname} ${usuario.name?.lastname}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usuario.username ?? '', style: const TextStyle(color: Colors.grey)),
              Text(usuario.phone ?? '', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          onTap: () {
            onUserSelected(usuario); 
          },
        );
      },
    );
  }
}
