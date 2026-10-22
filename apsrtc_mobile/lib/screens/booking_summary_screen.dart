import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';


class PassengerFormData {
  final String seat;
  final TextEditingController nameController;
  final TextEditingController ageController;
  String gender;

  PassengerFormData({
    required this.seat,
    required this.nameController,
    required this.ageController,
    this.gender = 'Male',
  });

  void dispose() {
    nameController.dispose();
    ageController.dispose();
  }
}

class BookingSummaryScreen extends StatefulWidget {
  final Bus bus;
  final List<String> selectedSeats;
  final String boardingPoint;
  final String droppingPoint;
  final Map<String, String>? adjacentGenderRestrictions;
  final Map<String, String>? initialSeatGenders;

  const BookingSummaryScreen({
    super.key,
    required this.bus,
    required this.selectedSeats,
    required this.boardingPoint,
    required this.droppingPoint,
    this.adjacentGenderRestrictions,
    this.initialSeatGenders,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<PassengerFormData> _passengers;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _passengers = widget.selectedSeats.asMap().entries.map((entry) {
      final index = entry.key;
      final seat = entry.value;
      final reqGender = widget.adjacentGenderRestrictions?[seat];
      final defaultGender = widget.initialSeatGenders?[seat] ?? reqGender ?? 'Male';

      return PassengerFormData(
        seat: seat,
        nameController: TextEditingController(
          text: index == 0 ? (authProvider.user?.name ?? '') : '',
        ),
        ageController: TextEditingController(),
        gender: defaultGender,
      );
    }).toList();

    if (authProvider.user != null) {
      _emailController.text = authProvider.user!.email;
    }
  }

  @override
  void dispose() {
    for (var p in _passengers) {
      p.dispose();
    }
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    // Enforce adjacent gender policy before submitting
    for (var p in _passengers) {
      final req = widget.adjacentGenderRestrictions?[p.seat];
      if (req != null && p.gender != req) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This seat is not for your gender (Seat ${p.seat} is reserved for $req passengers only).',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Directly proceed without QR scanning

    setState(() {
      _isSubmitting = true;
    });

    final totalFare = widget.selectedSeats.length * widget.bus.fare;
    final passengersList = _passengers.map((p) => {
          'seat': p.seat,
          'name': p.nameController.text.trim(),
          'age': int.parse(p.ageController.text.trim()),
          'gender': p.gender,
        }).toList();

    final primaryName = _passengers.map((p) => p.nameController.text.trim()).join(', ');
    final primaryAge = int.tryParse(_passengers.first.ageController.text.trim()) ?? 0;
    final primaryGender = _passengers.first.gender;

    final result = await ApiService.createBooking(
      busId: widget.bus.busId,
      routeId: widget.bus.routeId,
      seatNumbers: widget.selectedSeats.join(','),
      passengerName: primaryName,
      passengerAge: primaryAge,
      passengerGender: primaryGender,
      passengerEmail: _emailController.text.trim(),
      passengerPhone: _phoneController.text.trim(),
      totalFare: totalFare,
      passengers: passengersList,
      boardingStop: widget.boardingPoint,
      droppingStop: widget.droppingPoint,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (result.containsKey('message') && !result.containsKey('bookingId') && !result.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to book ticket'), backgroundColor: Colors.redAccent),
      );
    } else {
      // Success modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Booking Successful!'),
              ],
            ),
            content: Text(
              'Your ticket for ${widget.selectedSeats.length} passenger${widget.selectedSeats.length > 1 ? 's' : ''} (Seat${widget.selectedSeats.length > 1 ? 's' : ''} ${widget.selectedSeats.join(', ')}) has been confirmed. Confirmation details sent to ${_emailController.text.trim()}.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  Navigator.pushNamed(context, '/profile');
                },
                child: const Text('View Ticket'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFare = widget.selectedSeats.length * widget.bus.fare;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Journey details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JOURNEY DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.bus.busName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₹${widget.bus.fare.toStringAsFixed(2)} / seat'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${widget.bus.busType} | ${widget.selectedSeats.length} Seats (${widget.selectedSeats.join(', ')})'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FROM', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(widget.bus.source, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('TO', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(widget.bus.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date: ${widget.bus.journeyDate}'),
                          Text('Time: ${widget.bus.departureTime.length >= 5 ? widget.bus.departureTime.substring(0, 5) : widget.bus.departureTime}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Passenger Form Cards
              ..._passengers.asMap().entries.map((entry) {
                final index = entry.key;
                final passenger = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: theme.primaryColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PASSENGER ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Seat ${passenger.seat}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        if (widget.adjacentGenderRestrictions?[passenger.seat] != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                  ? const Color(0xFFFCE4EC)
                                  : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                    ? const Color(0xFFF48FB1)
                                    : const Color(0xFF90CAF9),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                      ? Icons.female
                                      : Icons.male,
                                  size: 18,
                                  color: widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                      ? const Color(0xFFD81B60)
                                      : const Color(0xFF1976D2),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                        ? 'Female Only: Adjacent seat is occupied by a female passenger.'
                                        : 'Male Only: Adjacent seat is occupied by a male passenger.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.adjacentGenderRestrictions![passenger.seat] == 'Female'
                                          ? const Color(0xFFC2185B)
                                          : const Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        TextFormField(
                          controller: passenger.nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name (Seat ${passenger.seat})',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter name for Passenger ${index + 1}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: passenger.ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Age';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age < 1 || age > 120) {
                                    return 'Valid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: passenger.gender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Icons.wc_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    final req = widget.adjacentGenderRestrictions?[passenger.seat];
                                    if (req != null && val != req) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.block, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'This seat is not for your gender (Seat ${passenger.seat} is reserved for $req passengers only).',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.redAccent.shade700,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      setState(() {
                                        passenger.gender = req;
                                      });
                                      return;
                                    }
                                    setState(() {
                                      passenger.gender = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Contact Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.contact_mail_outlined, color: theme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CONTACT INFORMATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ticket confirmation and notifications will be sent to these details.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Contact Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number (10 digits)',
                          hintText: 'Enter 10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact phone';
                          }
                          final cleanPhone = value.trim().replaceAll(RegExp(r'\s+|-'), '');
                          if (cleanPhone.length != 10) {
                            return 'Mobile number must be exactly 10 digits';
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checkout total details
              Card(
                color: theme.primaryColor.withOpacity(0.05),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Seat Numbers (${widget.selectedSeats.length})'),
                          Text(
                            widget.selectedSeats.join(', '),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Fare'),
                          Text(
                            '₹${totalFare.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E1A1A)))
                  : ElevatedButton(
                      onPressed: _confirmBooking,
                      child: Text('Pay & Confirm ₹${totalFare.toStringAsFixed(2)}'),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
