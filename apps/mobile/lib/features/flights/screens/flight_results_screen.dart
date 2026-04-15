import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../models/flight_offer.dart';
import '../services/flights_service.dart';
import '../widgets/flight_card.dart';

class FlightResultsScreen extends ConsumerStatefulWidget {
  const FlightResultsScreen({super.key, required this.params});
  final Map<String, dynamic> params;

  @override
  ConsumerState<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends ConsumerState<FlightResultsScreen> {
  late Future<List<FlightOffer>> _future;
  String _sortBy = 'price';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final p = widget.params;
    final service = ref.read(flightsServiceProvider);

    final departFrom = p['departure_date_from'] as String?;
    final departTo = p['departure_date_to'] as String?;
    final returnFrom = p['return_date_from'] as String?;
    final returnTo = p['return_date_to'] as String?;

    if (departFrom != null && departTo != null) {
      _future = service.searchFlightsRange(
        origin: p['origin'] as String,
        destination: p['destination'] as String,
        departFrom: DateTime.parse(departFrom),
        departTo: DateTime.parse(departTo),
        returnFrom: returnFrom != null ? DateTime.parse(returnFrom) : null,
        returnTo: returnTo != null ? DateTime.parse(returnTo) : null,
        adults: (p['adults'] as int? ?? 1),
        children: (p['children'] as int? ?? 0),
        cabin: p['cabin'] as String? ?? 'ECONOMY',
      );
    } else {
      _future = service.searchFlights(
        origin: p['origin'] as String,
        destination: p['destination'] as String,
        departureDate: p['departure_date'] as String,
        returnDate: p['return_date'] as String?,
        adults: (p['adults'] as int? ?? 1),
        children: (p['children'] as int? ?? 0),
        cabin: p['cabin'] as String? ?? 'ECONOMY',
      );
    }
  }

  List<FlightOffer> _sort(List<FlightOffer> offers) {
    final copy = [...offers];
    if (_sortBy == 'price') {
      copy.sort((a, b) => a.priceTotal.compareTo(b.priceTotal));
    } else {
      copy.sort((a, b) {
        final aD = a.firstSegment?.durationMinutes ?? 999;
        final bD = b.firstSegment?.durationMinutes ?? 999;
        return aD.compareTo(bD);
      });
    }
    return copy;
  }

  String _buildDateLabel() {
    final p = widget.params;
    final df = p['departure_date_from'] as String?;
    final dt = p['departure_date_to'] as String?;
    final rf = p['return_date_from'] as String?;
    final rt = p['return_date_to'] as String?;

    String label = df ?? (p['departure_date'] as String? ?? '');
    if (dt != null && dt != df) label += ' – $dt';
    if (rf != null) {
      label += '  ·  ↩ $rf';
      if (rt != null && rt != rf) label += ' – $rt';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final p = widget.params;
    final origin = p['origin'] as String? ?? '';
    final dest = p['destination'] as String? ?? '';
    final originCity = p['originCity'] as String? ?? origin;
    final destCity = p['destinationCity'] as String? ?? dest;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(context, originCity, destCity, origin, dest),
          _buildSortBar(),
          Expanded(
            child: FutureBuilder<List<FlightOffer>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snap.hasError) return _buildError(snap.error.toString());
                final offers = _sort(snap.data ?? []);
                if (offers.isEmpty) return _buildEmpty();
                return _buildList(offers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, String originCity, String destCity,
      String origin, String dest) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          child: Row(
            children: [
              // Back button — iOS swipe or tap
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(originCity,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.flight, color: Colors.white38, size: 14),
                        ),
                        Text(destCity,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildDateLabel(),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Edit search
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Text('Sort:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          _Chip(label: 'Cheapest', active: _sortBy == 'price',
              onTap: () => setState(() => _sortBy = 'price')),
          const SizedBox(width: 6),
          _Chip(label: 'Fastest', active: _sortBy == 'duration',
              onTap: () => setState(() => _sortBy = 'duration')),
        ],
      ),
    );
  }

  Widget _buildList(List<FlightOffer> offers) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        itemCount: offers.length,
        itemBuilder: (_, i) => FlightCard(
          offer: offers[i],
          onTap: () => _showSheet(offers[i]),
        ),
      );

  Widget _buildLoading() => Shimmer.fromColors(
        baseColor: const Color(0xFFE8E8F0),
        highlightColor: const Color(0xFFF8F8FF),
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.flight_outlined, size: 36, color: AppColors.brand),
              ),
              const SizedBox(height: 16),
              const Text('No flights found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Try different dates or airports',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Modify Search',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 34, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text('Something went wrong',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(msg,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _load()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );

  void _showSheet(FlightOffer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookSheet(offer: offer),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.brand : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              )),
        ),
      );
}

class _BookSheet extends StatelessWidget {
  const _BookSheet({required this.offer});
  final FlightOffer offer;

  @override
  Widget build(BuildContext context) {
    final seg = offer.firstSegment;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Flight Details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(offer.priceFormatted,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 16),
          if (seg != null) ...[
            _Row('From', '${seg.origin}  ${seg.departureTime}'),
            _Row('To', '${seg.destination}  ${seg.arrivalTime}'),
            _Row('Duration', seg.durationFormatted),
            _Row('Cabin', seg.cabin),
            _Row('Stops', offer.stopsLabel),
            if (offer.refundable) _Row('Refund', '✓ Refundable'),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Booking coming soon!'),
                  backgroundColor: AppColors.brand,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
