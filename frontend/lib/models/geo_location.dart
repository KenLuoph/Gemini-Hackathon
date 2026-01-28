/// Geographic location model
/// Mirrors backend GeoLocation from domain.py
class GeoLocation {
  final double lat;
  final double lng;
  final String address;

  const GeoLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  /// Create from JSON
  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  /// Google Maps URL
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  /// Short address (first line only)
  String get shortAddress {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts[0].trim() : address;
  }

  @override
  String toString() => 'GeoLocation(lat: $lat, lng: $lng, address: $address)';
}