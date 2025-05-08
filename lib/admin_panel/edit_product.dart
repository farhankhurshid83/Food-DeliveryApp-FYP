import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/product_update _controller.dart';
import '../models/product_model.dart';

class EditProductPage extends StatefulWidget {
  final int index;
  final Product product;

  const EditProductPage({required this.index, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image; // New image picked by the user
  String? _existingImageBase64; // Existing base64 image from the product
  String _selectedCategory = 'Snacks';
  String _selectedSubCategory = 'Best Seller';
  final ImagePicker _picker = ImagePicker();
  final ProductController productController = Get.find<ProductController>();
  bool _isUpdatingProduct = false; // Added for loading state

  final List<String> _categories = ['Snacks', 'Meal', 'Vegan', 'Dessert', 'Drinks'];
  final List<String> _subCategories = ['Best Seller', 'Recommended'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.name;
    _priceController.text = widget.product.price.toString();
    _selectedCategory = widget.product.category;
    _selectedSubCategory = widget.product.subCategory;
    _existingImageBase64 = widget.product.imageBase64; // Store the existing base64 image
    // Fetch the description from Firestore
    FirebaseFirestore.instance
        .collection('product_descriptions')
        .doc(widget.product.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        _descriptionController.text = doc['description'] ?? '';
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      var bytes = await image.length();
      // Lowered the limit to ~700 KB to account for base64 encoding overhead (1 MB Firestore limit)
      if (bytes > 700 * 1024) {
        _showDialog(context, 'Error', 'Image size must be under 700 KB to fit Firestore limits', isError: true);
        return;
      }
      if (!['.jpg', '.jpeg', '.png'].contains(pickedFile.path.toLowerCase().substring(pickedFile.path.lastIndexOf('.')))) {
        _showDialog(context, 'Error', 'Only JPG/PNG images allowed', isError: true);
        return;
      }
      setState(() {
        _image = image;
        _existingImageBase64 = null; // Clear existing image since a new one is picked
      });
    }
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
        content: Text(message, style: TextStyle(fontSize: 16)),
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

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null && _existingImageBase64 == null) {
        await _showDialog(context, 'Error', 'Please select an image', isError: true);
        return;
      }
      setState(() {
        _isUpdatingProduct = true; // Show loading indicator
      });
      try {
        final updatedProduct = Product(
          id: widget.product.id,
          name: _nameController.text,
          price: double.parse(_priceController.text),
          imageBase64: _existingImageBase64 ?? '', // Will be updated in ProductController if _image is not null
          category: _selectedCategory,
          subCategory: _selectedSubCategory,
        );
        // Pass the updated product and new image file to the controller
        await productController.updateProduct(updatedProduct, _image);
        // Update the description in Firestore
        await FirebaseFirestore.instance.collection('product_descriptions').doc(widget.product.id).set({
          'description': _descriptionController.text,
        });
        await _showDialog(context, 'Success', 'Product updated successfully!');
        Get.back();
      } catch (e) {
        String message = e is FirebaseException ? e.message ?? 'Unknown error' : e.toString();
        await _showDialog(context, 'Error', 'Failed to update product: $message', isError: true);
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to update product');
      } finally {
        setState(() {
          _isUpdatingProduct = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '    Edit Product',
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
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[100]!, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 16,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Product Name',
                              validator: (value) => value!.isEmpty ? 'Enter product name' : null,
                            ),
                            SizedBox(height: 10),
                            _buildTextField(
                              controller: _priceController,
                              label: 'Price (Rs)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) return 'Enter price';
                                if (double.tryParse(value) == null) return 'Enter valid price';
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              maxLines: 3,
                              validator: (value) => value!.isEmpty ? 'Enter description' : null,
                            ),
                            SizedBox(height: 10),
                            _buildDropdown(
                              value: _selectedCategory,
                              items: _categories,
                              label: 'Category',
                              onChanged: (value) => setState(() => _selectedCategory = value!),
                            ),
                            SizedBox(height: 10),
                            _buildDropdown(
                              value: _selectedSubCategory,
                              items: _subCategories,
                              label: 'Sub Category',
                              onChanged: (value) => setState(() => _selectedSubCategory = value!),
                            ),
                            SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(-2, -2)),
                                    ],
                                    image: _image != null
                                        ? DecorationImage(
                                      image: FileImage(_image!),
                                      fit: BoxFit.cover,
                                    )
                                        : _existingImageBase64 != null && _existingImageBase64!.isNotEmpty
                                        ? DecorationImage(
                                      image: MemoryImage(base64Decode(_existingImageBase64!)),
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                  child: (_image == null && _existingImageBase64 == null) ||
                                      (_image == null && _existingImageBase64!.isEmpty)
                                      ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 30,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Pick Image',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 32),
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isUpdatingProduct ? null : _updateProduct,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isUpdatingProduct
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    'Update Product',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUpdatingProduct)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(-2, -2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.orange, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(-2, -2)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.orange, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.orange),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
