import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controller/product_update _controller.dart';
import '../models/product_model.dart';
import '../widgets/home_page_widget.dart';
import '../widgets/promotional_banner.dart';
import 'see_more_best_sellers_page.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const HomePage({super.key, required this.scaffoldKey});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> categories = ['Snacks', 'Meal', 'Vegan', 'Dessert', 'Drinks'];
  final Map<String, List<Product>> _productsCache = {};
  final ProductController productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Product> getProductsByCategory(String category) {
    if (_productsCache.containsKey(category)) {
      return _productsCache[category]!;
    }
    List<Product> products = productController.products
        .where((product) => product.category == category && product.subCategory != 'Recommended')
        .toList();
    _productsCache[category] = products;
    return products;
  }

  List<Product> getRecommendedProducts(String category) {
    if (_productsCache.containsKey('Recommended_$category')) {
      return _productsCache['Recommended_$category']!;
    }
    List<Product> recommended = productController.products
        .where((product) => product.category == category && product.subCategory == 'Recommended')
        .toList();
    _productsCache['Recommended_$category'] = recommended;
    return recommended;
  }

  Future<void> _onRefresh() async {
    // Clear cache to ensure fresh data
    _productsCache.clear();
    // Refresh products by rebinding the Firestore stream
    await productController.refreshProducts();
    // Notify user of successful refresh
    Get.snackbar(
      "Refreshed",
      "Products have been reloaded.",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            "BiteOnTime",
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.orange,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildCategoryTabs(),
            const SizedBox(height: 20),
            CustomCarousel(
              imagePaths: [
                'assets/images/carousel1.png',
                'assets/images/carousel2.png',
                'assets/images/carousel3.png',
              ],
              height: 170,
              autoPlayInterval: const Duration(seconds: 4),
              showEnlarge: true,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              showIndicators: true,
              overlayOpacity: 0.4,
              indicatorColor: Colors.white,
              activeIndicatorColor: Colors.orange,
            ),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Stack(
      children: [
        Container(
          height: 50,
          decoration: const BoxDecoration(color: Colors.orange),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.white,
                  tabs: categories.map((category) {
                    return Tab(
                      child: SizedBox(
                        width: 60,
                        child: Center(
                          child: Text(
                            category,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    return Expanded(
      child: Obx(() {
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
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
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
        return TabBarView(
          controller: _tabController,
          children: categories.map((category) {
            List<Product> bestSellers = getProductsByCategory(category);
            List<Product> recommended = getRecommendedProducts(category);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Best Seller",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => SeeMoreBestSellersPage(category: category));
                          },
                          child: Row(
                            children: [
                              Text(
                                "View More",
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                              ),
                              Icon(Icons.expand_more, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(bestSellers),
                    const SizedBox(height: 20),
                    _buildRecommendedSection(recommended),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildSection(List<Product> products) {
    return products.isEmpty
        ? Center(
      child: Text(
        'No Best Seller items available',
        style: GoogleFonts.poppins(color: Colors.grey),
      ),
    )
        : SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          Product product = products[index];
          return buildBestSellerItem(
            product.id,
            product.name,
            product.price.toString(),
            product.imageBase64,
            context,
          );
        },
      ),
    );
  }

  Widget _buildRecommendedSection(List<Product> recommended) {
    if (recommended.isEmpty) {
      return Text(
        "No recommended products available.",
        style: GoogleFonts.poppins(color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 150 / 200,
          ),
          itemCount: recommended.length,
          itemBuilder: (context, index) {
            Product product = recommended[index];
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: buildRecommendItem(
                product.id,
                product.name,
                product.price.toString(),
                product.imageBase64,
                context,
              ),
            );
          },
        ),
      ],
    );
  }
}
