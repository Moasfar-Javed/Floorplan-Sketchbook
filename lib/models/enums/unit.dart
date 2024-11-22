enum Unit {
  inches,
  feetAndInches,
  metric;

  int get value {
    switch (this) {
      case Unit.inches:
        return 0;
      case Unit.feetAndInches:
        return 1;
      case Unit.metric:
        return 2;
      default:
        throw UnimplementedError();
    }
  }

  static Unit fromValue(int value) {
    switch (value) {
      case 0:
        return Unit.inches;
      case 1:
        return Unit.feetAndInches;
      case 2:
        return Unit.metric;
      default:
        throw UnimplementedError();
    }
  }
}
