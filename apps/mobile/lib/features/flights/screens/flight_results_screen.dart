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
  String _sortBy = 'price'; // price | duration

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final p = widget.params;
    _future = ref.read(flightsServiceProvider).searchFlights(
      origin: p['origin'] as String,
      destination: p['destination'] as String,
      departureDate: p['departure_date'] as String,
      returnDate: p['return_date'] as String?,
      adults: (p['adults'] as int? ?? 1),
      children: (p['children'] as int? ?? 0),
      cabin: p['cabin'] as String? ?? 'ECONOMY',
    );
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final p = widget.params;
    final origin = p['origin'] as String? ?? '';
    final dest = p['destination'] as String? ?? '';
    final originCity = p['originCity'] as String? ?? origin;
    final destCity = p['destinationCity'] as String? ?? dest;
    final date = p['departure_date'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(context, originCity, destCity, origin, dest, date),
          _buildSortBar(),
          Expanded(
            child: FutureBuilder<List<FlightOffer>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snap.hasError) {
                  return _buildError(snap.error.toString());
                }
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
      String origin, String dest, String date) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              originCity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.flight, color: Colors.white60, size: 16),
                            ),
                            Text(
                              destCity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$origin → $dest · $date',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(width: 10),
          _SortChip(
            label: 'Cheapest',
            selected: _sortBy == 'price',
            onTap: () => setState(() => _sortBy = 'price'),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Fastest',
            selected: _sortBy == 'duration',
            onTap: () => setState(() => _sortBy = 'duration'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FlightOffer> offers) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: offers.length,
      itemBuilder: (_, i) => FlightCard(
        offer: offers[i],
        onTap: () => _showBookingSheet(offers[i]),
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.flight_outlined, size: 44, color: AppColors.brand),
          ),
          const SizedBox(height: 20),
          const Text(
            'No flights found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different dates or airports',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.gradientCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Modify Search',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _load()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Try Again',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(FlightOffer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingPreviewSheet(offer: offer),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.brand : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BookingPreviewSheet extends StatelessWidget {
  const _BookingPreviewSheet({required this.offer});
  final FlightOffer offer;

  @override
  Widget build(BuildContext context) {
    final seg = offer.firstSegment;
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
          Row(
            children: [
              const Text('Flight Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                offer.priceFormatted,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brand),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (seg != null) ...[
            _DetailRow('From', '${seg.origin} at ${seg.departureTime}'),
            _DetailRow('To', '${seg.destination} at ${seg.arrivalTime}'),
            _DetailRow('Duration', seg.durationFormatted),
            _DetailRow('Cabin', seg.cabin),
            _DetailRow('Stops', offer.stopsLabel),
            if (offer.refundable) _DetailRow('Refund', 'Refundable'),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Booking flow coming soon!'),
                    backgroundColor: AppColors.brand,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Book Now'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
