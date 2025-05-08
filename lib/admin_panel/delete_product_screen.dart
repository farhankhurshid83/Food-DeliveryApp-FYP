import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart' show FirebaseCrashlytics;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/product_update _controller.dart';

class DeleteProductScreen extends StatefulWidget {
  @override
  _DeleteProductScreenState createState() => _DeleteProductScreenState();
}

class _DeleteProductScreenState extends State<DeleteProductScreen> {
  final ProductController productController = Get.find<ProductController>();
  final Map<int, bool> _isDeleting = {}; // Track deletion state for each product

  Future<bool> _confirmDelete(BuildContext context, String productName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Product',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $productName?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _showDialog(BuildContext context, String title, String message, {bool isError = false}) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: TextStyle(
            color: isError ? Colors.orange : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  'Delete Product',
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
                      Icons.delete_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(color: Colors.transparent),
                padding: EdgeInsets.all(16),
                child: Obx(() {
                  if (productController.products.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
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
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: List.generate(
                      productController.products.length,
                          (index) {
                        final product = productController.products[index];
                        final isDeleting = _isDeleting[index] ?? false;
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
                                  child: product.imageBase64.isEmpty
                                      ? Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                      : Image.memory(
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
                                  icon: isDeleting
                                      ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.orange,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Icon(
                                    Icons.delete,
                                    color: Colors.orange,
                                    size: 28,
                                  ),
                                  onPressed: isDeleting
                                      ? null
                                      : () async {
                                    bool confirm = await _confirmDelete(context, product.name);
                                    if (confirm) {
                                      setState(() {
                                        _isDeleting[index] = true;
                                      });
                                      try {
                                        await productController.deleteProduct(index as String);
                                        await _showDialog(context, 'Success', 'Product deleted!');
                                      } catch (e) {
                                        String message = e is FirebaseException
                                            ? e.message ?? 'Unknown error'
                                            : e.toString();
                                        await _showDialog(
                                          context,
                                          'Error',
                                          'Failed to delete: $message',
                                          isError: true,
                                        );
                                        FirebaseCrashlytics.instance.recordError(
                                          e,
                                          StackTrace.current,
                                          reason: 'Failed to delete product',
                                        );
                                      } finally {
                                        setState(() {
                                          _isDeleting.remove(index);
                                        });
                                      }
                                    }
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
