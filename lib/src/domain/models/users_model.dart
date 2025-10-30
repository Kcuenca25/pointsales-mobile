import 'dart:convert';

class User {
  int? id;
  String username;
  String email;
  String password;
  String? token;
  Name? name;  // Añadir esta propiedad
  String? phone;  // Añadir esta propiedad
  Address? address;  // Añadir esta propiedad

   User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.token,
    this.name,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'token': token,
      'name': name?.toMap(),
      'phone': phone,
      'address': address?.toMap(),
    };
  }


  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      token: map['token'],
      name: map['name'] != null ? Name.fromMap(map['name']) : null,
      phone: map['phone'],
      address: map['address'] != null ? Address.fromMap(map['address']) : null,
    );
  }


  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}


class Address {
  Geolocation? geolocation;
  String? city;
  String? street;
  int? number;
  String? zipcode;

  Address({
    this.geolocation,
    this.city,
    this.street,
    this.number,
    this.zipcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'geolocation': geolocation?.toMap(),
      'city': city,
      'street': street,
      'number': number,
      'zipcode': zipcode,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      geolocation: map['geolocation'] != null ? Geolocation.fromMap(map['geolocation']) : null,
      city: map['city'],
      street: map['street'],
      number: map['number']?.toInt(),
      zipcode: map['zipcode'],
    );
  }
}

class Geolocation {
  String? lat;
  String? long;

  Geolocation({
    this.lat,
    this.long,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'long': long,
    };
  }

  factory Geolocation.fromMap(Map<String, dynamic> map) {
    return Geolocation(
      lat: map['lat'],
      long: map['long'],
    );
  }
}

class Name {
  String? firstname;
  String? lastname;

  Name({
    this.firstname,
    this.lastname,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstname': firstname,
      'lastname': lastname,
    };
  }

  factory Name.fromMap(Map<String, dynamic> map) {
    return Name(
      firstname: map['firstname'],
      lastname: map['lastname'],
    );
  }
}
