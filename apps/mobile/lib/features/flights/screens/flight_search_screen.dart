import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/airport.dart';
import '../widgets/airport_search_sheet.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen>
    with SingleTickerProviderStateMixin {
  String _tripType = 'return'; // return | oneway
  Airport? _origin;
  Airport? _destination;
  DateTime _departDate = DateTime.now().add(const Duration(days: 14));
  DateTime? _returnDate;
  int _adults = 1;
  int _children = 0;
  String _cabin = 'Economy';
  bool _swapping = false;

  late final AnimationController _swapCtrl;
  late final Animation<double> _swapAnim;

  @override
  void initState() {
    super.initState();
    _swapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swapAnim = CurvedAnimation(parent: _swapCtrl, curve: Curves.easeInOut);
    _returnDate = _departDate.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _swapCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAirport(bool isOrigin) async {
    final airport = await showAirportSearchSheet(
      context,
      title: isOrigin ? 'From where?' : 'Where to?',
    );
    if (airport != null) {
      setState(() {
        if (isOrigin) {
          _origin = airport;
        } else {
          _destination = airport;
        }
      });
    }
  }

  Future<void> _pickDate(bool isDeparture) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? _departDate : (_returnDate ?? _departDate),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 3));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _swap() async {
    if (_swapping) return;
    setState(() => _swapping = true);
    await _swapCtrl.forward();
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
    _swapCtrl.reset();
    setState(() => _swapping = false);
  }

  void _search() {
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select both airports'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final fmt = DateFormat('yyyy-MM-dd');
    context.push('/flights/results', extra: {
      'origin': _origin!.code,
      'originCity': _origin!.city,
      'destination': _destination!.code,
      'destinationCity': _destination!.city,
      'departure_date': fmt.format(_departDate),
      'return_date': _tripType == 'return' && _returnDate != null
          ? fmt.format(_returnDate!)
          : null,
      'adults': _adults,
      'children': _children,
      'cabin': _cabinCode(_cabin),
    });
  }

  String _cabinCode(String label) {
    return switch (label) {
      'Business' => 'BUSINESS',
      'First' => 'FIRST',
      'Premium Economy' => 'PREMIUM_ECONOMY',
      _ => 'ECONOMY',
    };
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchCard(),
            _buildPopularRoutes(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final emoji = hour < 12 ? '☀️' : hour < 17 ? '✈️' : '🌙';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$greeting $emoji',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Where would\nyou like to go?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find the best flights at the best prices',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTripTypePicker(),
                const SizedBox(height: 16),
                _buildAirportRow(),
                const SizedBox(height: 16),
                _buildDateRow(),
                const SizedBox(height: 16),
                _buildPaxCabinRow(),
                const SizedBox(height: 20),
                _buildSearchButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypePicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TripTypeTab(label: 'Return', selected: _tripType == 'return',
              onTap: () => setState(() { _tripType = 'return'; _returnDate ??= _departDate.add(const Duration(days: 7)); })),
          _TripTypeTab(label: 'One-way', selected: _tripType == 'oneway',
              onTap: () => setState(() { _tripType = 'oneway'; })),
        ],
      ),
    );
  }

  Widget _buildAirportRow() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _AirportField(
            label: 'FROM',
            airport: _origin,
            placeholder: 'Departure city',
            icon: Icons.flight_takeoff_rounded,
            onTap: () => _pickAirport(true),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Stack(
            children: [
              _AirportField(
                label: 'TO',
                airport: _destination,
                placeholder: 'Destination city',
                icon: Icons.flight_land_rounded,
                onTap: () => _pickAirport(false),
              ),
              Positioned(
                right: 16,
                top: 0, bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _swap,
                    child: RotationTransition(
                      turns: _swapAnim,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brand, Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _DateCard(
            label: 'DEPART',
            date: _departDate,
            onTap: () => _pickDate(true),
          ),
        ),
        if (_tripType == 'return') ...[
          const SizedBox(width: 10),
          Expanded(
            child: _DateCard(
              label: 'RETURN',
              date: _returnDate,
              onTap: () => _pickDate(false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaxCabinRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showPassengersSheet,
            child: _InfoCard(
              icon: Icons.people_outline_rounded,
              label: 'PASSENGERS',
              value: _adults + _children == 1
                  ? '1 Adult'
                  : '${_adults + _children} Passengers',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _showCabinSheet,
            child: _InfoCard(
              icon: Icons.airline_seat_recline_extra_rounded,
              label: 'CABIN',
              value: _cabin,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _search,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brand, Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Search Flights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutes() {
    final routes = [
      ('TLV', 'LHR', 'London', '🇬🇧'),
      ('TLV', 'DXB', 'Dubai', '🇦🇪'),
      ('TLV', 'JFK', 'New York', '🇺🇸'),
      ('TLV', 'BKK', 'Bangkok', '🇹🇭'),
      ('TLV', 'FCO', 'Rome', '🇮🇹'),
      ('TLV', 'CDG', 'Paris', '🇫🇷'),
    ];

    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popular Routes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: routes.length,
              itemBuilder: (_, i) {
                final (from, to, city, flag) = routes[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _origin = Airport(code: from, name: '', city: 'Tel Aviv', country: 'Israel');
                      _destination = Airport(code: to, name: '', city: city, country: '');
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                city,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$from → $to',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
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
          ],
        ),
      ),
    );
  }

  void _showPassengersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PassengersSheet(
        adults: _adults,
        children: _children,
        infants: 0,
        onChanged: (a, c, i) => setState(() { _adults = a; _children = c; }),
      ),
    );
  }

  void _showCabinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CabinSheet(
        selected: _cabin,
        onSelected: (c) => setState(() => _cabin = c),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────

class _TripTypeTab extends StatelessWidget {
  const _TripTypeTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.brand : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AirportField extends StatelessWidget {
  const _AirportField({
    required this.label,
    required this.airport,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Airport? airport;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    airport?.displayName ?? placeholder,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: airport != null ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (airport != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCard,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  airport!.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = date != null ? DateFormat('EEE').format(date!) : '--';
    final dateStr = date != null ? DateFormat('MMM d').format(date!) : 'Select';
    final year = date != null ? date!.year.toString() : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.brand),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$day $year',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.brand),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Passengers Sheet ─────────────────────────────────────

class _PassengersSheet extends StatefulWidget {
  const _PassengersSheet({
    required this.adults,
    required this.children,
    required this.infants,
    required this.onChanged,
  });
  final int adults, children, infants;
  final void Function(int adults, int children, int infants) onChanged;

  @override
  State<_PassengersSheet> createState() => _PassengersSheetState();
}

class _PassengersSheetState extends State<_PassengersSheet> {
  late int _adults, _children;

  @override
  void initState() {
    super.initState();
    _adults = widget.adults;
    _children = widget.children;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          _PaxRow(
            label: 'Adults', sub: '12+ years',
            count: _adults,
            onMinus: () { if (_adults > 1) setState(() => _adults--); },
            onPlus: () { if (_adults < 9) setState(() => _adults++); },
          ),
          const SizedBox(height: 16),
          _PaxRow(
            label: 'Children', sub: '2–11 years',
            count: _children,
            onMinus: () { if (_children > 0) setState(() => _children--); },
            onPlus: () { if (_children < 8) setState(() => _children++); },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(_adults, _children, 0);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PaxRow extends StatelessWidget {
  const _PaxRow({required this.label, required this.sub, required this.count,
      required this.onMinus, required this.onPlus});
  final String label, sub;
  final int count;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const Spacer(),
        _CounterBtn(icon: Icons.remove, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        _CounterBtn(icon: Icons.add, onTap: onPlus, filled: true),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  const _CounterBtn({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.brand : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: filled ? AppColors.brand : AppColors.border),
        ),
        child: Icon(icon, size: 18, color: filled ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}

// ─── Cabin Sheet ──────────────────────────────────────────

class _CabinSheet extends StatelessWidget {
  const _CabinSheet({required this.selected, required this.onSelected});
  final String selected;
  final void Function(String) onSelected;

  static const _options = [
    ('Economy', Icons.airline_seat_recline_normal_rounded, 'Standard seating'),
    ('Premium Economy', Icons.airline_seat_recline_extra_rounded, 'Extra legroom'),
    ('Business', Icons.business_center_rounded, 'Lie-flat seats'),
    ('First', Icons.star_rounded, 'Ultimate luxury'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Cabin Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._options.map((opt) {
            final (label, icon, sub) = opt;
            final isSelected = label == selected;
            return GestureDetector(
              onTap: () { onSelected(label); Navigator.pop(context); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandLight : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.brand : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isSelected ? AppColors.brand : AppColors.textSecondary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: isSelected ? AppColors.brand : AppColors.textPrimary,
                        )),
                        Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.brand, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
