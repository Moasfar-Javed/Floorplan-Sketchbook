enum EntityInstance {
  moisturePoint,
  equipment,
  window,
  door,
  dragHandle,
  wall,
  internalWall;

  int get value {
    switch (this) {
      case EntityInstance.moisturePoint:
        return 0;
      case EntityInstance.equipment:
        return 1;
      case EntityInstance.window:
        return 2;
      case EntityInstance.door:
        return 3;
      case EntityInstance.dragHandle:
        return 4;
      case EntityInstance.wall:
        return 5;
      case EntityInstance.internalWall:
        return 6;
      default:
        throw UnimplementedError();
    }
  }

  static EntityInstance fromValue(int value) {
    switch (value) {
      case 0:
        return EntityInstance.moisturePoint;
      case 1:
        return EntityInstance.equipment;
      case 2:
        return EntityInstance.window;
      case 3:
        return EntityInstance.door;
      case 4:
        return EntityInstance.dragHandle;
      case 5:
        return EntityInstance.wall;
      case 6:
        return EntityInstance.internalWall;
      default:
        throw UnimplementedError();
    }
  }
}
