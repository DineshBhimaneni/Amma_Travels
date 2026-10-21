import 'dart:convert';

class RouteStop {
  final int id;
  final int routeId;
  final String stopName;
  final int stopOrder;
  final String? arrivalTime;
  final String? departureTime;
  final double fareFromSource;
  final double? latitude;
  final double? longitude;

  RouteStop({
    required this.id,
    required this.routeId,
    required this.stopName,
    required this.stopOrder,
    this.arrivalTime,
    this.departureTime,
    required this.fareFromSource,
    this.latitude,
    this.longitude,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      routeId: json['route_id'] is int ? json['route_id'] : int.tryParse(json['route_id']?.toString() ?? '0') ?? 0,
      stopName: json['stop_name']?.toString() ?? '',
      stopOrder: json['stop_order'] is int ? json['stop_order'] : int.tryParse(json['stop_order']?.toString() ?? '0') ?? 0,
      arrivalTime: json['arrival_time']?.toString(),
      departureTime: json['departure_time']?.toString(),
      fareFromSource: double.tryParse(json['fare_from_source']?.toString() ?? '0.0') ?? 0.0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'stop_name': stopName,
      'stop_order': stopOrder,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'fare_from_source': fareFromSource,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Bus {
  final int busId;
  final String busName;
  final String busNumber;
  final String busType;
  final int totalSeats;
  final int routeId;
  final String source;
  final String destination;
  final String journeyDate;
  final String departureTime;
  final String arrivalTime;
  final double fare;
  final List<RouteStop> stops;
  final String imageUrl;
  final List<String> images;

  Bus({
    required this.busId,
    required this.busName,
    required this.busNumber,
    required this.busType,
    required this.totalSeats,
    required this.routeId,
    required this.source,
    required this.destination,
    required this.journeyDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    this.stops = const [],
    this.imageUrl = '',
    this.images = const [],
  });

  static List<String> _getFallbackCatalog(String type, int id) {
    const list = [
      [
        'assets/images/buses/bus_super_luxury.jpg',
        'assets/images/buses/bus_interior_seats.jpg',
        'assets/images/buses/bus_interior_cabin.jpg',
      ],
      [
        'assets/images/buses/bus_volvo_multi_axle.jpg',
        'assets/images/buses/bus_luxury_seats.jpg',
        'assets/images/buses/bus_interior_seats.jpg',
      ],
      [
        'assets/images/buses/bus_ultra_deluxe.jpg',
        'assets/images/buses/bus_interior_cabin.jpg',
        'assets/images/buses/bus_coach_modern.jpg',
      ],
      [
        'assets/images/buses/bus_coach_modern.jpg',
        'assets/images/buses/bus_luxury_seats.jpg',
        'assets/images/buses/bus_express_transit.jpg',
      ],
      [
        'assets/images/buses/bus_tour_luxury.jpg',
        'assets/images/buses/bus_interior_seats.jpg',
        'assets/images/buses/bus_super_luxury.jpg',
      ],
      [
        'assets/images/buses/bus_express_transit.jpg',
        'assets/images/buses/bus_interior_cabin.jpg',
        'assets/images/buses/bus_ultra_deluxe.jpg',
      ],
    ];
    final idx = id > 0 ? (id % list.length) : 0;
    return list[idx];
  }

  factory Bus.fromJson(Map<String, dynamic> json) {
    var rawStops = json['stops'];
    List<RouteStop> parsedStops = [];
    if (rawStops is List) {
      parsedStops = rawStops
          .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    final int bId = json['bus_id'] ?? json['busId'] ?? 0;
    final String bType = json['bus_type'] ?? json['busType'] ?? '';

    final String rawImageUrl = json['image_url'] ?? json['imageUrl'] ?? '';
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawImages);
        if (decoded is List) {
          parsedImages = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final fallbackCatalog = _getFallbackCatalog(bType, bId);
    final effectiveImageUrl = rawImageUrl.isNotEmpty ? rawImageUrl : fallbackCatalog.first;
    final effectiveImages = parsedImages.isNotEmpty ? parsedImages : fallbackCatalog;

    return Bus(
      busId: bId,
      busName: json['bus_name'] ?? json['busName'] ?? '',
      busNumber: json['bus_number'] ?? json['busNumber'] ?? '',
      busType: bType,
      totalSeats: json['total_seats'] ?? json['totalSeats'] ?? 0,
      routeId: json['route_id'] ?? json['routeId'] ?? 0,
      source: json['source'] ?? '',
      destination: json['destination'] ?? '',
      journeyDate: json['journey_date'] ?? json['journeyDate'] ?? '',
      departureTime: json['departure_time'] ?? json['departureTime'] ?? '',
      arrivalTime: json['arrival_time'] ?? json['arrivalTime'] ?? '',
      fare: double.tryParse(json['fare']?.toString() ?? '0.0') ?? 0.0,
      stops: parsedStops,
      imageUrl: effectiveImageUrl,
      images: effectiveImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'bus_name': busName,
      'bus_number': busNumber,
      'bus_type': busType,
      'total_seats': totalSeats,
      'route_id': routeId,
      'source': source,
      'destination': destination,
      'journey_date': journeyDate,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'fare': fare,
      'stops': stops.map((s) => s.toJson()).toList(),
      'image_url': imageUrl,
      'images': images,
    };
  }

  bool get isNonAc {
    final t = '$busType $busName'.toUpperCase();
    return t.contains('NON A/C') ||
        t.contains('NON-A/C') ||
        t.contains('NON A.C') ||
        t.contains('NON AC') ||
        t.contains('NON-AC') ||
        t.contains('EXPRESS') ||
        t.contains('SUPER LUXURY') ||
        t.contains('ULTRA DELUXE') ||
        t.contains('PALLE VELUGU');
  }

  bool get isAc {
    if (isNonAc) return false;
    final t = '$busType $busName'.toUpperCase();
    return t.contains('A/C') ||
        t.contains('AC') ||
        t.contains('GARUDA') ||
        t.contains('AMARAVATHI') ||
        t.contains('VENNELA') ||
        t.contains('VOLVO');
  }

  bool get isSleeper {
    final t = '$busType $busName'.toUpperCase();
    return t.contains('SLEEPER') || t.contains('VENNELA');
  }

  bool get isSeater {
    final t = '$busType $busName'.toUpperCase();
    return t.contains('SEATER') ||
        t.contains('SEAT') ||
        t.contains('EXPRESS') ||
        t.contains('SUPER LUXURY') ||
        t.contains('ULTRA DELUXE') ||
        t.contains('PALLE VELUGU') ||
        (!isSleeper);
  }
}
