class Booking {
  final int id;
  final String seatNumbers;
  final String passengerName;
  final int? passengerAge;
  final String? passengerGender;
  final String passengerEmail;
  final String passengerPhone;
  final double totalFare;
  final String status;
  final String bookedAt;
  final String busName;
  final String busNumber;
  final String busType;
  final String source;
  final String destination;
  final String? boardingStop;
  final String? droppingStop;
  final String journeyDate;
  final String departureTime;
  final String arrivalTime;
  final double fare;

  Booking({
    required this.id,
    required this.seatNumbers,
    required this.passengerName,
    this.passengerAge,
    this.passengerGender,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.totalFare,
    required this.status,
    required this.bookedAt,
    required this.busName,
    required this.busNumber,
    required this.busType,
    required this.source,
    required this.destination,
    this.boardingStop,
    this.droppingStop,
    required this.journeyDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      seatNumbers: json['seat_numbers'] ?? json['seatNumbers'] ?? '',
      passengerName: json['passenger_name'] ?? json['passengerName'] ?? '',
      passengerAge: json['passenger_age'] ?? json['passengerAge'],
      passengerGender: json['passenger_gender'] ?? json['passengerGender'],
      passengerEmail: json['passenger_email'] ?? json['passengerEmail'] ?? '',
      passengerPhone: json['passenger_phone'] ?? json['passengerPhone'] ?? '',
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? 'Confirmed',
      bookedAt: json['booked_at'] ?? json['bookedAt'] ?? '',
      busName: json['bus_name'] ?? json['busName'] ?? '',
      busNumber: json['bus_number'] ?? json['busNumber'] ?? '',
      busType: json['bus_type'] ?? json['busType'] ?? '',
      source: json['source'] ?? '',
      destination: json['destination'] ?? '',
      boardingStop: json['boarding_stop'] ?? json['boardingStop'],
      droppingStop: json['dropping_stop'] ?? json['droppingStop'],
      journeyDate: json['journey_date'] ?? json['journeyDate'] ?? '',
      departureTime: json['departure_time'] ?? json['departureTime'] ?? '',
      arrivalTime: json['arrival_time'] ?? json['arrivalTime'] ?? '',
      fare: double.tryParse(json['fare']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seat_numbers': seatNumbers,
      'passenger_name': passengerName,
      'passenger_age': passengerAge,
      'passenger_gender': passengerGender,
      'passenger_email': passengerEmail,
      'passenger_phone': passengerPhone,
      'total_fare': totalFare,
      'status': status,
      'booked_at': bookedAt,
      'bus_name': busName,
      'bus_number': busNumber,
      'bus_type': busType,
      'source': source,
      'destination': destination,
      'boarding_stop': boardingStop,
      'dropping_stop': droppingStop,
      'journey_date': journeyDate,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'fare': fare,
    };
  }

  String get displaySource => (boardingStop != null && boardingStop!.isNotEmpty) ? boardingStop! : source;
  String get displayDestination => (droppingStop != null && droppingStop!.isNotEmpty) ? droppingStop! : destination;
}
