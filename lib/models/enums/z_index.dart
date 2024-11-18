// Higher means higher on the layer
enum ZIndex {
  moisturePoint(6),
  equipment(6),
  window(5),
  door(4),
  dragHandle(3),
  wall(2),
  internalWall(1);

  final int value;

  const ZIndex(this.value);
}
