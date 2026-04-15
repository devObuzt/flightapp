class FlightSegment {
  const FlightSegment({
    required this.origin,
    required this.destination,
    required this.departureDatetime,
    required this.arrivalDatetime,
    required this.carrier,
    required this.flightNumber,
    required this.cabin,
    required this.durationMinutes,
    required this.stops,
  });

  final String origin;
  final String destination;
  final String departureDatetime;
  final String arrivalDatetime;
  final String carrier;
  final String flightNumber;
  final String cabin;
  final int durationMinutes;
  final int stops;

  factory FlightSegment.fromJson(Map<String, dynamic> j) => FlightSegment(
        origin: j['origin'] ?? '',
        destination: j['destination'] ?? '',
        departureDatetime: j['departure_datetime'] ?? '',
        arrivalDatetime: j['arrival_datetime'] ?? '',
        carrier: j['carrier'] ?? '',
        flightNumber: j['flight_number'] ?? '',
        cabin: j['cabin'] ?? 'ECONOMY',
        durationMinutes: (j['duration_minutes'] ?? 0) as int,
        stops: (j['stops'] ?? 0) as int,
      );

  String get durationFormatted {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h}h ${m}m';
  }

  String get departureTime {
    if (departureDatetime.length >= 16) return departureDatetime.substring(11, 16);
    return departureDatetime;
  }

  String get arrivalTime {
    if (arrivalDatetime.length >= 16) return arrivalDatetime.substring(11, 16);
    return arrivalDatetime;
  }
}

class FlightOffer {
  const FlightOffer({
    required this.offerId,
    required this.priceTotal,
    required this.currency,
    required this.refundable,
    required this.segments,
  });

  final String offerId;
  final double priceTotal;
  final String currency;
  final bool refundable;
  final List<FlightSegment> segments;

  factory FlightOffer.fromJson(Map<String, dynamic> j) => FlightOffer(
        offerId: j['offer_id'] ?? '',
        priceTotal: (j['price_total'] ?? 0).toDouble(),
        currency: j['currency'] ?? 'USD',
        refundable: j['refundable'] ?? false,
        segments: (j['segments'] as List<dynamic>? ?? [])
            .map((s) => FlightSegment.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  FlightSegment? get firstSegment => segments.isNotEmpty ? segments.first : null;
  FlightSegment? get lastSegment => segments.isNotEmpty ? segments.last : null;

  int get totalStops => segments.fold(0, (sum, s) => sum + s.stops);

  String get stopsLabel {
    if (totalStops == 0) return 'Direct';
    if (totalStops == 1) return '1 stop';
    return '$totalStops stops';
  }

  String get priceFormatted => '$currency ${priceTotal.toStringAsFixed(0)}';
}
