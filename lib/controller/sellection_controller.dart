import 'package:get/get.dart';

class SelectionController extends GetxController {
  final RxMap<String, bool> _selectedItems = <String, bool>{}.obs;

  bool isSelected(String id) => _selectedItems[id] ?? false;

  void toggleSelection(String id) {
    _selectedItems[id] = !(_selectedItems[id] ?? false);
    update();
  }
}