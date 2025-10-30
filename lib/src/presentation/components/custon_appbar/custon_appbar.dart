import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_select/user_select.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/model_orden.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onOrdenTerminada;
  final bool showTitle; 
  final Function(Order, User, List<ArticuloItem>)? onOrdenCreadaCompleta;
  final Customer? currentCustomer; 
  final String? companyName; 
  final String? userName; 


  const CustomAppBar({
    super.key,
    required this.title,
    this.onOrdenTerminada,
    this.showTitle = true,
    this.onOrdenCreadaCompleta,
    this.currentCustomer, 
    this.companyName, 
    this.userName,
  });


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName?.toUpperCase() ?? 'MI EMPRESA', 
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userName ?? 'Usuario', 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          
          // Título centrado
          if (showTitle)
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const Spacer(),
          
          // Icono de notificaciones
          badges.Badge(
            showBadge: OrderDraftState.hasDraft,
            position: badges.BadgePosition.topEnd(top: -10, end: -5),
            badgeContent: const Text(
              '1',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(
              shape: badges.BadgeShape.circle,
              badgeColor: Colors.red,
              padding: EdgeInsets.all(5),
              elevation: 0,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
              onPressed: () {
                if (OrderDraftState.hasDraft) {
                  final customer = currentCustomer ?? Customer(
                    id: 0,
                    name: 'Cliente Temporal',
                    email: 'temp@email.com',
                    phone: '000-000-0000',
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NuevaOrdenPage(
                        customer: customer,
                        onOrdenCreada: (orden, customer, articulos) {
                          onOrdenTerminada?.call();
                        },
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("No tienes órdenes incompletas"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}