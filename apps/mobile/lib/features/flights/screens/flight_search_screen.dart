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
  String _tripType = 'return';
  Airport? _origin;
  Airport? _destination;
  late DateTimeRange _departRange;
  DateTimeRange? _returnRange;
  int _adults = 1;
  int _children = 0;
  String _cabin = 'Economy';
  bool _swapping = false;

  late final AnimationController _swapCtrl;
  late final Animation<double> _swapAnim;

  @override
  void initState() {
    super.initState();
    final base = DateTime.now().add(const Duration(days: 14));
    _departRange = DateTimeRange(start: base, end: base.add(const Duration(days: 2)));
    _returnRange = DateTimeRange(
      start: base.add(const Duration(days: 7)),
      end: base.add(const Duration(days: 9)),
    );
    _swapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _swapAnim = CurvedAnimation(parent: _swapCtrl, curve: Curves.easeInOut);
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
      setState(() => isOrigin ? _origin = airport : _destination = airport);
    }
  }

  Future<void> _pickDateRange(bool isDeparture) async {
    final now = DateTime.now();
    final initial = isDeparture ? _departRange : (_returnRange ?? _departRange);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: isDeparture ? 'DEPARTURE WINDOW' : 'RETURN WINDOW',
      saveText: 'DONE',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departRange = picked;
          if (_returnRange != null && _returnRange!.start.isBefore(picked.end)) {
            _returnRange = DateTimeRange(
              start: picked.end.add(const Duration(days: 1)),
              end: picked.end.add(const Duration(days: 3)),
            );
          }
        } else {
          _returnRange = picked;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select origin and destination'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final fmt = DateFormat('yyyy-MM-dd');
    context.push('/flights/results', extra: {
      'origin': _origin!.code,
      'originCity': _origin!.city,
      'destination': _destination!.code,
      'destinationCity': _destination!.city,
      'departure_date_from': fmt.format(_departRange.start),
      'departure_date_to': fmt.format(_departRange.end),
      'return_date_from': _tripType == 'return' && _returnRange != null
          ? fmt.format(_returnRange!.start)
          : null,
      'return_date_to': _tripType == 'return' && _returnRange != null
          ? fmt.format(_returnRange!.end)
          : null,
      'adults': _adults,
      'children': _children,
      'cabin': _cabinCode(_cabin),
    });
  }

  String _cabinCode(String label) => switch (label) {
        'Business' => 'BUSINESS',
        'First' => 'FIRST',
        'Premium Economy' => 'PREMIUM_ECONOMY',
        _ => 'ECONOMY',
      };

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCard()),
          SliverToBoxAdapter(child: _buildPopular()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(greeting,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const Spacer(),
                  _IconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Where to? ✈️',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              const SizedBox(height: 4),
              const Text('Search across flexible date windows',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTripToggle(),
              const SizedBox(height: 12),
              _buildAirports(),
              const SizedBox(height: 10),
              _buildDates(),
              const SizedBox(height: 10),
              _buildPaxRow(),
              const SizedBox(height: 14),
              _buildSearchBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripToggle() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Return',
            active: _tripType == 'return',
            onTap: () => setState(() {
              _tripType = 'return';
              _returnRange ??= DateTimeRange(
                start: _departRange.end.add(const Duration(days: 1)),
                end: _departRange.end.add(const Duration(days: 3)),
              );
            }),
          ),
          _ToggleBtn(
            label: 'One-way',
            active: _tripType == 'oneway',
            onTap: () => setState(() => _tripType = 'oneway'),
          ),
        ],
      ),
    );
  }

  Widget _buildAirports() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _AirportTile(
            icon: Icons.flight_takeoff_rounded,
            label: 'FROM',
            value: _origin?.displayName,
            code: _origin?.code,
            onTap: () => _pickAirport(true),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Stack(
            children: [
              _AirportTile(
                icon: Icons.flight_land_rounded,
                label: 'TO',
                value: _destination?.displayName,
                code: _destination?.code,
                onTap: () => _pickAirport(false),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _swap,
                    child: RotationTransition(
                      turns: _swapAnim,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.brand, Color(0xFF818CF8)]),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded,
                            color: Colors.white, size: 18),
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

  Widget _buildDates() {
    return Row(
      children: [
        Expanded(
          child: _DateRangeTile(
            label: 'DEPART',
            range: _departRange,
            onTap: () => _pickDateRange(true),
          ),
        ),
        if (_tripType == 'return') ...[
          const SizedBox(width: 8),
          Expanded(
            child: _DateRangeTile(
              label: 'RETURN',
              range: _returnRange,
              onTap: () => _pickDateRange(false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaxRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showPax,
            child: _InfoTile(
              icon: Icons.people_outline_rounded,
              label: 'PAX',
              value: '${_adults + _children} ${(_adults + _children) == 1 ? "Adult" : "Passengers"}',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _showCabin,
            child: _InfoTile(
              icon: Icons.airline_seat_recline_extra_rounded,
              label: 'CLASS',
              value: _cabin,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBtn() {
    return GestureDetector(
      onTap: _search,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandDark, AppColors.brand, Color(0xFF818CF8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Search Flights',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopular() {
    final routes = [
      ('TLV', 'LHR', 'London', '🇬🇧'),
      ('TLV', 'DXB', 'Dubai', '🇦🇪'),
      ('TLV', 'JFK', 'New York', '🇺🇸'),
      ('TLV', 'BKK', 'Bangkok', '🇹🇭'),
      ('TLV', 'FCO', 'Rome', '🇮🇹'),
      ('TLV', 'CDG', 'Paris', '🇫🇷'),
    ];

    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Popular Routes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemCount: routes.length,
              itemBuilder: (_, i) {
                final (from, to, city, flag) = routes[i];
                return GestureDetector(
                  onTap: () => setState(() {
                    _origin = Airport(code: from, name: '', city: 'Tel Aviv', country: 'Israel');
                    _destination = Airport(code: to, name: '', city: city, country: '');
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(city,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('$from → $to',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textMuted)),
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

  void _showPax() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaxSheet(
        adults: _adults,
        children: _children,
        onChanged: (a, c) => setState(() { _adults = a; _children = c; }),
      ),
    );
  }

  void _showCabin() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CabinSheet(
        selected: _cabin,
        onSelected: (c) => setState(() => _cabin = c),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active
                  ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.brand : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
}

class _AirportTile extends StatelessWidget {
  const _AirportTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.code,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final String? code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(
                      value ?? (label == 'FROM' ? 'Departure city' : 'Destination city'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (code != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(code!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ),
            ],
          ),
        ),
      );
}

class _DateRangeTile extends StatelessWidget {
  const _DateRangeTile({required this.label, required this.range, required this.onTap});
  final String label;
  final DateTimeRange? range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final start = range != null ? fmt.format(range!.start) : '--';
    final end = range != null ? fmt.format(range!.end) : '--';
    final sameDay = range != null &&
        range!.start.year == range!.end.year &&
        range!.start.month == range!.end.month &&
        range!.start.day == range!.end.day;
    final display = sameDay ? start : '$start – $end';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 12, color: AppColors.brand),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(display,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(icon, size: 12, color: AppColors.brand),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Sheets ───────────────────────────────────────────────

class _PaxSheet extends StatefulWidget {
  const _PaxSheet({required this.adults, required this.children, required this.onChanged});
  final int adults, children;
  final void Function(int, int) onChanged;

  @override
  State<_PaxSheet> createState() => _PaxSheetState();
}

class _PaxSheetState extends State<_PaxSheet> {
  late int _a, _c;

  @override
  void initState() {
    super.initState();
    _a = widget.adults;
    _c = widget.children;
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Passengers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _PaxRow(label: 'Adults', sub: '12+', count: _a,
                onMinus: () { if (_a > 1) setState(() => _a--); },
                onPlus: () { if (_a < 9) setState(() => _a++); }),
            const SizedBox(height: 12),
            _PaxRow(label: 'Children', sub: '2–11', count: _c,
                onMinus: () { if (_c > 0) setState(() => _c--); },
                onPlus: () { if (_c < 8) setState(() => _c++); }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { widget.onChanged(_a, _c); Navigator.pop(context); },
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      );
}

class _PaxRow extends StatelessWidget {
  const _PaxRow({required this.label, required this.sub, required this.count,
      required this.onMinus, required this.onPlus});
  final String label, sub;
  final int count;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
          const Spacer(),
          _Btn(icon: Icons.remove, onTap: onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          _Btn(icon: Icons.add, onTap: onPlus, filled: true),
        ],
      );
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: filled ? AppColors.brand : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: filled ? AppColors.brand : AppColors.border),
          ),
          child: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.textPrimary),
        ),
      );
}

class _CabinSheet extends StatelessWidget {
  const _CabinSheet({required this.selected, required this.onSelected});
  final String selected;
  final void Function(String) onSelected;

  static const _opts = [
    ('Economy', Icons.airline_seat_recline_normal_rounded, 'Standard'),
    ('Premium Economy', Icons.airline_seat_recline_extra_rounded, 'Extra legroom'),
    ('Business', Icons.business_center_rounded, 'Lie-flat seats'),
    ('First', Icons.star_rounded, 'Ultimate luxury'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Cabin Class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ..._opts.map((opt) {
              final (label, icon, sub) = opt;
              final sel = label == selected;
              return GestureDetector(
                onTap: () { onSelected(label); Navigator.pop(context); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.brandLight : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.brand : AppColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: sel ? AppColors.brand : AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: sel ? AppColors.brand : AppColors.textPrimary,
                        )),
                        Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ])),
                      if (sel) const Icon(Icons.check_circle_rounded, color: AppColors.brand, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
}
