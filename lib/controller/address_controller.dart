import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AddressController extends GetxController {
  var addresses = <Map<String, dynamic>>[].obs;
  var selectedAddress = "".obs;
  final box = GetStorage();

  @override
  void onInit() {
    // Initialize GetStorage and load addresses
    if (!box.hasData('addresses')) {
      box.write('addresses', []);
    }

    // Read addresses from storage
    try {
      var storedAddresses = box.read('addresses');
      if (storedAddresses is List) {
        addresses.value = List<Map<String, dynamic>>.from(
          storedAddresses.map((item) => Map<String, dynamic>.from(item)),
        );
      } else {
        addresses.value = [];
      }
    } catch (e) {
      addresses.value = [];
    }

    // Listen for changes and write to storage
    ever(addresses, (List<Map<String, dynamic>> newAddresses) {
      try {
        box.write('addresses', newAddresses);
      } catch (e) {
      }
    });

    super.onInit();
  }

  void addNewAddress(Map<String, dynamic> address) {
    addresses.add(address);
  }

  void deleteAddress(String address) {
    addresses.removeWhere((item) => item['address'] == address);
    if (selectedAddress.value == address) {
      clearSelectedAddress();
    }
  }

  void selectAddress(String address) {
    selectedAddress.value = address;
  }

  void clearSelectedAddress() {
    selectedAddress.value = "";
  }
}
