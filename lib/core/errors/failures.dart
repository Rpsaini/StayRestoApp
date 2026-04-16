import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class EmptyResultsFailure extends Failure {
  const EmptyResultsFailure(super.message);
}
