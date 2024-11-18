// Higher means more on top
enum ZIndex {
  door(4),
  dragHandle(3),
  wall(2),
  internalWall(1);

  final int value;

  const ZIndex(this.value);
}
