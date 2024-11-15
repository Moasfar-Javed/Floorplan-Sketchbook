// Higher means more on top
enum ZIndex {
  wall(2),
  dragHandle(3),
  internalWall(1);

  final int value;

  const ZIndex(this.value);
}
