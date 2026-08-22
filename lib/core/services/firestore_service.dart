import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Generic method to get a document from the user's document
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Generic method to update the user's document
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Stream of the user's document
  Stream<Map<String, dynamic>?> userProfileStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }

  // Generic method to add a document to a subcollection
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    
    // Check if ID is provided, else let Firestore generate one
    if (data.containsKey('id') && data['id'] != null && data['id'].toString().isNotEmpty) {
      await _db.collection('users').doc(uid).collection(collectionPath).doc(data['id']).set(data);
    } else {
      await _db.collection('users').doc(uid).collection(collectionPath).add(data);
    }
  }

  // Generic method to update a document
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _db.collection('users').doc(uid).collection(collectionPath).doc(docId).update(data);
  }

  // Generic method to delete a document
  Future<void> deleteDocument(String collectionPath, String docId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _db.collection('users').doc(uid).collection(collectionPath).doc(docId).delete();
  }

  // Generic stream of a collection
  Stream<List<Map<String, dynamic>>> collectionStream(String collectionPath) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    
    return _db.collection('users').doc(uid).collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ensure ID is included
        return data;
      }).toList();
    });
  }

  // Upload an image to Firebase Storage and return its URL
  Future<String?> uploadProfileImage(dynamic imageFile) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    try {
      final ref = _storage.ref().child('users/$uid/profile_image.jpg');
      
      if (kIsWeb) {
        // For web, imageFile will be Uint8List
        await ref.putData(imageFile as Uint8List, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // For mobile/desktop, imageFile will be File
        await ref.putFile(imageFile as File, SettableMetadata(contentType: 'image/jpeg'));
      }
      
      final url = await ref.getDownloadURL();
      
      // Update the user's profile with the new image URL
      await updateUserProfile({'avatarUrl': url});
      
      return url;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }
}

// Global instance for easy access
final firestoreService = FirestoreService();
