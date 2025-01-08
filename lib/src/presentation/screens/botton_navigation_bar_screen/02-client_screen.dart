import 'package:ecomerce_app/src/presentation/components/contact_list.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_user.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';

class ClientScreen extends StatefulWidget {
  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  late Future<List<User>> futureUsers;
  List<User> allUsers = [];
  List<User> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureUsers = ApiServices().fetchAllUsers();
    futureUsers.then((users) {
      setState(() {
        allUsers = users;
        filteredUsers = users;
      });
    });
  }

  void filterUsers(String query) {
    final users = allUsers.where((user) {
      final fullName = '${user.name?.firstname} ${user.name?.lastname}'.toLowerCase();
      return fullName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustonAppBar(),
              const SizedBox(height: 20),
              CustonSearch(
                controller: searchController,
                onTextChanged: filterUsers,
              ),
              const SizedBox(height: 20),
              const Text(
                'Clientes',
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (filteredUsers.isEmpty)
                const Center(child: Text('No hay usuarios disponibles.'))
              else
                ContactList(users: filteredUsers),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 1, 
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/car_shop_screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/purchase_history');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile_screen');
              break;
            default:
              Navigator.pushReplacementNamed(context, '/user_page');
          }
        },
      ),
    );
  }
}
