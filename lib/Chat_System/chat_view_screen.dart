import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import 'Classes/constants.dart';

class ChatViewScreen extends StatelessWidget {
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();

  Future<void> _showDialog(BuildContext context, String title, String message,
      {bool isError = false}) async {
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
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatController.currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog(context, 'Error', 'User is not logged in', isError: true);
      });
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'User Not Logged In',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace:
            Container(decoration: const BoxDecoration(color: Colors.orange)),
        title: Obx(() => Text(
              chatController.recipientName.value.isNotEmpty
                  ? 'Chat with ${chatController.recipientName.value}'
                  : chatController.chatType.value == ChatType.customerAdmin
                      ? 'Chat with Customer'
                      : chatController.chatType.value == ChatType.order
                          ? 'Order Chat'
                          : 'Chat with Delivery',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatController.getChatStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.orange));
                }
                if (snapshot.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showDialog(context, 'Error',
                        'Failed to load messages: ${snapshot.error}',
                        isError: true);
                  });
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No Messages Yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(
                          chatController.chatType.value == ChatType.order
                              ? Constants.chatsCollection
                              : Constants.conversationsCollection)
                      .doc(chatController.chatType.value == ChatType.order
                          ? chatController.orderId.value
                          : chatController.generateConversationId(
                              chatController.chatType.value ==
                                      ChatType.customerAdmin
                                  ? chatController.customerId.value
                                  : chatController.adminId.value,
                              chatController.chatType.value ==
                                      ChatType.customerAdmin
                                  ? chatController.adminId.value
                                  : chatController.deliveryBoyId.value,
                            ))
                      .snapshots(),
                  builder: (context, convoSnapshot) {
                    if (convoSnapshot.hasData && convoSnapshot.data!.exists) {
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            controller: chatController.scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isSentByUser = message['senderId'] ==
                                  chatController.currentUserId.value;
                              final readBy = message.data() != null
                                  ? List<dynamic>.from((message.data()
                                          as Map<String, dynamic>)['readBy'] ??
                                      [])
                                  : [];

                              Widget messageWidget = Align(
                                alignment: isSentByUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 12),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.7),
                                  decoration: BoxDecoration(
                                    color: isSentByUser
                                        ? Colors.orange
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12),
                                      topRight: const Radius.circular(12),
                                      bottomLeft: isSentByUser
                                          ? const Radius.circular(12)
                                          : const Radius.circular(0),
                                      bottomRight: isSentByUser
                                          ? const Radius.circular(0)
                                          : const Radius.circular(12),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(1, 1)),
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(-1, -1)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isSentByUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: isSentByUser
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            chatController.formatTimestamp(
                                                message['timestamp']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: isSentByUser
                                                  ? Colors.white70
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          if (isSentByUser &&
                                              readBy.length > 1) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.done_all,
                                                size: 12,
                                                color: Colors.white70),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              return messageWidget;
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(-2, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ),
          Obx(() => IconButton(
                icon: chatController.isSending.value
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange))
                    : const Icon(Icons.send, color: Colors.orange, size: 24),
                onPressed: chatController.sendMessage,
              )),
        ],
      ),
    );
  }
}
