import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../../../controller/product_update _controller.dart';
import '../../../../../models/product_model.dart';
import '../../../../../widgets/home_page_widget.dart';

class SeeMoreBestSellersPage extends StatelessWidget {
  final String category;
  final ProductController productController = Get.find<ProductController>(); // Use existing ProductController instance

  SeeMoreBestSellersPage({super.key, required this.category});

  List<Product> getProductsByCategory(String category) {
    return productController.products
        .where((product) => product.category == category && product.subCategory != 'Recommended')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Best Sellers - $category",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final bestSellers = getProductsByCategory(category);
          // Check if products are still loading
          if (productController.products.isEmpty) {
            return Center(
              child: FutureBuilder(
                future: Future.delayed(Duration(seconds: 1)), // Give some time for loading
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(
                      color: Colors.orange,
                    );
                  }
                  // After waiting, check if bestSellers is still empty
                  if (bestSellers.isEmpty) {
                    return Text(
                      'No Best Seller items available',
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                    );
                  }
                  return SizedBox.shrink(); // This won't be reached due to Obx re-evaluation
                },
              ),
            );
          }
          // Products are loaded, display the grid
          return bestSellers.isEmpty
              ? Center(
            child: Text(
              'No Best Seller items available',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          )
              : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 150 / 200,
            ),
            itemCount: bestSellers.length,
            itemBuilder: (context, index) {
              Product product = bestSellers[index];
              return AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: buildFoodItem(
                  id: product.id,
                  name: product.name,
                  price: product.price.toString(),
                  imageBase64: product.imageBase64, // Updated to imageBase64
                  context: context,
                  isHorizontal: false,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
