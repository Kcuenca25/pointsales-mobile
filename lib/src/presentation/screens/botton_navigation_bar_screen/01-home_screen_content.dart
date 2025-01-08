import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/contact_list.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_cards/custon_cards.dart';
import 'package:flutter/material.dart';

class HomeScreenContent extends StatefulWidget {
  final Function(User) onUserPageNavigate;

  const HomeScreenContent({Key? key, required this.onUserPageNavigate}) : super(key: key);

  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<User>> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = ApiServices().fetchAllUsers(); // Método para obtener usuarios desde la API
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const CustonAppBar(),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estadísticas', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Custon_Cards(),
                const SizedBox(height: 20),
                const Text('Clientes', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                FutureBuilder<List<User>>(
                  future: futureUsers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay usuarios disponibles.'));
                    }

                    final users = snapshot.data!;
                    return ContactList(
                      users: users,
                      onUserSelected: widget.onUserPageNavigate,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
