import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _sourceFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  List<String> _cities = ApiService.defaultCities;
  DateTime _journeyDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await ApiService.getCities();
    if (mounted && cities.isNotEmpty) {
      setState(() {
        _cities = cities;
      });
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _sourceFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9E1A1A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _journeyDate) {
      setState(() {
        _journeyDate = picked;
      });
    }
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;

    final source = _sourceController.text.trim();
    final destination = _destinationController.text.trim();
    final dateStr = DateFormat('yyyy-MM-dd').format(_journeyDate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          source: source,
          destination: destination,
          journeyDate: dateStr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amma Travels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Booking History',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner/Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    const Color(0xFF7A1212),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${authProvider.user?.name ?? "Guest"}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Where are you planning to travel today?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _buildAmmaAvatar(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Dedicated to Sri Mata Amritanandamayi Devi (Amma) • Amrita Vishwa Vidyapeetham',
                            style: TextStyle(
                              color: Color(0xFFFFF8E7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search Form Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_bus, color: theme.primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              'Book Your Ticket',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        // From Input with RedBus-like Autocomplete
                        _buildCityAutocomplete(
                          label: 'From Station (Boarding Point)',
                          hint: 'Enter city or station (e.g. Hyderabad)',
                          icon: Icons.location_on_outlined,
                          controller: _sourceController,
                          focusNode: _sourceFocusNode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter boarding point';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Swap button helper
                        Center(
                          child: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: IconButton(
                              icon: Icon(Icons.swap_vert, color: theme.primaryColor),
                              onPressed: () {
                                final temp = _sourceController.text;
                                _sourceController.text = _destinationController.text;
                                _destinationController.text = temp;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // To Input with RedBus-like Autocomplete
                        _buildCityAutocomplete(
                          label: 'To Station (Dropping Point)',
                          hint: 'Enter city or station (e.g. Vijayawada)',
                          icon: Icons.location_on,
                          controller: _destinationController,
                          focusNode: _destinationFocusNode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter dropping point';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Date selector
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: theme.primaryColor),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Journey Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMMM yyyy (EEEE)').format(_journeyDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Search Button
                        ElevatedButton(
                          onPressed: _search,
                          child: const Text('Search Buses'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _cities.where((city) => city.toLowerCase().contains(query)).take(8);
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: fieldController,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          fieldController.clear();
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
          validator: validator,
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 320),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.directions_bus, size: 16, color: theme.primaryColor),
                    ),
                    title: Text(
                      option,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'APSRTC Bus Station',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmmaAvatar() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text('Dedication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/amma.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(
                      'https://webfiles.amrita.edu/2019/11/zW3orNKx-Mata-Amritanandamayi.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dedicated with deep gratitude and reverence to Sri Mata Amritanandamayi Devi (Amma), renowned humanitarian and Chancellor of Amrita Vishwa Vidyapeetham.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Tooltip(
        message: 'Dedicated with reverence to Sri Mata Amritanandamayi Devi (Amma)',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/amma.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://webfiles.amrita.edu/2019/11/zW3orNKx-Mata-Amritanandamayi.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
