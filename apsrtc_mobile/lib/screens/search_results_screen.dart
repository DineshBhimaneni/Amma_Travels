import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../services/api_service.dart';
import '../widgets/bus_photo_gallery.dart';
import 'bus_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String source;
  final String destination;
  final String journeyDate;

  const SearchResultsScreen({
    super.key,
    required this.source,
    required this.destination,
    required this.journeyDate,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _HomeScreenFilter {
  bool ac = false;
  bool nonAc = false;
  bool sleeper = false;
  bool seater = false;
  String sortBy = 'default'; // 'default', 'fare_asc', 'fare_desc', 'time_asc'

  bool get isActive => ac || nonAc || sleeper || seater || sortBy != 'default';

  void clear() {
    ac = false;
    nonAc = false;
    sleeper = false;
    seater = false;
    sortBy = 'default';
  }
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Bus> _allBuses = [];
  bool _isLoading = true;
  final _HomeScreenFilter _filter = _HomeScreenFilter();

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() {
      _isLoading = true;
    });
    final results = await ApiService.searchBuses(
      widget.source,
      widget.destination,
      widget.journeyDate,
    );
    setState(() {
      _allBuses = results.map((b) => Bus.fromJson(b)).toList();
      _isLoading = false;
    });
  }

  List<Bus> get _filteredBuses {
    List<Bus> list = _allBuses.where((bus) {
      // 1. Bus Type filters (AC / Non-AC)
      if (_filter.ac && _filter.nonAc) {
        // Both selected: show both
      } else if (_filter.ac && !bus.isAc) {
        return false;
      } else if (_filter.nonAc && !bus.isNonAc) {
        return false;
      }

      // 2. Seating arrangement filters (Sleeper / Seater)
      if (_filter.sleeper && _filter.seater) {
        // Both selected: show both
      } else if (_filter.sleeper && !bus.isSleeper) {
        return false;
      } else if (_filter.seater && !bus.isSeater) {
        return false;
      }

      return true;
    }).toList();

    // 3. Sorting
    if (_filter.sortBy == 'fare_asc') {
      list.sort((a, b) => a.fare.compareTo(b.fare));
    } else if (_filter.sortBy == 'fare_desc') {
      list.sort((a, b) => b.fare.compareTo(a.fare));
    } else if (_filter.sortBy == 'time_asc') {
      list.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }

    return list;
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters & Sorting',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _filter.clear();
                            });
                            setState(() {});
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      'SORT BY',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Default'),
                          selected: _filter.sortBy == 'default',
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _filter.sortBy = 'default');
                              setState(() {});
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Price: Low to High'),
                          selected: _filter.sortBy == 'fare_asc',
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _filter.sortBy = 'fare_asc');
                              setState(() {});
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Price: High to Low'),
                          selected: _filter.sortBy == 'fare_desc',
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _filter.sortBy = 'fare_desc');
                              setState(() {});
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Departure Time'),
                          selected: _filter.sortBy == 'time_asc',
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _filter.sortBy = 'time_asc');
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'BUS TYPE',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('A/C Buses'),
                      value: _filter.ac,
                      activeColor: theme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setModalState(() {
                          _filter.ac = val ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Non-A/C Buses'),
                      value: _filter.nonAc,
                      activeColor: theme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setModalState(() {
                          _filter.nonAc = val ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SEAT TYPE',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Sleeper'),
                      value: _filter.sleeper,
                      activeColor: theme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setModalState(() {
                          _filter.sleeper = val ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Seater'),
                      value: _filter.seater,
                      activeColor: theme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? val) {
                        setModalState(() {
                          _filter.seater = val ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: Icon(
                Icons.tune,
                size: 16,
                color: _filter.isActive ? Colors.white : Colors.black87,
              ),
              label: Text(
                'Filters${_filter.isActive ? " (Active)" : ""}',
                style: TextStyle(
                  color: _filter.isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _filter.isActive ? theme.primaryColor : Colors.grey.shade100,
              onPressed: _openFilterBottomSheet,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('A/C', style: TextStyle(fontSize: 12)),
              selected: _filter.ac,
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              onSelected: (val) {
                setState(() {
                  _filter.ac = val;
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Non-A/C', style: TextStyle(fontSize: 12)),
              selected: _filter.nonAc,
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              onSelected: (val) {
                setState(() {
                  _filter.nonAc = val;
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Sleeper', style: TextStyle(fontSize: 12)),
              selected: _filter.sleeper,
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              onSelected: (val) {
                setState(() {
                  _filter.sleeper = val;
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Seater', style: TextStyle(fontSize: 12)),
              selected: _filter.seater,
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              onSelected: (val) {
                setState(() {
                  _filter.seater = val;
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('₹ Low to High', style: TextStyle(fontSize: 12)),
              selected: _filter.sortBy == 'fare_asc',
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              onSelected: (val) {
                setState(() {
                  _filter.sortBy = val ? 'fare_asc' : 'default';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buses = _filteredBuses;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.source} → ${widget.destination}'),
            Text(
              widget.journeyDate,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_alt),
                if (_filter.isActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Buses',
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E1A1A)))
          : Column(
              children: [
                _buildQuickFilterBar(theme),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${buses.length} ${buses.length == 1 ? "Bus" : "Buses"} Available',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                      ),
                      if (_filter.isActive)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Reset', style: TextStyle(color: Color(0xFF9E1A1A), fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: buses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Buses Found',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _filter.isActive
                                      ? 'No buses match your selected filters. Try clearing or adjusting filters.'
                                      : 'Try changing the route or adjusting your search parameters.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (_filter.isActive) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _filter.clear();
                                      });
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: buses.length,
                          itemBuilder: (context, index) {
                            final bus = buses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusDetailsScreen(bus: bus),
                            ),
                          ).then((_) => _fetchBuses()); // Refresh on return in case seats booked
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Realistic Bus Photo Banner (RedBus/AbhiBus style)
                            BusImageBanner(
                              bus: bus,
                              height: 125,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bus.busName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => showBusPhotoGallery(context, bus),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            border: Border.all(color: Colors.amber.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.photo_camera_outlined, size: 14, color: Colors.amber.shade800),
                                              const SizedBox(width: 4),
                                              Text(
                                                'View Photos',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        bus.busNumber,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        bus.busType,
                                        style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DEPARTURE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        bus.departureTime.substring(0, 5),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('ARRIVAL', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        bus.arrivalTime.substring(0, 5),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('FARE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        '₹${bus.fare.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.event_seat_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${bus.totalSeats} Total Seats',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
