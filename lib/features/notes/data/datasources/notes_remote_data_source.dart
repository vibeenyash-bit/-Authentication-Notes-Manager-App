import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NotesRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NoteModel>> streamNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        //.orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromSnapshot(doc))
            .toList());
  }

  Future<void> addNote({required String userId, required String title, required String description}) async {
    final newNote = NoteModel(
      id: '',
      userId: userId,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore.collection('notes').add(newNote.toMap());
  }

  Future<void> updateNote({required String noteId, required String title, required String description}) async {
    await _firestore.collection('notes').doc(noteId).update({
      'title': title,
      'description': description,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }
}