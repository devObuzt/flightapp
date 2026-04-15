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
}

final flightsServiceProvider = Provider<FlightsService>((ref) {
  return FlightsService(ref.read(dioProvider));
});
