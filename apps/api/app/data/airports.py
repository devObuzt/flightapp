"""
Major airports dataset with IATA codes, city names, and country names.
Supports search by code, city, airport name, or country.
"""

AIRPORTS = [
    # ─── Middle East ───────────────────────────────────────────
    {"code": "TLV", "name": "Ben Gurion International", "city": "Tel Aviv", "country": "Israel"},
    {"code": "DXB", "name": "Dubai International", "city": "Dubai", "country": "UAE"},
    {"code": "AUH", "name": "Abu Dhabi International", "city": "Abu Dhabi", "country": "UAE"},
    {"code": "DOH", "name": "Hamad International", "city": "Doha", "country": "Qatar"},
    {"code": "AMM", "name": "Queen Alia International", "city": "Amman", "country": "Jordan"},
    {"code": "BEY", "name": "Rafic Hariri International", "city": "Beirut", "country": "Lebanon"},
    {"code": "CAI", "name": "Cairo International", "city": "Cairo", "country": "Egypt"},
    {"code": "RUH", "name": "King Khalid International", "city": "Riyadh", "country": "Saudi Arabia"},
    {"code": "JED", "name": "King Abdulaziz International", "city": "Jeddah", "country": "Saudi Arabia"},
    {"code": "KWI", "name": "Kuwait International", "city": "Kuwait City", "country": "Kuwait"},
    {"code": "BAH", "name": "Bahrain International", "city": "Manama", "country": "Bahrain"},
    {"code": "MCT", "name": "Muscat International", "city": "Muscat", "country": "Oman"},
    {"code": "BGW", "name": "Baghdad International", "city": "Baghdad", "country": "Iraq"},
    {"code": "IKA", "name": "Imam Khomeini International", "city": "Tehran", "country": "Iran"},
    {"code": "IST", "name": "Istanbul Airport", "city": "Istanbul", "country": "Turkey"},
    {"code": "SAW", "name": "Sabiha Gokcen International", "city": "Istanbul", "country": "Turkey"},
    {"code": "ESB", "name": "Esenboga International", "city": "Ankara", "country": "Turkey"},

    # ─── Europe ────────────────────────────────────────────────
    {"code": "LON", "name": "London All Airports", "city": "London", "country": "United Kingdom"},
    {"code": "LHR", "name": "Heathrow Airport", "city": "London", "country": "United Kingdom"},
    {"code": "LGW", "name": "Gatwick Airport", "city": "London", "country": "United Kingdom"},
    {"code": "STN", "name": "Stansted Airport", "city": "London", "country": "United Kingdom"},
    {"code": "LTN", "name": "Luton Airport", "city": "London", "country": "United Kingdom"},
    {"code": "CDG", "name": "Charles de Gaulle Airport", "city": "Paris", "country": "France"},
    {"code": "ORY", "name": "Orly Airport", "city": "Paris", "country": "France"},
    {"code": "FRA", "name": "Frankfurt Airport", "city": "Frankfurt", "country": "Germany"},
    {"code": "MUC", "name": "Munich Airport", "city": "Munich", "country": "Germany"},
    {"code": "BER", "name": "Brandenburg Airport", "city": "Berlin", "country": "Germany"},
    {"code": "AMS", "name": "Amsterdam Schiphol", "city": "Amsterdam", "country": "Netherlands"},
    {"code": "MAD", "name": "Adolfo Suarez Madrid-Barajas", "city": "Madrid", "country": "Spain"},
    {"code": "BCN", "name": "Barcelona El Prat", "city": "Barcelona", "country": "Spain"},
    {"code": "FCO", "name": "Rome Fiumicino", "city": "Rome", "country": "Italy"},
    {"code": "MXP", "name": "Milan Malpensa", "city": "Milan", "country": "Italy"},
    {"code": "ZRH", "name": "Zurich Airport", "city": "Zurich", "country": "Switzerland"},
    {"code": "VIE", "name": "Vienna International", "city": "Vienna", "country": "Austria"},
    {"code": "BRU", "name": "Brussels Airport", "city": "Brussels", "country": "Belgium"},
    {"code": "CPH", "name": "Copenhagen Airport", "city": "Copenhagen", "country": "Denmark"},
    {"code": "OSL", "name": "Oslo Gardermoen", "city": "Oslo", "country": "Norway"},
    {"code": "ARN", "name": "Stockholm Arlanda", "city": "Stockholm", "country": "Sweden"},
    {"code": "HEL", "name": "Helsinki Vantaa", "city": "Helsinki", "country": "Finland"},
    {"code": "ATH", "name": "Athens International", "city": "Athens", "country": "Greece"},
    {"code": "WAW", "name": "Warsaw Chopin Airport", "city": "Warsaw", "country": "Poland"},
    {"code": "PRG", "name": "Václav Havel Airport", "city": "Prague", "country": "Czech Republic"},
    {"code": "BUD", "name": "Budapest Ferenc Liszt", "city": "Budapest", "country": "Hungary"},
    {"code": "LIS", "name": "Humberto Delgado Airport", "city": "Lisbon", "country": "Portugal"},

    # ─── CIS / Eastern Europe ──────────────────────────────────
    {"code": "SVO", "name": "Sheremetyevo International", "city": "Moscow", "country": "Russia"},
    {"code": "DME", "name": "Domodedovo International", "city": "Moscow", "country": "Russia"},
    {"code": "LED", "name": "Pulkovo Airport", "city": "St. Petersburg", "country": "Russia"},
    {"code": "ALA", "name": "Almaty International", "city": "Almaty", "country": "Kazakhstan"},
    {"code": "NQZ", "name": "Nursultan Nazarbayev International", "city": "Astana", "country": "Kazakhstan"},
    {"code": "GYD", "name": "Heydar Aliyev International", "city": "Baku", "country": "Azerbaijan"},
    {"code": "TBS", "name": "Tbilisi International", "city": "Tbilisi", "country": "Georgia"},
    {"code": "EVN", "name": "Zvartnots International", "city": "Yerevan", "country": "Armenia"},
    {"code": "KIV", "name": "Chisinau International", "city": "Chisinau", "country": "Moldova"},
    {"code": "KBP", "name": "Boryspil International", "city": "Kyiv", "country": "Ukraine"},
    {"code": "TAS", "name": "Tashkent International", "city": "Tashkent", "country": "Uzbekistan"},

    # ─── Asia ──────────────────────────────────────────────────
    {"code": "BKK", "name": "Suvarnabhumi Airport", "city": "Bangkok", "country": "Thailand"},
    {"code": "SIN", "name": "Singapore Changi", "city": "Singapore", "country": "Singapore"},
    {"code": "HKG", "name": "Hong Kong International", "city": "Hong Kong", "country": "Hong Kong"},
    {"code": "NRT", "name": "Tokyo Narita", "city": "Tokyo", "country": "Japan"},
    {"code": "HND", "name": "Tokyo Haneda", "city": "Tokyo", "country": "Japan"},
    {"code": "ICN", "name": "Incheon International", "city": "Seoul", "country": "South Korea"},
    {"code": "PEK", "name": "Beijing Capital International", "city": "Beijing", "country": "China"},
    {"code": "PVG", "name": "Shanghai Pudong International", "city": "Shanghai", "country": "China"},
    {"code": "DEL", "name": "Indira Gandhi International", "city": "New Delhi", "country": "India"},
    {"code": "BOM", "name": "Chhatrapati Shivaji International", "city": "Mumbai", "country": "India"},
    {"code": "KUL", "name": "Kuala Lumpur International", "city": "Kuala Lumpur", "country": "Malaysia"},
    {"code": "CGK", "name": "Soekarno-Hatta International", "city": "Jakarta", "country": "Indonesia"},

    # ─── Africa ────────────────────────────────────────────────
    {"code": "JNB", "name": "O.R. Tambo International", "city": "Johannesburg", "country": "South Africa"},
    {"code": "CPT", "name": "Cape Town International", "city": "Cape Town", "country": "South Africa"},
    {"code": "ADD", "name": "Addis Ababa Bole International", "city": "Addis Ababa", "country": "Ethiopia"},
    {"code": "NBO", "name": "Jomo Kenyatta International", "city": "Nairobi", "country": "Kenya"},
    {"code": "LOS", "name": "Murtala Muhammed International", "city": "Lagos", "country": "Nigeria"},
    {"code": "CMN", "name": "Mohammed V International", "city": "Casablanca", "country": "Morocco"},

    # ─── Americas ──────────────────────────────────────────────
    {"code": "JFK", "name": "John F. Kennedy International", "city": "New York", "country": "USA"},
    {"code": "EWR", "name": "Newark Liberty International", "city": "New York", "country": "USA"},
    {"code": "LAX", "name": "Los Angeles International", "city": "Los Angeles", "country": "USA"},
    {"code": "ORD", "name": "O'Hare International", "city": "Chicago", "country": "USA"},
    {"code": "MIA", "name": "Miami International", "city": "Miami", "country": "USA"},
    {"code": "SFO", "name": "San Francisco International", "city": "San Francisco", "country": "USA"},
    {"code": "BOS", "name": "Boston Logan International", "city": "Boston", "country": "USA"},
    {"code": "YYZ", "name": "Toronto Pearson International", "city": "Toronto", "country": "Canada"},
    {"code": "YUL", "name": "Montreal-Trudeau International", "city": "Montreal", "country": "Canada"},
    {"code": "GRU", "name": "São Paulo-Guarulhos International", "city": "São Paulo", "country": "Brazil"},
    {"code": "EZE", "name": "Ministro Pistarini International", "city": "Buenos Aires", "country": "Argentina"},

    # ─── Oceania ───────────────────────────────────────────────
    {"code": "SYD", "name": "Sydney Kingsford Smith", "city": "Sydney", "country": "Australia"},
    {"code": "MEL", "name": "Melbourne Airport", "city": "Melbourne", "country": "Australia"},
    {"code": "AKL", "name": "Auckland Airport", "city": "Auckland", "country": "New Zealand"},
]


def search_airports(query: str, limit: int = 8) -> list[dict]:
    """Search airports by code, name, city, or country (case-insensitive)."""
    if not query or len(query) < 2:
        return []

    q = query.strip().upper()
    results = []

    for airport in AIRPORTS:
        code = airport["code"].upper()
        name = airport["name"].upper()
        city = airport["city"].upper()
        country = airport["country"].upper()

        # Exact code match — highest priority
        if code == q:
            results.insert(0, airport)
        elif (
            code.startswith(q)
            or city.startswith(q)
            or q in city
            or q in name
            or q in country
        ):
            results.append(airport)

    # Deduplicate and limit
    seen = set()
    unique = []
    for a in results:
        if a["code"] not in seen:
            seen.add(a["code"])
            unique.append(a)

    return unique[:limit]
