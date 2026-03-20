import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestPage extends StatelessWidget {
  const FirestoreTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Shops Test")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("categories")
            .doc("restaurants")
            .collection("shops")
            .snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var shop = docs[index];

              return ListTile(
                title: Text(shop["shopName"]),
                subtitle: Text(shop["address"]),
                trailing: Text("⭐ ${shop["rating"]}"),
              );
            },
          );
        },
      ),
    );
  }
}
