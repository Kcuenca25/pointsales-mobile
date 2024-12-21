import 'package:flutter/material.dart';

class Custon_Cards extends StatelessWidget {
  const Custon_Cards({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Card(
            color: Colors.blueAccent,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.people,color: Colors.white,size: 18,),
                  Text('#', style: TextStyle(color: Colors.white,fontSize: 12),),
                  Text('Total de', style: TextStyle(color: Colors.white,fontSize: 12)),
                  Text('clientes', style: TextStyle(color: Colors.white,fontSize: 12))
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Card(
            color: Colors.orangeAccent,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart,color: Colors.white,size: 18),
                  Text('#', style: TextStyle(color: Colors.white,fontSize: 12)),
                  Text('Compras', style: TextStyle(color: Colors.white,fontSize: 12)),
                  Text('pendientes', style: TextStyle(color: Colors.white,fontSize: 12))
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Card(
            color: Colors.green,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart,color: Colors.white,size: 18),
                  Text('#', style: TextStyle(color: Colors.white,fontSize: 12)),
                  Text('Compras', style: TextStyle(color: Colors.white,fontSize: 12)),
                  Text('completadas', style: TextStyle(color: Colors.white,fontSize: 12))
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
