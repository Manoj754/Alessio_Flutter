class ProductReview {
  final int rating;
  final String comment;
  final DateTime? date;
  final String reviewerName;

  const ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: (json['comment'] ?? '').toString(),
    date: DateTime.tryParse((json['date'] ?? '').toString()),
    reviewerName: (json['reviewerName'] ?? '').toString(),
  );
}
