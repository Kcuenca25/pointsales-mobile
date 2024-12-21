// user_model.dart
import 'dart:convert';

class User {
  Address? address;
  int? id;
  String? email;
  String? username;
  String? password;
  Name? name;
  String? phone;
  int? v;

  User({
    this.address,
    this.id,
    this.email,
    this.username,
    this.password,
    this.name,
    this.phone,
    this.v,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address?.toMap(),
      'id': id,
      'email': email,
      'username': username,
      'password': password,
      'name': name?.toMap(),
      'phone': phone,
      'v': v,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      address: map['address'] != null ? Address.fromMap(map['address']) : null,
      id: map['id']?.toInt(),
      email: map['email'],
      username: map['username'],
      password: map['password'],
      name: map['name'] != null ? Name.fromMap(map['name']) : null,
      phone: map['phone'],
      v: map['v']?.toInt(),
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
