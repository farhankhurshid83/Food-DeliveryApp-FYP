import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  var products = <Product>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
// Bind products to a real-time Firestore stream
    bindStream(_firestore.collection('products').snapshots());
  }

// Bind the products list to a Firestore stream for real-time updates
  void bindStream(Stream<QuerySnapshot> stream) {
    products.bindStream(
      stream.map((QuerySnapshot query) {
        return query.docs.map((doc) {
          return Product.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }).handleError((error) {
        Get.snackbar('Error', 'Failed to load products: $error',
            snackPosition: SnackPosition.BOTTOM);
        return <Product>[]; // Return empty list on error
      }),
    );
  }

// Refresh the products by rebinding the Firestore stream
  Future<void> refreshProducts() async {
    try {
// Clear current products to show loading state
      products.clear();
// Rebind the stream to fetch fresh data
      bindStream(_firestore.collection('products').snapshots());
    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh products: $e',
          snackPosition: SnackPosition.BOTTOM);
      throw Exception('Failed to refresh products: $e');
    }
  }

  Future<String> _compressAndEncodeImage(File image) async {
// Compress the image
    final compressedImage = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: 300,
      minHeight: 300,
      quality: 70,
    );

    if (compressedImage == null) {
      throw Exception('Failed to compress image');
    }

// Encode to base64
    final imageBase64 = base64Encode(compressedImage);

// Check if the base64 string is too large for Firestore (1 MB limit)
    if (imageBase64.length > 1 * 1024 * 1024) {
      throw Exception(
          'Compressed image size exceeds Firestore document limit of 1 MB');
    }

    return imageBase64;
  }

  Future<void> addProduct(Product product, File image) async {
    try {
// Compress and encode the image
      final imageBase64 = await _compressAndEncodeImage(image);

// Create a new Product instance with the base64 image
      Product updatedProduct = Product(
        id: product.id,
        name: product.name,
        imageBase64: imageBase64,
        price: product.price,
        category: product.category,
        subCategory: product.subCategory,
      );

// Store the product in Firestore
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(updatedProduct.toFirestore());
// No need to manually add to products; the stream will handle it
      Get.snackbar('Success', 'Product added successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: $e',
          snackPosition: SnackPosition.BOTTOM);
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product, File? image) async {
    try {
      String imageBase64 = product.imageBase64;

// If a new image is provided, compress and encode it
      if (image != null) {
        imageBase64 = await _compressAndEncodeImage(image);
      }

// Create an updated Product instance
      Product updatedProduct = Product(
        id: product.id,
        name: product.name,
        imageBase64: imageBase64,
        price: product.price,
        category: product.category,
        subCategory: product.subCategory,
      );

// Update the product in Firestore
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(updatedProduct.toFirestore());
// No need to manually update products; the stream will handle it
      Get.snackbar('Success', 'Product updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product: $e',
          snackPosition: SnackPosition.BOTTOM);
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
// Delete the product from Firestore
      await _firestore.collection('products').doc(productId).delete();
// Optionally, delete the product description if it exists
      await _firestore
          .collection('product_descriptions')
          .doc(productId)
          .delete();
// No need to manually remove from products; the stream will handle it
      Get.snackbar('Success', 'Product deleted successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: $e',
          snackPosition: SnackPosition.BOTTOM);
      throw Exception('Failed to delete product: $e');
    }
  }
}
