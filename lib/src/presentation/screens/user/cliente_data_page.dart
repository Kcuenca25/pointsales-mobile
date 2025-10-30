import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:flutter/material.dart';


class UserInfoPage extends StatelessWidget {
  final User usuario;
  final Function(User) onProductListNavigate;

  const UserInfoPage({
    super.key, 
    required this.usuario, 
    required this.onProductListNavigate,
  });

    String _getUserInitials() {
    final firstName = usuario.name?.firstname;
    final lastName = usuario.name?.lastname;
    
    final firstInitial = (firstName?.isNotEmpty ?? false) ? firstName![0] : '';
    final lastInitial = (lastName?.isNotEmpty ?? false) ? lastName![0] : '';
    
    return '$firstInitial$lastInitial';
  }


  String _getFullName() {
    final firstName = usuario.name?.firstname ?? '';
    final lastName = usuario.name?.lastname ?? '';
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CustomBarRow(
                title: 'Informacion',
                onBackButtonPressed: () => Navigator.pop(context),
                backgroundColor: Colors.blueAccent,
                textColor: Colors.black,
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _getUserInitials(),
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _getFullName(),
                style: const TextStyle(fontSize: 24),
              ),
              Text(
                usuario.username,
                style: const TextStyle(color: Colors.grey),
              ),
              if (usuario.phone != null && usuario.phone!.isNotEmpty)
                Text(
                  usuario.phone!,
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      ),

    );
  }
}
