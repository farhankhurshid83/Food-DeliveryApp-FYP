class Product {
  final String id;
  final String name;
  final String imageBase64; // Store image as base64 string
  final double price;
  final String category;
  final String subCategory;

  Product({
    required this.id,
    required this.name,
    required this.imageBase64,
    required this.price,
    required this.category,
    required this.subCategory,
  });

  // Convert Product to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'imageBase64': imageBase64,
      'price': price,
      'category': category,
      'subCategory': subCategory,
    };
  }

  // Create a Product from a Firestore document
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
    );
  }
}
