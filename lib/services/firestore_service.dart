import 'package:cloud_firestore/cloud_firestore.dart';

class GenericFirestoreService<T> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath;
  final T Function(Map<String, dynamic> data, String id) fromFirestore;

  GenericFirestoreService({
    required this.collectionPath,
    required this.fromFirestore,
  });

  // Stream for real-time updates
  Stream<List<T>> streamList() {
    return _db
        .collection(collectionPath)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Generic Create
  Future<DocumentReference> create(Map<String, dynamic> data) async {
    return await _db.collection(collectionPath).add(data);
  }

  // Generic Update
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _db.collection(collectionPath).doc(id).update(data);
  }

  // Generic Delete
  Future<void> delete(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
  }
}
