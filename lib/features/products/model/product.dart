import 'package:flutterapp/features/products/model/product_review.dart';

/// One DummyJSON product. The list endpoint returns the same shape as the
/// detail endpoint, so the detail page can paint instantly from the list item
/// while the full record loads.
class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String? brand;
  final String thumbnail;
  final List<String> images;
  final List<String> tags;
  final String availabilityStatus;
  final String warrantyInformation;
  final String shippingInformation;
  final String returnPolicy;
  final List<ProductReview> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.tags,
    required this.availabilityStatus,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.returnPolicy,
    required this.reviews,
  });

  /// Price before the discount — DummyJSON's `price` is the selling price.
  double get originalPrice =>
      discountPercentage <= 0 ? price : price / (1 - discountPercentage / 100);

  bool get hasDiscount => discountPercentage >= 1;

  /// Every image to show in the gallery, falling back to the thumbnail.
  List<String> get gallery => images.isNotEmpty ? images : [thumbnail];

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num).toInt(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    category: (json['category'] ?? '').toString(),
    price: _toDouble(json['price']),
    discountPercentage: _toDouble(json['discountPercentage']),
    rating: _toDouble(json['rating']),
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    brand: json['brand'] as String?,
    thumbnail: (json['thumbnail'] ?? '').toString(),
    images: _toStrings(json['images']),
    tags: _toStrings(json['tags']),
    availabilityStatus: (json['availabilityStatus'] ?? '').toString(),
    warrantyInformation: (json['warrantyInformation'] ?? '').toString(),
    shippingInformation: (json['shippingInformation'] ?? '').toString(),
    returnPolicy: (json['returnPolicy'] ?? '').toString(),
    reviews: (json['reviews'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductReview.fromJson)
        .toList(),
  );

  static double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0;

  static List<String> _toStrings(Object? v) =>
      (v as List? ?? const []).map((e) => e.toString()).toList();
}
