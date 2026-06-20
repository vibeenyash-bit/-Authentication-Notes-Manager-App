import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/notes_remote_data_source.dart';
import '../../data/models/note_model.dart';

// ----------------------------- Events -----------------------------

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// Starts (or restarts) listening to the user's real-time notes stream.
class NotesSubscriptionRequested extends NotesEvent {
  final String userId;

  const NotesSubscriptionRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class _NotesUpdated extends NotesEvent {
  final List<NoteModel> notes;

  const _NotesUpdated(this.notes);

  @override
  List<Object?> get props => [notes];
}

class _NotesStreamFailed extends NotesEvent {
  final String message;

  const _NotesStreamFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class NoteAddRequested extends NotesEvent {
  final String userId;
  final String title;
  final String description;

  const NoteAddRequested({
    required this.userId,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [userId, title, description];
}

class NotesUnsubscribeRequested extends NotesEvent {
  const NotesUnsubscribeRequested();
}

class NoteUpdateRequested extends NotesEvent {
  final String noteId;
  final String title;
  final String description;

  const NoteUpdateRequested({
    required this.noteId,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [noteId, title, description];
}

class NoteDeleteRequested extends NotesEvent {
  final String noteId;

  const NoteDeleteRequested(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// ----------------------------- States -----------------------------

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {
  const NotesInitial();
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  final List<NoteModel> notes;
  final bool isMutating;

  const NotesLoaded(this.notes, {this.isMutating = false});

  NotesLoaded copyWith({List<NoteModel>? notes, bool? isMutating}) {
    return NotesLoaded(
      notes ?? this.notes,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [notes, isMutating];
}

class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotesActionSuccess extends NotesState {
  final String message;
  final List<NoteModel> notes;

  const NotesActionSuccess(this.message, this.notes);

  @override
  List<Object?> get props => [message, notes];
}

// ----------------------------- Bloc -----------------------------

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRemoteDataSource dataSource;
  StreamSubscription<List<NoteModel>>? _subscription;

  NotesBloc({required this.dataSource}) : super(const NotesInitial()) {
    on<NotesSubscriptionRequested>(_onSubscriptionRequested);
    on<_NotesUpdated>(_onNotesUpdated);
    on<_NotesStreamFailed>((event, emit) => emit(NotesError(event.message)));
    on<NoteAddRequested>(_onAddRequested);
    on<NotesUnsubscribeRequested>(_onUnsubscribeRequested);
    on<NoteUpdateRequested>(_onUpdateRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onSubscriptionRequested(
    NotesSubscriptionRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(const NotesLoading());
    await _subscription?.cancel();

    final completer = Completer<void>();
    _subscription = dataSource.streamNotes(event.userId).listen(
      (notes) {
        if (!isClosed) add(_NotesUpdated(notes));
        if (!completer.isCompleted) completer.complete();
      },
      onError: (error) {
        if (!isClosed) add(_NotesStreamFailed(error.toString()));
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  void _onNotesUpdated(_NotesUpdated event, Emitter<NotesState> emit) {
    emit(NotesLoaded(event.notes));
  }

  Future<void> _onAddRequested(
    NoteAddRequested event,
    Emitter<NotesState> emit,
  ) async {
    if (event.title.trim().isEmpty) {
      emit(const NotesError('Title is mandatory'));
      return;
    }
    final current = state;
    if (current is NotesLoaded) {
      emit(current.copyWith(isMutating: true));
    }
    try {
      await dataSource.addNote(
        userId: event.userId,
        title: event.title.trim(),
        description: event.description.trim(),
      );
      final latest = state is NotesLoaded
          ? (state as NotesLoaded).notes
          : <NoteModel>[];
      emit(NotesActionSuccess('Note added', latest));
    } catch (e) {
      emit(NotesError('Failed to add note: $e'));
    }
  }

    Future<void> _onUnsubscribeRequested(
    NotesUnsubscribeRequested event,
    Emitter<NotesState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onUpdateRequested(
    NoteUpdateRequested event,
    Emitter<NotesState> emit,
  ) async {
    if (event.title.trim().isEmpty) {
      emit(const NotesError('Title is mandatory'));
      return;
    }
    final current = state;
    if (current is NotesLoaded) {
      emit(current.copyWith(isMutating: true));
    }
    try {
      await dataSource.updateNote(
        noteId: event.noteId,
        title: event.title.trim(),
        description: event.description.trim(),
      );
      final latest = state is NotesLoaded
          ? (state as NotesLoaded).notes
          : <NoteModel>[];
      emit(NotesActionSuccess('Note updated', latest));
    } catch (e) {
      emit(NotesError('Failed to update note: $e'));
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<NotesState> emit,
  ) async {
    final current = state;
    if (current is NotesLoaded) {
      emit(current.copyWith(isMutating: true));
    }
    try {
      await dataSource.deleteNote(event.noteId);
      final latest = state is NotesLoaded
          ? (state as NotesLoaded).notes
          : <NoteModel>[];
      emit(NotesActionSuccess('Note deleted', latest));
    } catch (e) {
      emit(NotesError('Failed to delete note: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
