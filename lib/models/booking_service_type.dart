// types.dart
class Service {
  final String id;
  final String name;

  Service({required this.id, required this.name});

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['serviceId'].toString(),
      name: map['serviceName'].toString(),
    );
  }

  Map<String, String> toMap() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Pet {
  final String id;
  final String name;

  Pet({required this.id, required this.name});

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['petId'].toString(),
      name: map['petName'].toString(),
    );
  }

  Map<String, String> toMap() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ServiceVariant {
  final String id;
  final String content;
  final double price;

  ServiceVariant({
    required this.id,
    required this.content,
    required this.price,
  });

  factory ServiceVariant.fromMap(Map<String, dynamic> map) {
    return ServiceVariant(
      id: map['serviceVariantId'].toString(),
      content: map['serviceContent'].toString(),
      price: double.tryParse(map['servicePrice'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'price': price,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class BookingChoice {
  final dynamic service;
  final Pet pet;
  final ServiceVariant? serviceVariant;
  final double price;
  final String bookingDate; // ISO8601 string
  final List<ServiceVariant> variants;

  BookingChoice({
    required this.service,
    required this.pet,
    required this.serviceVariant,
    required this.price,
    required this.bookingDate,
    required this.variants,
  });

  Map<String, dynamic> toMap() {
    return {
      'service': service is Map ? service : {
        'id': service.id,
        'name': service.name,
      },
      'pet': {
        'id': pet.id,
        'name': pet.name,
      },
      'serviceVariant': serviceVariant?.toMap(),
      'price': price,
      'bookingDate': bookingDate,
    };
  }
}