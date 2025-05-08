import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_ui/admin_panel/edit_product.dart';
import '../controller/product_update _controller.dart';

class UpdateProductScreen extends StatelessWidget {
  final ProductController productController = Get.find<ProductController>(); // Use existing instance

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade200,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Update Product',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.all(16),
                child: Obx(() {
                  // Check if products are still loading
                  if (productController.products.isEmpty) {
                    // Since ProductController loads products in onInit, we'll show a loading indicator
                    // until products are fetched or confirmed to be empty
                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: FutureBuilder(
                          future: Future.delayed(Duration(seconds: 1)), // Give some time for loading
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(
                                color: Colors.orange,
                              );
                            }
                            // After waiting, check if products are still empty
                            if (productController.products.isEmpty) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Products Available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SizedBox.shrink(); // This won't be reached due to Obx re-evaluation
                          },
                        ),
                      ),
                    );
                  }
                  // Products are loaded, display the list
                  return Column(
                    children: List.generate(
                      productController.products.length,
                          (index) {
                        final product = productController.products[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.imageBase64.isNotEmpty
                                      ? Image.memory(
                                    base64Decode(product.imageBase64),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 30,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  )
                                      : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Rs ${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    Get.to(
                                          () => EditProductPage(index: index, product: product),
                                      transition: Transition.rightToLeft,
                                      duration: Duration(milliseconds: 400),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
