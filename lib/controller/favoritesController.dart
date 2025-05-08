import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FavoritesController extends GetxController {
  var favorites = <String>[].obs;
  final box = GetStorage();

  @override
  void onInit() {
    // Ensure GetStorage is initialized before use
    if (!box.hasData('favorites')) {
      box.write('favorites', []);
    }

    // Read favorites from storage
    try {
      var storedFavorites = box.read('favorites');
      if (storedFavorites is List) {
        favorites.value = List<String>.from(storedFavorites);
      } else {
        favorites.value = [];
      }
    } catch (e) {
      favorites.value = [];
    }

    // Listen for changes and write to storage
    ever(favorites, (List<String> newFavorites) {
      try {
        box.write('favorites', newFavorites);
      } catch (e) {
      }
    });

    super.onInit();
  }

  void toggleFavorite(String productId) {
    if (productId.isEmpty) {
      return;
    }
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
  }

  bool isFavorite(String productId) => favorites.contains(productId);

  void clearFavorites() {
    favorites.clear();
  }
}
