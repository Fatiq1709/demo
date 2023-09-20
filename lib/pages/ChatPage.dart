import 'package:chat_app/main.dart';
import 'package:chat_app/models/ChatRoomModel.dart';
import 'package:chat_app/models/UserModel.dart';
import 'package:chat_app/pages/ChatRoomPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;
  const ChatPage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${widget.userModel.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .get();

    if (snapshot.docs.length > 0) {
      // fetch the existing one
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      // create a new one
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatroom.chatroomid)
          .set(newChatroom.toMap());

      chatRoom = newChatroom;
    }

    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Chat App"),
      ),
      body: SafeArea(
        child: Container(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> userMap =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        UserModel resultUser = UserModel.fromMap(userMap);
                        return ListTile(
                          onTap: () async {
                            ChatRoomModel? chatroomModel =
                                await getChatroomModel(resultUser);

                            if (chatroomModel != null) {
                              Navigator.pop(context);
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ChatRoomPage(
                                  targetUser: resultUser,
                                  userModel: widget.userModel,
                                  firebaseUser: widget.firebaseUser,
                                  chatroom: chatroomModel,
                                );
                              }));
                            }
                          },
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(resultUser.profilepic!),
                            backgroundColor: Colors.grey[500],
                          ),
                          title: Text(resultUser.fullname.toString()),
                          subtitle: Text(resultUser.email.toString()),
                          trailing: Icon(Icons.keyboard_arrow_right),
                        );
                      },
                    ),
                  );
                } else {
                  return Text("No data!");
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
