/// An address resolved from a map position (reverse geocoding). Not stored in
/// Appwrite — the address screens copy its parts into an `AddressModel`.
class GeocodedAddressModel {
  /// Street line, e.g. "12 Road 5, Dhanmondi". Empty when the point has none.
  final String street;
  final String city;
  final String postalCode;

  /// Building / place name at the point, when it has one.
  final String placeName;

  const GeocodedAddressModel({
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.placeName = '',
  });

  bool get isEmpty =>
      street.isEmpty && city.isEmpty && postalCode.isEmpty && placeName.isEmpty;

  /// The street line, falling back to the place name.
  String get addressLine => street.isNotEmpty ? street : placeName;

  /// One-line summary for display, e.g. "12 Road 5, Dhanmondi, Dhaka, 1205".
  String get formatted => [addressLine, city, postalCode]
      .where((part) => part.isNotEmpty)
      .join(', ');
}
