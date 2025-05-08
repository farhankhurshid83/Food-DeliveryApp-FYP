import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I track my order?',
        'answer':
        'You can track your order in the "Orders" section of the app. Select your order to view real-time updates.'
      },
      {
        'question': 'What payment methods are supported?',
        'answer':
        'We support credit/debit cards, digital wallets (e.g., Apple Pay, Google Pay), and cash on delivery in select areas.'
      },
      {
        'question': 'How do I cancel an order?',
        'answer':
        'You can cancel an order within 5 minutes of placing it from the "Orders" page. Contact support for assistance with later cancellations.'
      },
      {
        'question': 'What if my food arrives cold?',
        'answer':
        'If your food isn’t up to standard, contact us via the "About Us" page, and we’ll resolve the issue.'
      },
      {
        'question': 'How do I apply a promo code?',
        'answer':
        'Enter your promo code at checkout in the "Promo Code" field. Ensure the code is valid for your order.'
      },
      {
        'question': 'Can I schedule a delivery?',
        'answer':
        'Yes, select "Schedule Delivery" during checkout to choose a convenient time slot.'
      },
      {
        'question': 'What are the delivery fees?',
        'answer':
        'Delivery fees vary based on distance and restaurant. The fee is shown at checkout before you confirm your order.'
      },
      {
        'question': 'How do I update my profile?',
        'answer':
        'Go to the "Settings" page to update your name, email, or password.'
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Help',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[300]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.help, size: 80, color: Colors.white70),
                ),
              ),
            ),
            backgroundColor: Colors.orange,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final faq = faqs[index];
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading:
                      const Icon(Icons.question_answer, color: Colors.white),
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            faq['answer']!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: faqs.length,
            ),
          ),
        ],
      ),
    );
  }
}
