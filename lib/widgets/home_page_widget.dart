import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/detail_page.dart';

void navigateToDetail(
    BuildContext context,
    String id,
    String name,
    String price,
    String imageBase64,
    List<String> toppings,
    ) {
  final product = {
    'id': id,
    'name': name,
    'price': double.tryParse(price) ?? 0.0,
    'image': imageBase64, // Updated to imageBase64
    'toppings': toppings,
  };
  Get.to(() => ProductDetailPage(product: product));
}

Widget buildFoodItem({
  required String id,
  required String name,
  required String price,
  required String imageBase64, // Updated to imageBase64
  required BuildContext context,
  bool isHorizontal = false,
  List<String> toppings = const [],
}) {
  return GestureDetector(
    onTap: () => navigateToDetail(context, id, name, price, imageBase64, toppings),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isHorizontal ? 150 : 150,
      height: 170,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9DC), // Beige background from image
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildImage(imageBase64, width: 130, height: 130)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              'Rs ${double.tryParse(price)?.toStringAsFixed(2) ?? "0.00"}',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildImage(String imageBase64, {double width = 120, double height = 100}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: imageBase64.isNotEmpty
        ? Image.memory(
      base64Decode(imageBase64),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _placeholderImage(width, height),
    )
        : _placeholderImage(width, height),
  );
}

Widget _placeholderImage(double width, double height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
  );
}

Widget buildBestSellerItem(
    String id,
    String name,
    String price,
    String imageBase64, // Updated to imageBase64
    BuildContext context,
    ) {
  return buildFoodItem(
    id: id,
    name: name,
    price: price,
    imageBase64: imageBase64,
    context: context,
    isHorizontal: true,
  );
}

Widget buildRecommendItem(
    String id,
    String name,
    String price,
    String imageBase64, // Updated to imageBase64
    BuildContext context,
    ) {
  return buildFoodItem(
    id: id,
    name: name,
    price: price,
    imageBase64: imageBase64,
    context: context,
    isHorizontal: false,
  );
}
