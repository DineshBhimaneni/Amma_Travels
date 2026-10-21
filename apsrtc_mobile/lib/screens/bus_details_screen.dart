import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../services/api_service.dart';
import '../widgets/bus_photo_gallery.dart';
import 'booking_summary_screen.dart';
import 'route_map_screen.dart';

class BusDetailsScreen extends StatefulWidget {
  final Bus bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  List<String> _bookedSeats = [];
  Map<String, String> _seatGender = {};
  final List<String> _selectedSeats = [];
  final Map<String, String> _chosenSeatGenders = {};
  bool _isLoading = true;

  late List<RouteStop> _stops;
  String _selectedBoarding = '';
  String _selectedDropping = '';
  double _currentFare = 0.0;

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.bus.stops);
    _selectedBoarding = widget.bus.source;
    _selectedDropping = widget.bus.destination;
    _currentFare = widget.bus.fare;

    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // 1. If stops not present, fetch full bus details
      if (_stops.isEmpty) {
        final busData = await ApiService.getBusById(widget.bus.routeId);
        if (busData != null && busData['stops'] is List) {
          _stops = (busData['stops'] as List)
              .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }

      // 2. Fallback stops if still empty
      if (_stops.isEmpty) {
        _stops = [
          RouteStop(
            id: 1,
            routeId: widget.bus.routeId,
            stopName: widget.bus.source,
            stopOrder: 1,
            departureTime: widget.bus.departureTime,
            fareFromSource: 0.0,
          ),
          RouteStop(
            id: 2,
            routeId: widget.bus.routeId,
            stopName: widget.bus.destination,
            stopOrder: 2,
            arrivalTime: widget.bus.arrivalTime,
            fareFromSource: widget.bus.fare,
          ),
        ];
      }

      // Match boarding stop
      final bMatch = _stops.firstWhere(
        (s) => s.stopName.toLowerCase() == _selectedBoarding.toLowerCase(),
        orElse: () => _stops.first,
      );
      _selectedBoarding = bMatch.stopName;

      // Match dropping stop
      final dMatch = _stops.firstWhere(
        (s) => s.stopName.toLowerCase() == _selectedDropping.toLowerCase(),
        orElse: () => _stops.last,
      );
      _selectedDropping = dMatch.stopName;

      _recalculateFare();

      // 3. Fetch booked seats & gender details
      await _fetchSeatData();
    } catch (e) {
      // Handle error gracefully
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSeatData() async {
    try {
      final seatsList = await ApiService.getBookedSeats(widget.bus.routeId);
      final newBooked = seatsList.map((e) => e.toString()).toList();

      final Map<String, String> newGenderMap = {};
      if (_selectedBoarding.isNotEmpty && _selectedDropping.isNotEmpty) {
        final details = await ApiService.getSeatDetails(
          widget.bus.routeId,
          _selectedBoarding,
          _selectedDropping,
        );
        for (var item in details) {
          if (item is Map && item['seat'] != null) {
            final s = item['seat'].toString();
            newGenderMap[s] = item['gender']?.toString() ?? '';
            if (!newBooked.contains(s)) {
              newBooked.add(s);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookedSeats = newBooked;
          _seatGender = newGenderMap;
          _selectedSeats.removeWhere((s) => _bookedSeats.contains(s));
        });
      }
    } catch (_) {}
  }

  void _recalculateFare() {
    if (_stops.isEmpty) return;
    final bStop = _stops.firstWhere((s) => s.stopName == _selectedBoarding, orElse: () => _stops.first);
    final dStop = _stops.firstWhere((s) => s.stopName == _selectedDropping, orElse: () => _stops.last);

    final diff = (dStop.fareFromSource - bStop.fareFromSource).abs();
    _currentFare = math.max(50.0, diff > 0 ? diff : widget.bus.fare);
  }

  void _onBoardingChanged(String? newBoarding) async {
    if (newBoarding == null) return;
    setState(() {
      _selectedBoarding = newBoarding;
      final bStop = _stops.firstWhere((s) => s.stopName == newBoarding, orElse: () => _stops.first);
      final dStop = _stops.firstWhere((s) => s.stopName == _selectedDropping, orElse: () => _stops.last);

      // If dropping stop is before or same as boarding, set dropping stop to last available stop
      if (dStop.stopOrder <= bStop.stopOrder) {
        final subsequent = _stops.where((s) => s.stopOrder > bStop.stopOrder).toList();
        if (subsequent.isNotEmpty) {
          _selectedDropping = subsequent.last.stopName;
        }
      }
      _recalculateFare();
    });
    await _fetchSeatData();
  }

  void _onDroppingChanged(String? newDropping) async {
    if (newDropping == null) return;
    setState(() {
      _selectedDropping = newDropping;
      _recalculateFare();
    });
    await _fetchSeatData();
  }

  void _onSeatTap(String seatNum) {
    if (_bookedSeats.contains(seatNum)) {
      final gender = _seatGender[seatNum];
      final genderText = (gender != null && gender.isNotEmpty) ? ' ($gender)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat $seatNum is already reserved$genderText and cannot be selected.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedSeats.contains(seatNum)) {
      setState(() {
        _selectedSeats.remove(seatNum);
        _chosenSeatGenders.remove(seatNum);
      });
      return;
    }

    final adjRestriction = getAdjacentGenderRestriction(seatNum);
    if (adjRestriction != null) {
      _handleRestrictedSeatTap(seatNum, adjRestriction);
      return;
    }

    if (_selectedSeats.length < 6) {
      setState(() {
        _selectedSeats.add(seatNum);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select a maximum of 6 seats')),
      );
    }
  }

  Future<void> _handleRestrictedSeatTap(String seatNum, String adjRestriction) async {
    final adjSeat = getAdjacentSeat(seatNum) ?? '';

    final chosenGender = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: adjRestriction == 'Female' ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  adjRestriction == 'Female' ? Icons.female : Icons.male,
                  color: adjRestriction == 'Female' ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat $seatNum Selection', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Adjacent to $adjRestriction (Seat $adjSeat)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                adjRestriction == 'Female'
                    ? 'Seat $seatNum is beside a female passenger. According to bus rules, only a female passenger can book this seat.'
                    : 'Seat $seatNum is beside a male passenger. According to bus rules, only a male passenger can book this seat.',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                'Who is travelling in this seat?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'Male'),
                      icon: const Icon(Icons.male, color: Color(0xFF1976D2)),
                      label: const Text('Male'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: adjRestriction == 'Male' ? const Color(0xFF1976D2) : Colors.grey.shade300,
                          width: adjRestriction == 'Male' ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'Female'),
                      icon: const Icon(Icons.female, color: Color(0xFFD81B60)),
                      label: const Text('Female'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: adjRestriction == 'Female' ? const Color(0xFFD81B60) : Colors.grey.shade300,
                          width: adjRestriction == 'Female' ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (chosenGender == null) return;

    if (chosenGender != adjRestriction) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This seat is not for your gender (Seat $seatNum is reserved for $adjRestriction passengers only).',
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

    setState(() {
      if (_selectedSeats.length < 6) {
        _selectedSeats.add(seatNum);
        _chosenSeatGenders[seatNum] = chosenGender;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can select a maximum of 6 seats')),
        );
      }
    });
  }

  void _openRouteMap() {
    final busWithStops = Bus(
      busId: widget.bus.busId,
      busName: widget.bus.busName,
      busNumber: widget.bus.busNumber,
      busType: widget.bus.busType,
      totalSeats: widget.bus.totalSeats,
      routeId: widget.bus.routeId,
      source: widget.bus.source,
      destination: widget.bus.destination,
      journeyDate: widget.bus.journeyDate,
      departureTime: widget.bus.departureTime,
      arrivalTime: widget.bus.arrivalTime,
      fare: _currentFare,
      stops: _stops,
      imageUrl: widget.bus.imageUrl,
      images: widget.bus.images,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapScreen(
          bus: busWithStops,
          boardingStop: _selectedBoarding,
          droppingStop: _selectedDropping,
        ),
      ),
    );
  }

  String? getAdjacentSeat(String seat) {
    if (seat.isEmpty) return null;
    final alphaMatch = RegExp(r'^(\d+)([A-Za-z])$').firstMatch(seat.trim());
    if (alphaMatch != null) {
      final row = alphaMatch.group(1);
      final col = alphaMatch.group(2)!.toUpperCase();
      if (col == 'A') return '${row}B';
      if (col == 'B') return '${row}A';
      if (col == 'C') return '${row}D';
      if (col == 'D') return '${row}C';
    }

    final num = int.tryParse(seat.trim());
    if (num != null && num > 0) {
      final rem = (num - 1) % 4;
      if (rem == 0) return (num + 1).toString();
      if (rem == 1) return (num - 1).toString();
      if (rem == 2) return (num + 1).toString();
      if (rem == 3) return (num - 1).toString();
    }
    return null;
  }

  String? getAdjacentGenderRestriction(String seat) {
    final adj = getAdjacentSeat(seat);
    if (adj == null) return null;
    if (_bookedSeats.contains(adj)) {
      final gender = _seatGender[adj]?.toLowerCase() ?? '';
      if (gender.startsWith('f') || gender == 'female') return 'Female';
      if (gender.startsWith('m') || gender == 'male') return 'Male';
    }
    return null;
  }

  void _proceedToCheckout() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // Bus with updated segment fare & stops
    final updatedBus = Bus(
      busId: widget.bus.busId,
      busName: widget.bus.busName,
      busNumber: widget.bus.busNumber,
      busType: widget.bus.busType,
      totalSeats: widget.bus.totalSeats,
      routeId: widget.bus.routeId,
      source: _selectedBoarding,
      destination: _selectedDropping,
      journeyDate: widget.bus.journeyDate,
      departureTime: widget.bus.departureTime,
      arrivalTime: widget.bus.arrivalTime,
      fare: _currentFare,
      stops: _stops,
      imageUrl: widget.bus.imageUrl,
      images: widget.bus.images,
    );

    final Map<String, String> restrictions = {};
    for (var s in _selectedSeats) {
      final r = getAdjacentGenderRestriction(s);
      if (r != null) {
        restrictions[s] = r;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryScreen(
          bus: updatedBus,
          selectedSeats: _selectedSeats,
          boardingPoint: _selectedBoarding,
          droppingPoint: _selectedDropping,
          adjacentGenderRestrictions: restrictions,
          initialSeatGenders: _chosenSeatGenders,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedSeats.clear();
          _chosenSeatGenders.clear();
        });
        _fetchSeatData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandRed = Color(0xFF9E1A1A);
    final totalSeatsCount = widget.bus.totalSeats;

    final currentBoardingObj = _stops.firstWhere(
      (s) => s.stopName == _selectedBoarding,
      orElse: () => _stops.isNotEmpty
          ? _stops.first
          : RouteStop(id: 0, routeId: 0, stopName: '', stopOrder: 0, fareFromSource: 0.0),
    );

    final boardingOptions = _stops.isNotEmpty ? _stops.sublist(0, math.max(1, _stops.length - 1)) : <RouteStop>[];
    final droppingOptions = _stops.where((s) => s.stopOrder > currentBoardingObj.stopOrder).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bus.busName),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View Route Map',
            onPressed: _openRouteMap,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bus Photo Showcase Banner (RedBus/AbhiBus style)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Stack(
                      children: [
                        BusImageBanner(
                          bus: widget.bus,
                          height: 175,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () => showBusPhotoGallery(context, widget.bus),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'View Gallery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Info card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.bus.source} ➔ ${widget.bus.destination}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Text(
                                '₹${_currentFare.toStringAsFixed(0)} / seat',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.bus.busType, style: const TextStyle(color: Colors.grey)),
                              Text(
                                'Dept: ${widget.bus.departureTime.length >= 5 ? widget.bus.departureTime.substring(0, 5) : widget.bus.departureTime}',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Route Map Banner Button
                  InkWell(
                    onTap: _openRouteMap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.map, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Route Map & All Halts',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Explore ${_stops.length} intermediate stops with GPS coordinates',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Intermediate Stops Dropdown Selectors
                  Card(
                    color: const Color(0xFFFFFBEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alt_route, color: brandRed, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Boarding & Dropping Halts',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fare dynamically recalculates based on your chosen segment!',
                            style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                          ),
                          const SizedBox(height: 14),

                          // Boarding Point Dropdown
                          const Text(
                            '📍 Boarding Point (Origin):',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedBoarding.isNotEmpty ? _selectedBoarding : null,
                                items: boardingOptions.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s.stopName,
                                    child: Text('${s.stopName} (${s.departureTime ?? s.arrivalTime ?? "Start"})'),
                                  );
                                }).toList(),
                                onChanged: _onBoardingChanged,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Dropping Point Dropdown
                          const Text(
                            '🎯 Dropping Point (Destination):',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDropping.isNotEmpty ? _selectedDropping : null,
                                items: droppingOptions.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s.stopName,
                                    child: Text('${s.stopName} (${s.arrivalTime ?? s.departureTime ?? "End"})'),
                                  );
                                }).toList(),
                                onChanged: _onDroppingChanged,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Segment: $_selectedBoarding ➔ $_selectedDropping',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  '₹${_currentFare.toStringAsFixed(0)} / seat',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: brandRed, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Legends
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _buildLegend(Colors.white, Border.all(color: Colors.grey.shade400, width: 1.5), null, 'Available'),
                      _buildLegend(Colors.amber.shade700, null, Icons.check, 'Selected'),
                      _buildLegend(const Color(0xFFE3F2FD), Border.all(color: const Color(0xFF90CAF9), width: 1.5), Icons.male, 'Booked (M)'),
                      _buildLegend(const Color(0xFFFCE4EC), Border.all(color: const Color(0xFFF48FB1), width: 1.5), Icons.female, 'Booked (F)'),
                      _buildLegend(Colors.white, Border.all(color: const Color(0xFFF48FB1), width: 1.5), Icons.female, 'Ladies Available'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Seat Selection Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Seats (2+2 Bus Layout)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brandRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Max 6 Seats',
                          style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Realistic Bus Coach Layout (2 + 2 with Central Aisle)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Front of bus header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.door_front_door_outlined, size: 20, color: Colors.grey.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DOOR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'FRONT / WINDSHIELD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'DRIVER',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.sports_motorsports_rounded, size: 20, color: brandRed),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Seat Rows (2 + 2 layout with Central Walking Aisle)
                        ..._buildBusSeatRows(totalSeatsCount),

                        const SizedBox(height: 12),
                        // Back of Bus Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          child: Text(
                            '— REAR OF BUS —',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selection Summary & Proceed Button
                  Card(
                    color: brandRed.withOpacity(0.06),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: brandRed.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Seats Selected: ${_selectedSeats.isEmpty ? "None" : _selectedSeats.join(', ')}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Total: ₹${(_selectedSeats.length * _currentFare).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: brandRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Proceed to Passenger Details (${_selectedSeats.length} Seats)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildBusSeatRows(int totalSeats) {
    final int rowCount = (totalSeats / 4).ceil();
    final List<Widget> rows = [];

    for (int r = 0; r < rowCount; r++) {
      final int s1 = (r * 4) + 1;
      final int s2 = (r * 4) + 2;
      final int s3 = (r * 4) + 3;
      final int s4 = (r * 4) + 4;

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Block (2 Seats)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(child: _buildSeatWidget(s1, totalSeats)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSeatWidget(s2, totalSeats)),
                  ],
                ),
              ),

              // Central Walking Aisle
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Text(
                    'AISLE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Right Block (2 Seats)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(child: _buildSeatWidget(s3, totalSeats)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSeatWidget(s4, totalSeats)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildSeatWidget(int seatNumInt, int totalSeats) {
    if (seatNumInt > totalSeats) {
      return const SizedBox(height: 52);
    }

    final seatNum = seatNumInt.toString();
    final isBooked = _bookedSeats.contains(seatNum);
    final isSelected = _selectedSeats.contains(seatNum);
    final gender = _seatGender[seatNum]?.toLowerCase() ?? '';
    final adjRestriction = !isBooked ? getAdjacentGenderRestriction(seatNum) : null;

    final isFemale = isBooked && (gender.startsWith('f') || gender == 'female');
    final isMale = isBooked && (gender.startsWith('m') || gender == 'male');

    Color bgColor = Colors.white;
    Border? border = Border.all(color: Colors.grey.shade400, width: 1.5);
    Color textColor = Colors.black87;
    IconData? genderIcon;
    Color iconColor = Colors.grey;

    if (isSelected) {
      bgColor = Colors.amber.shade700;
      border = Border.all(color: Colors.amber.shade900, width: 2);
      textColor = Colors.white;
    } else if (isBooked) {
      if (isFemale) {
        bgColor = const Color(0xFFFCE4EC); // Soft pink
        border = Border.all(color: const Color(0xFFF48FB1), width: 1.5);
        textColor = const Color(0xFFC2185B);
        genderIcon = Icons.female;
        iconColor = const Color(0xFFD81B60);
      } else if (isMale) {
        bgColor = const Color(0xFFE3F2FD); // Soft blue
        border = Border.all(color: const Color(0xFF90CAF9), width: 1.5);
        textColor = const Color(0xFF1565C0);
        genderIcon = Icons.male;
        iconColor = const Color(0xFF1976D2);
      } else {
        bgColor = Colors.grey.shade200;
        border = Border.all(color: Colors.grey.shade300, width: 1.5);
        textColor = Colors.grey.shade600;
        genderIcon = Icons.person;
        iconColor = Colors.grey.shade500;
      }
    } else if (adjRestriction == 'Female') {
      // Available seat next to female (Ladies indicator)
      bgColor = Colors.white;
      border = Border.all(color: const Color(0xFFF48FB1), width: 1.5);
      textColor = Colors.black87;
    } else {
      // Normal Available seat
      bgColor = Colors.white;
      border = Border.all(color: Colors.grey.shade400, width: 1.5);
      textColor = Colors.black87;
    }

    final String tooltipMsg;
    if (isBooked) {
      tooltipMsg = 'Seat $seatNum: Booked (${isFemale ? "Female" : isMale ? "Male" : "Occupied"})';
    } else if (isSelected) {
      tooltipMsg = 'Seat $seatNum: Selected';
    } else if (adjRestriction == 'Female') {
      tooltipMsg = 'Seat $seatNum: Available (Reserved for Ladies only)';
    } else if (adjRestriction == 'Male') {
      tooltipMsg = 'Seat $seatNum: Available (Reserved for Male only)';
    } else {
      tooltipMsg = 'Seat $seatNum: Available';
    }

    return Tooltip(
      message: tooltipMsg,
      child: InkWell(
        onTap: () => _onSeatTap(seatNum),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Headrest styling at top of seat
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 6,
                  width: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.4)
                        : (isBooked ? iconColor.withOpacity(0.3) : Colors.grey.shade300),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),

              // Ladies indicator in top-right corner for available seat beside female
              if (!isBooked && !isSelected && adjRestriction == 'Female')
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE4EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.female, size: 9, color: Color(0xFFD81B60)),
                  ),
                ),

              // Seat number & status icon in center
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seatNum,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, size: 12, color: Colors.white)
                    else if (isBooked && genderIcon != null)
                      Icon(genderIcon, size: 13, color: iconColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, Border? border, IconData? icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            border: border,
            borderRadius: BorderRadius.circular(6),
          ),
          child: icon != null ? Icon(icon, size: 14, color: color == Colors.amber.shade700 ? Colors.white : Colors.blueGrey) : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    );
  }
}
