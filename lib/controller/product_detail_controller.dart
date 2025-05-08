import 'package:get/get.dart';
import '../controller/cart_controller.dart';

class ProductDetailController extends GetxController {
  var quantity = 1.obs; // Observable quantity
  final CartController cartController = Get.find<CartController>();

  void increaseQuantity() {
    quantity.value++;
  }

  void decreaseQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void addToCart(Map<String, dynamic> product) {
    cartController.addToCart({
      'id': product['id'], // Ensure each product has a unique ID
      'name': product['name'],
      'price': product['price'] is double ? product['price'] : double.tryParse(product['price'].toString()) ?? 0.0, // Ensure price is double
      'quantity': quantity.value,
      'image': product['image'],
    });

    // Reset quantity to 1 after adding to cart
    quantity.value = 1;

    // Show confirmation message
    Get.snackbar(
      'Added to Cart',
      '${product['name']} added to cart!',
      snackPosition: SnackPosition.TOP,
    );
  }
}
