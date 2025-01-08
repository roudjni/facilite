class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() {
    return "DatabaseException: $message";
  }
}

class InsertException extends DatabaseException {
  InsertException(String message) : super(message);
}

class UpdateException extends DatabaseException {
  UpdateException(String message) : super(message);
}

class DeleteException extends DatabaseException {
  DeleteException(String message) : super(message);
}

class QueryException extends DatabaseException {
  QueryException(String message) : super(message);
}