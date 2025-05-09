Food Delivery App
Welcome to the Food Delivery App, a Flutter-based mobile application designed to provide a seamless food ordering and delivery experience. This app connects customers, restaurant admins, and delivery personnel, offering features like real-time order tracking, a chat system for communication, and secure user authentication. Built with a modern tech stack, it leverages Firebase for backend services and GetX for state management.





Table of Contents

Features
Technologies Used
Installation
Usage
Project Structure
Contributing
License
Contact








Features

User Authentication: Secure login and registration using Firebase Authentication.
Food Ordering: Browse menus, place orders, and customize items.
Real-Time Order Tracking: Track the status of your order from preparation to delivery.
Chat System: Real-time chat between customers, admins, and delivery personnel for order updates and support.
Supports customer-admin, customer-delivery, and admin-delivery chat types.
Features unread message counts and  notifications.


Order Management: Admins can manage orders, update statuses, and communicate with customers and delivery personnel.
Push Notifications: Receive updates on order status and new messages via Awesom Notification.
User Profiles: Manage personal information and view order history.
Responsive UI: Beautiful and intuitive interface optimized for both Android and iOS.







Technologies Used

Frontend: Flutter (Dart)
State Management: GetX
Backend: Firebase
Authentication: Firebase Authentication
Database: Cloud Firestore
Notifications:  Awesom Notification
Crash Reporting: Firebase Crashlytics





Other Packages:
cloud_firestore: For real-time database operations
firebase_auth: For user authentication
rxdart: For combining multiple Firestore streams
awesome_notifications: For local and push notifications


IDE: Visual Studio Code / Android Studio
Version Control: Git

Installation
To set up the project locally, follow these steps:
Prerequisites





Flutter SDK: Version 3.0.0 or higher
Dart: Version 2.17.0 or higher
Firebase Account: For backend services
IDE: Android Studio or VS Code
Git: For cloning the repository







Steps

Clone the Repository:
git clone https://https://github.com/farhankhurshid83/Food-DeliveryApp-FYP
cd food_ui


Install Dependencies:Run the following command to install all required packages:
flutter pub get


Set Up Firebase:

Create a Firebase project in the Firebase Console.
Add an Android and/or iOS app to your Firebase project.
Download the google-services.json (for Android) and/or GoogleService-Info.plist (for iOS) and place them in the appropriate directories:
Android: android/app/
iOS: ios/Runner/


Enable Firebase Authentication (Email/Password or other methods).
Set up Cloud Firestore and create collections for users, conversations, and chats.
Configure Firebase Cloud Messaging for push notifications.
Enable Firebase Crashlytics for crash reporting.


Configure Firestore Rules:Update your Firestore security rules to secure your data. Example:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && resource.data.participants.includes(request.auth.uid);
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && resource.data.participants.includes(request.auth.uid);
    }
  }
}


Run the App:Connect a device or emulator, then run:
flutter run



Usage

Sign Up / Log In:

Create an account or log in using your credentials.
Roles supported: Customer, Admin, Delivery Personnel.


Browse and Order:

Explore restaurants and menus.
Add items to your cart and place an order.


Track Orders:

View real-time updates on your order status.


Chat:

Communicate with admins or delivery personnel via the chat system.
Receive notifications for new messages.


Admin Features:

Manage orders, update statuses, and respond to customer queries.
Communicate with delivery personnel for logistics.



Project Structure
food_ui/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/                     # Main application code
│   ├── Chat_System/         # Chat-related features
│   │   ├── Classes/         # Utility classes (constants, user_cache)
│   │   ├── controller/      # ChatController for chat logic
│   │   └── screens/         # ChatListWidget, ChatViewScreen
│   ├── controller/          # Other controllers (e.g., AuthController)
│   ├── services/            # Notification and other services
│   └── main.dart            # App entry point
├── pubspec.yaml             # Dependencies and configuration
└── README.md                # Project documentation

Contributing
Contributions are welcome! To contribute:

Fork the Repository:Click the "Fork" button on GitHub and clone your fork:
git clone https://github.com/your-username/food_ui.git


Create a Branch:
git checkout -b feature/your-feature-name


Make Changes:Implement your feature or bug fix, following the coding style and structure.

Run Tests:Ensure your changes pass any existing tests:
flutter test


Commit and Push:
git commit -m "Add your feature description"
git push origin feature/your-feature-name


Create a Pull Request:Open a pull request on GitHub, describing your changes and referencing any related issues.


Guidelines

Follow Flutter best practices and Dart style guidelines.
Write clear, concise commit messages.
Update documentation if necessary.
Ensure your code is well-tested.

License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For questions or feedback, please contact:

Your Name: farhankhurshid0000@gmail.com
GitHub Issues: Open an issue on this repository


Happy coding, and enjoy your food delivery experience with the Food Delivery App! 🍔🚀

 
