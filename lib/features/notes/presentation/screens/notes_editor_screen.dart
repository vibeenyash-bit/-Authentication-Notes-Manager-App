import 'package:auth_notes_manager/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/note_model.dart';
import '../controllers/notes_bloc.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final NotesBloc notesBloc;

  const NoteEditorScreen({super.key, this.note, required this.notesBloc});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.note?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    if (isEditing) {
      widget.notesBloc.add(
        NoteUpdateRequested(
          noteId: widget.note!.id,
          title: _titleController.text,
          description: _descriptionController.text,
        ),
      );
    } else {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      widget.notesBloc.add(
        NoteAddRequested(
          userId: userId,
          title: _titleController.text,
          description: _descriptionController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.notesBloc,
      child: BlocConsumer<NotesBloc, NotesState>(
        listener: (context, state) {
          if (state is NotesActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is NotesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isSaving =
              state is NotesLoaded && state.isMutating;

          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit note' : 'New note'),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Give your note a name',
                      ),
                      validator: (val) => val!.trim().isEmpty
                          ? 'Title is mandatory'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Write what is on your mind...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSaving ? null : _saveNote,
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textDark,
                                ),
                              ),
                            )
                          : Text(isEditing ? 'Update note' : 'Save note'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
