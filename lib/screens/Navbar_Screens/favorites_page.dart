import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controller/favoritesController.dart';
import '../../../controller/product_update _controller.dart';
import '../Home_Screen/Pages/detail_page.dart';

class FavoriteScreen extends StatelessWidget {
  final FavoritesController favoritesController = Get.find<FavoritesController>();
  final ProductController productController = Get.find<ProductController>();
  final RxBool isGridView = false.obs; // State to track view mode

  // Placeholder image widget
  Widget _buildPlaceholderImage({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 30, color: Colors.grey),
          Text(
            'BiteOnTime',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Image widget with error handling
  Widget _buildImage(String imageBase64, {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageBase64.isNotEmpty
          ? Image.memory(
        base64Decode(imageBase64),
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: 'Image of food item',
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(width: width, height: height),
      )
          : _buildPlaceholderImage(width: width, height: height),
    );
  }

  // Show dialog to confirm deletion
  void _showDeleteDialog(BuildContext context, {String? productId, String? productName, bool isClearAll = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isClearAll ? 'Clear All Favorites' : 'Remove Favorite',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          isClearAll
              ? 'Are you sure you want to remove all items from your favorites?'
              : 'Are you sure you want to remove $productName from your favorites?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (isClearAll) {
                favoritesController.clearFavorites();
                Get.snackbar(
                  'Favorites Cleared',
                  'All favorites have been removed.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              } else if (productId != null) {
                favoritesController.toggleFavorite(productId);
              }
              Get.back();
            },
            child: Text(
              isClearAll ? 'Clear All' : 'Remove',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build individual product tile for both list and grid
  Widget _buildProductTile(BuildContext context, dynamic product, bool isGrid) {
    final List<Color> pastelColors = [
      Color(0xffffffff),
      Color(0xffffffff),
      Color(0xffffffff),
    ];
    final int colorIndex = product.id.hashCode % pastelColors.length;
    final Color backgroundColor = pastelColors[colorIndex];

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          'Swipe to remove',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        child: Text(
          'Swipe to remove',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onDismissed: (direction) {},
      confirmDismiss: (direction) async {
        _showDeleteDialog(context, productId: product.id, productName: product.name);
        return false;
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isGrid ? 12 : 12, right: isGrid ? 12 : 0),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Get.to(() => ProductDetailPage(product: {
              'id': product.id,
              'name': product.name,
              'price': product.price,
              'image': product.imageBase64,
              'category': product.category,
              'subCategory': product.subCategory,
            })),
            child: isGrid
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildImage(
                    product.imageBase64,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PKR ${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
                : ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _buildImage(
                product.imageBase64,
                width: 60,
                height: 60,
              ),
              title: Text(
                product.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                semanticsLabel: product.name,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'PKR ${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    semanticsLabel: 'Price: PKR ${product.price.toStringAsFixed(2)}',
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
                onPressed: () => favoritesController.toggleFavorite(product.id),
                tooltip: 'Remove from favorites',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: Text(
          'Favorites',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Obx(() => favoritesController.favorites.isNotEmpty
              ? Row(
            children: [
              IconButton(
                icon: Icon(isGridView.value ? Icons.list : Icons.grid_view),
                color: Colors.white,
                onPressed: () => isGridView.toggle(),
                tooltip: isGridView.value ? 'Switch to List View' : 'Switch to Grid View',
              ),
              TextButton.icon(
                onPressed: () => _showDeleteDialog(context, isClearAll: true),
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )
              : SizedBox.shrink()),
          SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Obx(() {
          var favoriteProducts = productController.products
              .where((p) => favoritesController.favorites.contains(p.id))
              .toList();
          if (productController.products.isEmpty) {
            return Center(
              child: FutureBuilder(
                future: Future.delayed(Duration(seconds: 1)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(
                      color: Colors.orange,
                    );
                  }
                  if (favoriteProducts.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add some products to your favorites!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            );
          }
          if (favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some products to your favorites!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          return isGridView.value
              ? GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return _buildProductTile(context, product, true);
            },
          )
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return _buildProductTile(context, product, false);
            },
          );
        }),
      ),
    );
  }
}
