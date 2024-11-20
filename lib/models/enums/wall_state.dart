enum WallState {
  active,
  removed;

  int get value {
    switch (this) {
      case WallState.active:
        return 0;
      case WallState.removed:
        return 1;
      default:
        throw UnimplementedError();
    }
  }

  static WallState fromValue(int value) {
    switch (value) {
      case 0:
        return WallState.active;
      case 1:
        return WallState.removed;
      default:
        throw UnimplementedError();
    }
  }
}
