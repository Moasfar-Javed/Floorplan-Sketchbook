enum ParentEntity {
  window,
  internalWall,
  wall;

  int get value {
    switch (this) {
      case ParentEntity.window:
        return 0;
      case ParentEntity.internalWall:
        return 1;
      case ParentEntity.wall:
        return 2;
      default:
        throw UnimplementedError();
    }
  }

  static ParentEntity fromValue(int value) {
    switch (value) {
      case 0:
        return ParentEntity.window;
      case 1:
        return ParentEntity.internalWall;
      case 2:
        return ParentEntity.wall;
      default:
        throw UnimplementedError();
    }
  }
}
