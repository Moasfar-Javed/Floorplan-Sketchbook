enum HandleType {
  transparent,
  colored;

  int get value {
    switch (this) {
      case HandleType.transparent:
        return 0;
      case HandleType.colored:
        return 1;
      default:
        throw UnimplementedError();
    }
  }

  static HandleType fromValue(int value) {
    switch (value) {
      case 0:
        return HandleType.transparent;
      case 1:
        return HandleType.colored;
      default:
        throw UnimplementedError();
    }
  }
}
