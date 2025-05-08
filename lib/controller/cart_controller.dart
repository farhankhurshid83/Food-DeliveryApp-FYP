import 'package:get/get.dart';

class CartController extends GetxController {
  var cartItems = <Map<String, dynamic>>[].obs;
  var subtotal = 0.0.obs;
  var delivery = 3.0.obs;
  var total = 0.0.obs;

  void calculateTotals() {
    subtotal.value = cartItems.fold(
        0.0, (sum, item) => sum + (item["price"] * item["quantity"]));
    total.value = subtotal.value + delivery.value;
  }

  void addToCart(Map<String, dynamic> newItem) {
    if (newItem["id"] == null ||
        newItem["name"] == null ||
        newItem["price"] == null) {
      Get.snackbar("Error", "Item details are incomplete, cannot add to cart.");
      return;
    }

    int existingIndex =
    cartItems.indexWhere((item) => item["id"] == newItem["id"]);

    if (existingIndex != -1) {
      cartItems[existingIndex] = {
        ...cartItems[existingIndex],
        "quantity":
        cartItems[existingIndex]["quantity"] + (newItem["quantity"] ?? 1),
      };
    } else {
      cartItems.add({
        "id": newItem["id"],
        "name": newItem["name"] ?? "Unknown Item",
        "image": newItem["image"] ?? "",
        "price": newItem["price"] is num
            ? newItem["price"]
            : double.tryParse(newItem["price"]?.toString() ?? '0.0') ?? 0.0,
        "quantity": newItem["quantity"] ?? 1,
      });
    }
    calculateTotals();
  }

  void increaseQuantity(int index) {
    cartItems[index] = {
      ...cartItems[index],
      "quantity": cartItems[index]["quantity"] + 1,
    };
    calculateTotals();
  }

  void decreaseQuantity(int index) {
    if (cartItems[index]["quantity"] > 1) {
      cartItems[index] = {
        ...cartItems[index],
        "quantity": cartItems[index]["quantity"] - 1,
      };
    } else {
      cartItems.removeAt(index);
    }
    calculateTotals();
  }

  void clearCart() {
    cartItems.clear();
    calculateTotals();
  }
}
