import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bus.dart';
import '../models/booking.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Bus> _buses = [];
  List<Booking> _bookings = [];
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final busesList = await ApiService.searchBuses('', '', '');
      final bookingsList = await ApiService.getAllBookingsAdmin();
      final usersList = await ApiService.getAllUsersAdmin();

      if (!mounted) return;
      setState(() {
        _buses = busesList.map((e) => Bus.fromJson(e)).toList();
        _bookings = bookingsList.map((e) => Booking.fromJson(e)).toList();
        _users = usersList.map((e) => User.fromJson(e)).toList();
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteRoute(int routeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Delete Bus Route?'),
          content: const Text('Are you sure you want to delete this bus and route? This is permanent.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final res = await ApiService.deleteBusRoute(routeId);

      if (!mounted) return;

      if (res.containsKey('message') && res['message'].toString().toLowerCase().contains('success')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus route deleted successfully'), backgroundColor: Colors.green),
        );
        await _refreshAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to delete route'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting route: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddEditRouteDialog([Bus? bus]) {
    final isEditing = bus != null;
    final formKey = GlobalKey<FormState>();

    final busNameController = TextEditingController(text: bus?.busName ?? '');
    final busNumberController = TextEditingController(text: bus?.busNumber ?? '');
    final sourceController = TextEditingController(text: bus?.source ?? '');
    final destinationController = TextEditingController(text: bus?.destination ?? '');
    final fareController = TextEditingController(text: bus?.fare.toString() ?? '');
    final totalSeatsController = TextEditingController(text: bus?.totalSeats.toString() ?? '40');

    String busType = bus?.busType ?? 'A/C Seater';
    DateTime journeyDate = isEditing ? DateTime.parse(bus.journeyDate) : DateTime.now();
    TimeOfDay departureTime = isEditing ? TimeOfDay(hour: int.parse(bus.departureTime.split(':')[0]), minute: int.parse(bus.departureTime.split(':')[1])) : const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay arrivalTime = isEditing ? TimeOfDay(hour: int.parse(bus.arrivalTime.split(':')[0]), minute: int.parse(bus.arrivalTime.split(':')[1])) : const TimeOfDay(hour: 5, minute: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStateContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Bus Route' : 'Add New Bus'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: busNameController,
                        decoration: const InputDecoration(labelText: 'Operator/Bus Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: busNumberController,
                        decoration: const InputDecoration(labelText: 'Bus Number'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: busType,
                        decoration: const InputDecoration(labelText: 'Bus Type'),
                        items: const [
                          DropdownMenuItem(value: 'A/C Seater', child: Text('A/C Seater')),
                          DropdownMenuItem(value: 'Non A/C Seater', child: Text('Non A/C Seater')),
                          DropdownMenuItem(value: 'A/C Sleeper', child: Text('A/C Sleeper')),
                          DropdownMenuItem(value: 'Non A/C Sleeper', child: Text('Non A/C Sleeper')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => busType = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: totalSeatsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Seats'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: sourceController,
                        decoration: const InputDecoration(labelText: 'Source'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: destinationController,
                        decoration: const InputDecoration(labelText: 'Destination'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: fareController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Fare (₹)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 15),
                      // Date Selector Row
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF9E1A1A)),
                                SizedBox(width: 8),
                                Text('Journey Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDE8E8),
                                foregroundColor: const Color(0xFF9E1A1A),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final minDate = journeyDate.isBefore(DateTime(2020)) ? journeyDate : DateTime(2020);
                                final maxDate = DateTime(2035);
                                final safeInitial = journeyDate.isBefore(minDate)
                                    ? minDate
                                    : (journeyDate.isAfter(maxDate) ? maxDate : journeyDate);

                                final picked = await showDatePicker(
                                  context: dialogStateContext,
                                  initialDate: safeInitial,
                                  firstDate: minDate,
                                  lastDate: maxDate,
                                );
                                if (picked != null) {
                                  setDialogState(() => journeyDate = picked);
                                }
                              },
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(journeyDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Departure Selector Row
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF9E1A1A)),
                                SizedBox(width: 8),
                                Text('Departure:', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(context: dialogStateContext, initialTime: departureTime);
                                if (picked != null) {
                                  setDialogState(() => departureTime = picked);
                                }
                              },
                              child: Text(departureTime.format(dialogStateContext)),
                            ),
                          ],
                        ),
                      ),
                      // Arrival Selector Row
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF9E1A1A)),
                                SizedBox(width: 8),
                                Text('Arrival:', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(context: dialogStateContext, initialTime: arrivalTime);
                                if (picked != null) {
                                  setDialogState(() => arrivalTime = picked);
                                }
                              },
                              child: Text(arrivalTime.format(dialogStateContext)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext); // close dialog safely using dialogContext

                    String formatTime(TimeOfDay t) {
                      final h = t.hour.toString().padLeft(2, '0');
                      final m = t.minute.toString().padLeft(2, '0');
                      return '$h:$m:00';
                    }

                    final payload = {
                      'bus_name': busNameController.text.trim(),
                      'bus_number': busNumberController.text.trim(),
                      'bus_type': busType,
                      'total_seats': int.parse(totalSeatsController.text.trim()),
                      'source': sourceController.text.trim(),
                      'destination': destinationController.text.trim(),
                      'journey_date': DateFormat('yyyy-MM-dd').format(journeyDate),
                      'departure_time': formatTime(departureTime),
                      'arrival_time': formatTime(arrivalTime),
                      'fare': double.parse(fareController.text.trim()),
                    };

                    try {
                      setState(() {
                        _isLoading = true;
                      });

                      final response = isEditing
                          ? await ApiService.updateBusRoute(bus.routeId, payload)
                          : await ApiService.createBusRoute(payload);

                      if (!mounted) return;

                      final msg = response['message']?.toString() ?? '';
                      final isSuccess = msg.toLowerCase().contains('success') ||
                          msg.toLowerCase().contains('updated') ||
                          response.containsKey('routeId');

                      if (isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Route updated successfully' : 'Route created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _refreshAll();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg.isNotEmpty ? msg : 'Action failed'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving bus route: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.directions_bus), text: 'Buses'),
              Tab(icon: Icon(Icons.assignment), text: 'Bookings'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E1A1A)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Buses Tab
                Scaffold(
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    onPressed: () => _showAddEditRouteDialog(),
                    child: const Icon(Icons.add),
                  ),
                  body: _buses.isEmpty
                      ? const Center(child: Text('No buses found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _buses.length,
                          itemBuilder: (context, index) {
                            final bus = _buses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(bus.busName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${bus.source} ➔ ${bus.destination}'),
                                    Text('Date: ${bus.journeyDate.substring(0, 10)} | Dept: ${bus.departureTime.substring(0, 5)}'),
                                    Text('Fare: ₹${bus.fare}'),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddEditRouteDialog(bus),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteRoute(bus.routeId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Bookings Tab
                _bookings.isEmpty
                    ? const Center(child: Text('No bookings found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Booking #${booking.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        booking.status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: booking.status == 'Cancelled' ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Text('Passenger: ${booking.passengerName}'),
                                  Text('Email: ${booking.passengerEmail}'),
                                  Text('Route: ${booking.source} ➔ ${booking.destination}'),
                                  Text('Journey: ${booking.journeyDate.substring(0, 10)}'),
                                  Text('Seats: ${booking.seatNumbers}'),
                                  Text('Total: ₹${booking.totalFare}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                // Users Tab
                _users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.email),
                              trailing: Text('ID: ${user.id}'),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
