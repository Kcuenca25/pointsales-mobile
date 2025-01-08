import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:flutter/material.dart';

class UserSelect extends StatefulWidget {
  final Function(User) onUserSelected;

  const UserSelect({super.key, required this.onUserSelected});

  @override
  _UserSelectState createState() => _UserSelectState();
}

class _UserSelectState extends State<UserSelect> {
  List<User> users = [];
  User? selectedUser;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      ApiServices apiServices = ApiServices();
      List<User> fetchedUsers = await apiServices.fetchAllUsers();
      setState(() {
        users = fetchedUsers;
      });
    } catch (e) {
      print('Error al cargar los usuarios: $e');
      
    }
  }

  void toggleUserList() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 2.0,
          borderRadius: BorderRadius.circular(16.0),
          child: TextFormField(
            readOnly: true,
            onTap: toggleUserList,
            decoration: InputDecoration(
              hintText: selectedUser != null
                  ? '${selectedUser!.name?.firstname} ${selectedUser!.name?.lastname}'
                  : 'Seleccionar usuario...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.blueAccent,
                ),
                onPressed: toggleUserList,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
        if (isExpanded) // Mostrar la lista solo si está expandida
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${users[index].name?.firstname} ${users[index].name?.lastname}'),
                  onTap: () {
                    setState(() {
                      selectedUser = users[index];
                      isExpanded = false; // Cierra la lista al seleccionar
                    });
                    widget.onUserSelected(selectedUser!); // Llama al callback
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}