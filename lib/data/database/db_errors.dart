import 'dart:async';

import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/foundation.dart';
import 'package:traccash/core/errors/app_error.dart';

/// SQLite extended result codes for the constraints the schema declares.
abstract final class SqliteConstraint {
  static const int check = 275;

  /// A row points at a parent that doesn't exist.
  static const int foreignKey = 787;

  /// ON DELETE RESTRICT blocked deleting a parent. SQLite enforces RESTRICT
  /// like a trigger, so it reports this code rather than [foreignKey].
  static const int restrict = 1811;

  static const int unique = 2067;
}

/// Turns a constraint code into the error the caller expects, or null to
/// report a generic [StorageError].
typedef ConstraintTranslator = AppError? Function(int extendedCode);

/// Runs [action] and lets only [AppError]s escape.
///
/// Validation runs before every write, so a constraint failure here usually
/// means a bug or a race. [translate] names the ones a caller can explain.
Future<T> guardDb<T>(
  Future<T> Function() action, {
  ConstraintTranslator? translate,
}) async {
  try {
    return await action();
  } on AppError {
    rethrow;
  } on Exception catch (error, stackTrace) {
    Error.throwWithStackTrace(toAppError(error, translate), stackTrace);
  }
}

/// [stream] with database exceptions replaced by [AppError]s, so screens
/// receive the same typed errors from reads as from writes.
Stream<T> guardDbStream<T>(Stream<T> stream) {
  return stream.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        // Errors (as opposed to Exceptions) are bugs; pass them on untouched.
        sink.addError(
          error is Exception ? toAppError(error) : error,
          stackTrace,
        );
      },
    ),
  );
}

/// Maps any exception from the database layer to an [AppError].
AppError toAppError(Exception error, [ConstraintTranslator? translate]) {
  if (error is AppError) return error;

  // drift_flutter runs SQLite on a background isolate, which wraps the
  // original exception.
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  final code = cause is SqliteException ? cause.extendedResultCode : null;

  if (kDebugMode) {
    // Type and code only: SQLite messages can quote the statement.
    debugPrint('Database error: ${cause.runtimeType} (code $code)');
  }

  if (code != null && translate != null) {
    final translated = translate(code);
    if (translated != null) return translated;
  }
  return const StorageError();
}
