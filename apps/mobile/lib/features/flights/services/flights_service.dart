import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/airport.dart';
import '../models/flight_offer.dart';

class FlightsService {
  FlightsService(this._dio);
  final Dio _dio;

  Future<List<Airport>> searchAirports(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _dio.get('/flights/airports', queryParameters: {'q': query});
    final list = res.data as List<dynamic>;
    return list.map((e) => Airport.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FlightOffer>> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults = 1,
    int children = 0,
    int infants = 0,
    String cabin = 'ECONOMY',
  }) async {
    final body = {
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate,
      'passengers': {
        'adults': adults,
        'children': children,
        'infants': infants,
      },
      'cabin': cabin,
    };
    if (returnDate != null) body['return_date'] = returnDate;

    final res = await _dio.post('/flights/search', data: body);
    final data = res.data as Map<String, dynamic>;
    final offers = data['offers'] as List<dynamic>? ?? [];
    return offers.map((e) => FlightOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Smart multi-date search: searches all departure dates in [departFrom..departTo]
  /// in parallel, and optionally all return dates in [returnFrom..returnTo].
  /// Results are aggregated and deduplicated by offer_id, then sorted by price.
  Future<List<FlightOffer>> searchFlightsRange({
    required String origin,
    required String destination,
    required DateTime departFrom,
    required DateTime departTo,
    DateTime? returnFrom,
    DateTime? returnTo,
    int adults = 1,
    int children = 0,
    int infants = 0,
    String cabin = 'ECONOMY',
  }) async {
    // Generate all departure dates in range
    final departDates = _datesInRange(departFrom, departTo);

    // For each departure date, determine the return date to use.
    // If a return range is given, use the mid-point or first date.
    // We search all departure dates in parallel with a fixed return date.
    // If return range is also multi-day, we also search across return dates.
    final List<Future<List<FlightOffer>>> futures = [];

    if (returnFrom != null && returnTo != null) {
      // Cross-product: each depart date × each return date
      // To keep API calls reasonable, cap each range to 5 dates
      final returnDates = _datesInRange(returnFrom, returnTo);
      for (final d in departDates) {
        for (final r in returnDates) {
          if (!r.isBefore(d)) {
            futures.add(_searchSingle(
              origin: origin,
              destination: destination,
              departureDate: _fmt(d),
              returnDate: _fmt(r),
              adults: adults,
              children: children,
              infants: infants,
              cabin: cabin,
            ));
          }
        }
      }
    } else {
      // One-way: just search each departure date
      for (final d in departDates) {
        futures.add(_searchSingle(
          origin: origin,
          destination: destination,
          departureDate: _fmt(d),
          returnDate: null,
          adults: adults,
          children: children,
          infants: infants,
          cabin: cabin,
        ));
      }
    }

    // Run all in parallel
    final results = await Future.wait(futures, eagerError: false);

    // Merge and deduplicate
    final seen = <String>{};
    final merged = <FlightOffer>[];
    for (final list in results) {
      for (final offer in list) {
        final key = '${offer.offerId}_${offer.firstSegment?.departureDatetime}';
        if (seen.add(key)) {
          merged.add(offer);
        }
      }
    }

    // Sort by price ascending
    merged.sort((a, b) => a.priceTotal.compareTo(b.priceTotal));
    return merged;
  }

  Future<List<FlightOffer>> _searchSingle({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    required int adults,
    required int children,
    required int infants,
    required String cabin,
  }) async {
    try {
      return await searchFlights(
        origin: origin,
        destination: destination,
        departureDate: departureDate,
        returnDate: returnDate,
        adults: adults,
        children: children,
        infants: infants,
        cabin: cabin,
      );
    } catch (_) {
      // If one date fails, return empty (don't break all results)
      return [];
    }
  }

  /// Returns all dates from [start] to [end] inclusive, capped at 5 to avoid
  /// too many parallel API calls.
  List<DateTime> _datesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last) && dates.length < 5) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final flightsServiceProvider = Provider<FlightsService>((ref) {
  return FlightsService(ref.read(dioProvider));
});
