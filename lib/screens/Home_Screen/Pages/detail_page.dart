import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controller/favoritesController.dart';
import '../../../controller/product_detail_controller.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({required this.product, super.key});

  Widget _buildPlaceholderImage() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          Text(
            'BiteOnTime',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductDetailController controller = Get.put(ProductDetailController());
    final FavoritesController favoritesController = Get.find<FavoritesController>();

    // Safely access product fields
    final String id = product['id'] ?? '';
    final String name = product['name'] ?? 'Unnamed Product';
    final double price = (product['price'] is num
        ? product['price']
        : double.tryParse(product['price']?.toString() ?? '0.0')) ??
        0.0;
    final String imageBase64 = product['image'] ?? ''; // Updated to imageBase64

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
          tooltip: 'Go back',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Handle menu action (e.g., open drawer or menu)
            },
            tooltip: 'Open menu',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.orange.shade400),
        child: Column(
          children: [
            // Product Image
            Container(
              height: 250,
              width: double.infinity,
              alignment: Alignment.center,
              child: imageBase64.isNotEmpty
                  ? Image.memory(
                base64Decode(imageBase64),
                height: 250,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, _) {
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                semanticLabel: 'Image of $name',
              )
                  : _buildPlaceholderImage(),
            ),
            // Content Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Unit
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: name,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1 each',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      semanticsLabel: 'Unit: 1 each',
                    ),
                    SizedBox(height: 16),
                    // Quantity and Price Row
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Decrease Button Container
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove, color: Colors.white, size: 16),
                                onPressed: controller.decreaseQuantity,
                                tooltip: 'Decrease quantity',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                              ),
                            ),
                            // Quantity Text Container
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Text(
                                controller.quantity.value.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            // Increase Button Container
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Colors.white, size: 16),
                                onPressed: controller.increaseQuantity,
                                tooltip: 'Increase quantity',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rs ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          semanticsLabel: 'Price: Rs ${price.toStringAsFixed(2)}',
                        ),
                      ],
                    )),
                    SizedBox(height: 16),
                    // Description
                    Text(
                      'Product Description',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('product_descriptions')
                          .doc(id)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: Colors.orange),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error loading description',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange),
                          );
                        }
                        String description = snapshot.data?.exists ?? false
                            ? (snapshot.data!['description'] ?? 'No description available')
                            : 'No description available';
                        return Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          semanticsLabel: 'Description: $description',
                        );
                      },
                    ),
                    Spacer(),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(width: 1, color: Colors.orange),
                          ),
                          child: IconButton(
                            icon: Icon(
                              favoritesController.isFavorite(id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.orange,
                              size: 30,
                            ),
                            onPressed: () => favoritesController.toggleFavorite(id),
                            tooltip: favoritesController.isFavorite(id)
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        )),
                        AnimatedScaleButton(
                          onPressed: () {
                            controller.addToCart(product);
                          },
                          semanticsLabel: 'Add $name to cart',
                          child: Container(
                            width: 220,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Add to cart',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for animated button scaling
class AnimatedScaleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String semanticsLabel;

  const AnimatedScaleButton({
    required this.child,
    required this.onPressed,
    required this.semanticsLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Semantics(
        label: semanticsLabel,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          transform: Matrix4.identity()..scale(1.0),
          transformAlignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTapDown: (_) {
                (context as Element).markNeedsBuild();
              },
              onTapUp: (_) {
                (context as Element).markNeedsBuild();
                onPressed();
              },
              onTapCancel: () {
                (context as Element).markNeedsBuild();
              },
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
