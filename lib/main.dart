import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sketchbook/file_util.dart';
import 'package:sketchbook/models/entities/door.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/equipment.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/moisture_point.dart';
import 'package:sketchbook/models/entities/window.dart';
import 'package:sketchbook/models/enums/handle_type.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
import 'package:sketchbook/models/enums/unit.dart';
import 'package:sketchbook/models/enums/wall_state.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/painters/base_painter.dart';
import 'package:sketchbook/painters/icon_painter.dart';
import 'package:sketchbook/painters/unit_painter.dart';
import 'package:sketchbook/sketch_helpers.dart';
import 'package:undo_redo/undo_redo.dart';
import 'package:uuid/uuid.dart';

const cellSizeUnitPx = 20.0;
const oneCellToInches = 5; // one cell is 5 inches

const Uuid _uuid = Uuid();

String generateGuid() {
  var id = _uuid.v4();
  return id;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketchbook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Size canvasSize;
  late Grid grid;
  final TransformationController _transformationController =
      TransformationController();
  final UndoRedoManager<Grid> _undoRedoManager = UndoRedoManager<Grid>();

  bool initialized = false;
  Entity? selectedEntity;
  ui.Image? loadedDoorAsset,
      loadedActiveDoorAsset,
      loadedEquipmentAsset,
      loadedActiveEquipmentAsset,
      loadedMPAsset,
      loadedActiveMPAsset,
      loadedDragHandle,
      loadedWallDragHandle;

  bool showUnits = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    if (!initialized) {
      initialized = true;
      canvasSize = const Size(2000, 2000);
      grid = Grid(
        width: canvasSize.width,
        height: canvasSize.height,
        cellSize: cellSizeUnitPx,
      );

      SketchHelpers.generateInitialSquare(grid, canvasSize);
      SketchHelpers.centerCanvas(
        canvasSize,
        context,
        _animationController,
        _transformationController,
        animate: false,
      );
      await _loadHandles();
      _undoRedoManager.initialize(grid.clone());
    }

    super.didChangeDependencies();
  }

  // DON'T PASS IN ASYNC ACTIONS
  // this is to ensure setState isn't called after the state has been disposed
  setGridState(Function action) {
    action();
    _undoRedoManager.captureState(grid.clone());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                var childWasTappedAt = _transformationController.toScene(
                  details.localPosition,
                );
                selectedEntity =
                    SketchHelpers.getEntityAtPosition(childWasTappedAt, grid);
                setState(() {});
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                panEnabled: selectedEntity == null,
                scaleEnabled: selectedEntity == null,
                minScale: 0.5,
                onInteractionUpdate: (details) =>
                    _handleInteractionUpdate(details),
                onInteractionEnd: (details) {
                  if (selectedEntity != null) {
                    if (selectedEntity is InternalWall) {
                      // snap to the closest wall here
                      // and make sure it's perpendicular to it
                      _handleInternalWallSnapping(details);
                    }

                    setGridState(() {
                      // grid.snapEntityToGrid(selectedEntity!);
                    });
                  }
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      size: canvasSize,
                      painter: BasePainter(
                        grid: grid,
                        selectedEntity: selectedEntity,
                      ),
                    ),
                    if (showUnits)
                      CustomPaint(
                        size: canvasSize,
                        painter: UnitPainter(
                          unit: grid.unit,
                          walls: grid.entities.whereType<Wall>().toList(),
                          internalWalls:
                              grid.entities.whereType<InternalWall>().toList(),
                        ),
                      ),
                    _buildOverlayIcon()
                  ],
                ),
              ),
            ),
            _buildContextButtons(),
            _buildOptionsWidget(),
          ],
        ),
      ),
    );
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle) {
        _handleDragHandleInteraction(details);
      }
      // else if (selectedEntity is InternalWall) {
      //   _handleInternalWallInteraction(details);
      // }
      else {
        selectedEntity?.move(
          details.focalPointDelta.dx,
          details.focalPointDelta.dy,
        );
      }
      setState(() {});
    }
  }

  void _handleDragHandleInteraction(ScaleUpdateDetails details) {
    DragHandle handle = selectedEntity as DragHandle;
    List<Offset> offsetsToMatch = [];
    double minWallLength = 20;
    final commonWalls = grid.entities
        .whereType<Wall>()
        .where((e) => e.handleA.isEqual(handle) || e.handleB.isEqual(handle))
        .toList();

    for (final wall in commonWalls) {
      final complementingHandle =
          wall.handleA.isEqual(handle) ? wall.handleB : wall.handleA;
      offsetsToMatch.add(Offset(complementingHandle.x, complementingHandle.y));
    }

    // Proposed new position of the handle
    final proposedX = selectedEntity!.x + details.focalPointDelta.dx;
    final proposedY = selectedEntity!.y + details.focalPointDelta.dy;

    bool isMovementValid = true;

    for (final offset in offsetsToMatch) {
      final distance = (Offset(proposedX, proposedY) - offset).distance;
      if (distance < minWallLength) {
        isMovementValid = false;
        break;
      }
    }

    if (isMovementValid) {
      final snappingOffset = SketchHelpers.findExactPerpendicularOffset(
          Offset(proposedX, proposedY), offsetsToMatch);

      if (snappingOffset != null) {
        selectedEntity?.snap(
          snappingOffset.dx,
          snappingOffset.dy,
        );
      } else {
        selectedEntity?.move(
          details.focalPointDelta.dx,
          details.focalPointDelta.dy,
        );
      }
    } else {
      // movement is restricted, add a feedback
    }
  }

  void _handleInternalWallSnapping(ScaleEndDetails details) {
    final internalWall = selectedEntity as InternalWall;
    List<Wall> walls = grid.entities.whereType<Wall>().toList();
    Wall? closestWall;
    DragHandle? closeInternalWallHandle;
    DragHandle? farInternalWallHandle;
    double minDistance = double.infinity;
    double targetLength = internalWall.length;

    // Find the closest wall and handles
    for (Wall wall in walls) {
      double distance = inWallDistanceFromWall(internalWall, wall);

      if (distance < minDistance) {
        minDistance = distance;
        closestWall = wall;

        double distanceToHandleA =
            handleDistanceFromWall(internalWall.handleA, wall);
        double distanceToHandleB =
            handleDistanceFromWall(internalWall.handleB, wall);

        closeInternalWallHandle = (distanceToHandleA < distanceToHandleB)
            ? internalWall.handleA
            : internalWall.handleB;

        farInternalWallHandle = (distanceToHandleA > distanceToHandleB)
            ? internalWall.handleA
            : internalWall.handleB;
      }
    }

    if (farInternalWallHandle == null ||
        closeInternalWallHandle == null ||
        closestWall == null) {
      return;
    }

    print('before length: ${internalWall.length}');
    print('before angle: ${angleBetweenWalls(internalWall, closestWall)}');
    Offset closestPoint =
        _findClosestPointOnWall(closeInternalWallHandle, closestWall);

    // Move the closest internal wall handle to the closest point
    closeInternalWallHandle.setPosition(closestPoint.dx, closestPoint.dy);

    // Calculate the vector between the two handles (dx, dy)
    double dx = farInternalWallHandle.x - closeInternalWallHandle.x;
    double dy = farInternalWallHandle.y - closeInternalWallHandle.y;

    // Calculate the current distance between the two handles
    double currentDistance = sqrt(dx * dx + dy * dy);

    // Preserve the length of the internal wall
    double scaleFactor = targetLength / currentDistance;

    // Calculate the angle between the two handles (in radians)
    double angle = atan2(dy, dx);

    // Calculate the new position for the far handle using the scaling factor
    double newFarHandleX =
        closeInternalWallHandle.x + cos(angle) * targetLength;
    double newFarHandleY =
        closeInternalWallHandle.y + sin(angle) * targetLength;

    // Move the far handle to the new position
    farInternalWallHandle.setPosition(newFarHandleX, newFarHandleY);

    // Debug output for after calculations
    print('after length: ${internalWall.length}');
    print('after angle: ${angleBetweenWalls(internalWall, closestWall)}');
  }

  Offset _findClosestPointOnWall(DragHandle dragHandle, Wall wall) {
    // Get the two handles of the wall
    Offset wallHandleA = Offset(wall.handleA.x, wall.handleA.y);
    Offset wallHandleB = Offset(wall.handleB.x, wall.handleB.y);

    // Calculate the vector from wallHandleA to wallHandleB
    Offset wallVector = wallHandleB - wallHandleA;

    // Calculate the vector from wallHandleA to the dragHandle
    Offset dragVector = Offset(dragHandle.x, dragHandle.y) - wallHandleA;

    // Project dragVector onto wallVector (perpendicular projection)
    double projection =
        (dragVector.dx * wallVector.dx + dragVector.dy * wallVector.dy) /
            (wallVector.dx * wallVector.dx + wallVector.dy * wallVector.dy);

    // Clamp the projection to ensure it falls within the line segment [wallHandleA, wallHandleB]
    projection = projection.clamp(0.0, 1.0);

    // Find the closest point on the wall
    Offset closestPoint = wallHandleA + (wallVector * projection);

    return closestPoint;
  }

  double angleBetweenWalls(InternalWall internalWall, Wall wall) {
    // Get the coordinates of the handles for both the internal wall and the wall
    double x1 = internalWall.handleA.x;
    double y1 = internalWall.handleA.y;
    double x2 = internalWall.handleB.x;
    double y2 = internalWall.handleB.y;
    double x3 = wall.handleA.x;
    double y3 = wall.handleA.y;
    double x4 = wall.handleB.x;
    double y4 = wall.handleB.y;

    // Compute the vectors for both wall segments
    double dx1 = x2 - x1;
    double dy1 = y2 - y1;
    double dx2 = x4 - x3;
    double dy2 = y4 - y3;

    // Compute the dot product and magnitudes of the vectors
    double dotProduct = dx1 * dx2 + dy1 * dy2;
    double magnitude1 = sqrt(dx1 * dx1 + dy1 * dy1);
    double magnitude2 = sqrt(dx2 * dx2 + dy2 * dy2);

    // Calculate the cosine of the angle between the two vectors
    double cosAngle = dotProduct / (magnitude1 * magnitude2);

    // Ensure that the cosine value is within the valid range for acos
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    // Calculate the angle in radians and convert to degrees
    double angleInRadians = acos(cosAngle);
    double angleInDegrees = angleInRadians * 180 / pi;

    return angleInDegrees;
  }

  double handleDistanceFromWall(DragHandle dragHandle, Wall wall) {
    // Get the two handles of the wall
    Offset wallHandleA = Offset(wall.handleA.x, wall.handleA.y);
    Offset wallHandleB = Offset(wall.handleB.x, wall.handleB.y);

    // Get the position of the dragHandle
    Offset dragPosition = Offset(dragHandle.x, dragHandle.y);

    // Function to calculate the distance from the dragHandle to the wall
    double calculateDistanceFromWall(
        Offset handle, Offset wallA, Offset wallB) {
      // Calculate the vector from wallA to wallB (direction of the wall)
      Offset wallVector = wallB - wallA;
      // Calculate the vector from wallA to the handle
      Offset handleVector = handle - wallA;

      // Project handleVector onto wallVector (perpendicular projection)
      double projection =
          (handleVector.dx * wallVector.dx + handleVector.dy * wallVector.dy) /
              (wallVector.dx * wallVector.dx + wallVector.dy * wallVector.dy);

      // Clamp the projection to ensure it falls within the line segment [wallA, wallB]
      projection = projection.clamp(0.0, 1.0);

      // Find the closest point on the wall
      Offset closestPoint = wallA + (wallVector * projection);

      // Return the distance from the handle to the closest point on the wall
      return (handle - closestPoint).distance;
    }

    // Calculate and return the distance from the dragHandle to the wall
    return calculateDistanceFromWall(dragPosition, wallHandleA, wallHandleB);
  }

  double inWallDistanceFromWall(InternalWall internalWall, Wall wall) {
    // Get the coordinates of the handles for both the internal wall and the wall
    double x1 = internalWall.handleA.x;
    double y1 = internalWall.handleA.y;
    double x2 = internalWall.handleB.x;
    double y2 = internalWall.handleB.y;
    double x3 = wall.handleA.x;
    double y3 = wall.handleA.y;
    double x4 = wall.handleB.x;
    double y4 = wall.handleB.y;

    // Compute the vectors for the lines of both wall segments
    double dx1 = x2 - x1;
    double dy1 = y2 - y1;
    double dx2 = x4 - x3;
    double dy2 = y4 - y3;

    // Calculate the determinant to check if the lines are parallel
    double determinant = dx1 * dy2 - dy1 * dx2;

    if (determinant == 0) {
      // The lines are parallel, so we compute the perpendicular distance from one segment to the other
      return _distanceToLine(x1, y1, x3, y3, x4, y4);
    } else {
      // The lines are not parallel, compute the intersection point and the distance
      double t1 = ((x3 - x1) * dy2 - (y3 - y1) * dx2) / determinant;
      double t2 = ((x3 - x1) * dy1 - (y3 - y1) * dx1) / determinant;

      // If t1 and t2 are between 0 and 1, there is an intersection within the line segments
      if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
        // If the intersection is within the bounds, return 0 (there's no need for distance calculation)
        return 0;
      } else {
        // If there's no intersection within the bounds, return the minimum distance from the endpoints
        return _minDistanceToEndpoints(x1, y1, x2, y2, x3, y3, x4, y4);
      }
    }
  }

// Function to calculate the perpendicular distance from a point to a line
  double _distanceToLine(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    // Distance from point (x1, y1) to the line segment (x2, y2) - (x3, y3)
    return ((y3 - y2) * x1 - (x3 - x2) * y1 + x3 * y2 - y3 * x2).abs() /
        sqrt(pow(y3 - y2, 2) + pow(x3 - x2, 2));
  }

// Function to calculate the minimum distance between two line segments (endpoints)
  double _minDistanceToEndpoints(double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4) {
    // Distance from a point to a line
    double dist1 = _distanceToLine(x1, y1, x3, y3, x4, y4);
    double dist2 = _distanceToLine(x2, y2, x3, y3, x4, y4);
    double dist3 = _distanceToLine(x3, y3, x1, y1, x2, y2);
    double dist4 = _distanceToLine(x4, y4, x1, y1, x2, y2);

    // Return the minimum of these distances
    return [dist1, dist2, dist3, dist4].reduce((a, b) => a < b ? a : b);
  }

  // void _handleInternalWallInteraction(ScaleUpdateDetails details) {
  //   final internalWall = selectedEntity as InternalWall;
  //   List<Wall> walls = grid.entities.whereType<Wall>().toList();

  //   // Loop through all walls to find the one closest to the internal wall
  //   Wall? closestWall;
  //   double minDistance = double.infinity;

  //   for (Wall wall in walls) {
  //     // Find the closest distance from internalWall to the current wall
  //     double distance = distanceFromWall(internalWall, wall);
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closestWall = wall;
  //     }
  //   }

  //   if (closestWall != null) {
  //     // Calculate the perpendicular direction to the closest wall
  //     final perpendicularDirection =
  //         getPerpendicularDirectionVector(closestWall);

  //     // Project the movement of the internal wall along the perpendicular direction
  //     double deltaX = details.localFocalPoint.dx;
  //     double deltaY = details.localFocalPoint.dy;

  //     final double projection = deltaX * perpendicularDirection.dx +
  //         deltaY * perpendicularDirection.dy;
  //     final double projectedDeltaX = projection * perpendicularDirection.dx;
  //     final double projectedDeltaY = projection * perpendicularDirection.dy;

  //     // Move the internal wall based on the projected deltas
  //     internalWall.move(projectedDeltaX, projectedDeltaY);
  //   }
  // }

  // void _handleInternalWallInteraction(ScaleUpdateDetails details) {
  //   final internalWall = selectedEntity as InternalWall;
  //   List<Wall> walls = grid.entities.whereType<Wall>().toList();
  //   Wall? closestWall;
  //   DragHandle? closestHandle;

  //   double snapThreshold = 20.0;

  //   // check for proximity of the internal wall's handles to other walls
  //   for (Wall wall in walls) {
  //     double distanceToHandleA = SketchHelpers.distanceToLine(
  //       Offset(internalWall.handleA.x, internalWall.handleA.y),
  //       Offset(wall.handleA.x, wall.handleA.y),
  //       Offset(wall.handleB.x, wall.handleB.y),
  //     );
  //     double distanceToHandleB = SketchHelpers.distanceToLine(
  //       Offset(internalWall.handleB.x, internalWall.handleB.y),
  //       Offset(wall.handleA.x, wall.handleA.y),
  //       Offset(wall.handleB.x, wall.handleB.y),
  //     );

  //     double minDistanceToWall = distanceToHandleA < distanceToHandleB
  //         ? distanceToHandleA
  //         : distanceToHandleB;

  //     if (minDistanceToWall < snapThreshold) {
  //       // Snap the internal wall to the new wall
  //       print("jumping to a new wall");
  //       closestWall = wall;
  //       closestHandle = (distanceToHandleA < distanceToHandleB)
  //           ? wall.handleA
  //           : wall.handleB;

  //       break;
  //     }
  //   }

  //   // If no closest wall is found, do not move
  //   if (closestWall == null || closestHandle == null) return;

  //   Offset wallDirection = Offset(
  //     closestWall.handleB.x - closestWall.handleA.x,
  //     closestWall.handleB.y - closestWall.handleA.y,
  //   );

  //   // Normalize the direction vector
  //   double wallLength = wallDirection.distance;
  //   Offset unitDirection = Offset(
  //     wallDirection.dx / wallLength,
  //     wallDirection.dy / wallLength,
  //   );

  //   // Project the movement delta onto the wall's direction vector
  //   double deltaX = details.focalPointDelta.dx;
  //   double deltaY = details.focalPointDelta.dy;

  //   double projectionLength =
  //       deltaX * unitDirection.dx + deltaY * unitDirection.dy;

  //   Offset projectedDelta = Offset(
  //     projectionLength * unitDirection.dx,
  //     projectionLength * unitDirection.dy,
  //   );

  //   internalWall.move(projectedDelta.dx, projectedDelta.dy);
  // }

  Widget _buildOptionsWidget() {
    return Positioned(
      top: 80,
      left: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  visualDensity: VisualDensity.compact,
                  color: _undoRedoManager.canUndo()
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  onPressed: () {
                    final res = _undoRedoManager.undo();
                    if (res != null) {
                      grid = res.clone();
                      selectedEntity = null;
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.redo),
                  visualDensity: VisualDensity.compact,
                  color: _undoRedoManager.canRedo()
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  onPressed: () {
                    final res = _undoRedoManager.redo();
                    if (res != null) {
                      grid = res.clone();
                      selectedEntity = null;
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              if (grid.unit == Unit.inches) {
                grid.unit = Unit.feetAndInches;
              } else if (grid.unit == Unit.feetAndInches) {
                grid.unit = Unit.metric;
              } else {
                grid.unit = Unit.inches;
              }
              setState(() {});
            },
            child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    grid.unit == Unit.feetAndInches
                        ? "1'1\""
                        : grid.unit == Unit.inches
                            ? "1\""
                            : "1m",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHandles() async {
    loadedDragHandle ??=
        await SketchHelpers.loadImage('assets/drag_handle.png');
    loadedWallDragHandle ??=
        await SketchHelpers.loadImage('assets/wall_move_handle.png');
  }

  Widget _buildOverlayIcon() {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle) {
        return CustomPaint(
          size: canvasSize,
          painter: IconPainter(
            position: Offset(selectedEntity?.x ?? 0, selectedEntity?.y ?? 0),
            image: loadedDragHandle!,
          ),
        );
      } else if (selectedEntity is Wall) {
        return CustomPaint(
          size: canvasSize,
          painter: IconPainter(
            position: Wall.getCenter(selectedEntity),
            image: loadedWallDragHandle!,
            rotationAngle: Wall.getAngle(selectedEntity as Wall),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildContextButtons() {
//----------
//DEFAULT
//----------
    if (selectedEntity == null) {
      return Row(
        children: [
          TextButton(
            child: const Text('Center'),
            onPressed: () {
              SketchHelpers.centerCanvas(
                canvasSize,
                context,
                _animationController,
                _transformationController,
              );
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Fit to View'),
            onPressed: () {
              SketchHelpers.fitDragHandles(
                context,
                grid,
                _animationController,
                _transformationController,
              );
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              await FileUtil.saveFile(jsonEncode(grid.toJson()));
            },
          ),
          TextButton(
            child: const Text('Load Saved'),
            onPressed: () async {
              final jsonData = jsonDecode(await FileUtil.readFile());
              loadedDoorAsset = loadedDoorAsset ??
                  await SketchHelpers.loadImage('assets/door.png');
              loadedActiveDoorAsset = loadedActiveDoorAsset ??
                  await SketchHelpers.loadImage('assets/door_active.png');
              loadedMPAsset = loadedMPAsset ??
                  await SketchHelpers.loadImage('assets/moisture.png');
              loadedActiveMPAsset = loadedActiveMPAsset ??
                  await SketchHelpers.loadImage('assets/moisture_active.png');
              loadedEquipmentAsset = loadedEquipmentAsset ??
                  await SketchHelpers.loadImage('assets/equipment.png');
              loadedActiveEquipmentAsset = loadedActiveEquipmentAsset ??
                  await SketchHelpers.loadImage('assets/equipment_active.png');
              grid = Grid.fromJson(
                jsonData,
                loadedDoorAsset!,
                loadedActiveDoorAsset!,
                loadedMPAsset!,
                loadedActiveMPAsset!,
                loadedEquipmentAsset!,
                loadedActiveEquipmentAsset!,
              );

              setState(() {});
              if (mounted) {
                SketchHelpers.fitDragHandles(context, grid,
                    _animationController, _transformationController);
              }
              _undoRedoManager.initialize(grid.clone());
            },
          ),
          TextButton(
            child: Text(showUnits ? 'Units Off' : 'Units On'),
            onPressed: () async {
              setState(() {
                showUnits = !showUnits;
              });
            },
          ),
        ],
      );
    }
//----------
//WALL
//----------
    if (selectedEntity is Wall) {
      final wall = selectedEntity as Wall;
      return Row(
        children: [
          if (wall.wallState == WallState.active)
            TextButton(
              child: const Text('Add a Point'),
              onPressed: () {
                setGridState(() {
                  var childWalls = wall.split(wall);
                  grid.removeEntity(wall);
                  grid.addEntity(childWalls.$1);
                  grid.addEntity(childWalls.$2);
                  // grid.snapEntityToGrid(childWalls.$1);
                  // grid.snapEntityToGrid(childWalls.$2);
                  selectedEntity = null;
                });
              },
            ),
          if (wall.wallState == WallState.active)
            TextButton(
              child: const Text('Open Wall'),
              onPressed: () {
                setGridState(() {
                  wall.wallState = WallState.removed;
                });
              },
            ),
          if (wall.wallState == WallState.removed)
            TextButton(
              child: const Text('Close Wall'),
              onPressed: () {
                setGridState(() {
                  wall.wallState = WallState.active;
                });
              },
            ),
        ],
      );
    }
//----------
//DRAG HANDLE
//----------
    else if (selectedEntity is DragHandle &&
        (selectedEntity as DragHandle).parentEntity == ParentEntity.wall &&
        grid.entities.whereType<Wall>().toList().length > 3) {
      final handle = selectedEntity as DragHandle;
      return Row(
        children: [
          TextButton(
            child: const Text('Remove Point'),
            onPressed: () {
              setGridState(() {
                final walls = grid.entities
                    .where((e) =>
                        e is Wall &&
                        ((e).handleA.isEqual(handle) ||
                            (e).handleB.isEqual(handle)))
                    .cast<Wall>()
                    .toList();
                final newCommonHandle = walls.first.handleA.isEqual(handle)
                    ? walls.first.handleB
                    : walls.first.handleA;
                walls.last.replaceHandle(handle, newCommonHandle);
                grid.removeEntity(walls.first);
                selectedEntity = null;
              });
            },
          ),
        ],
      );
    }
//----------
//INTERNAL WALL
//----------
    else if (selectedEntity is InternalWall) {
      final inWall = selectedEntity as InternalWall;
      return Row(
        children: [
          TextButton(
            child: const Text('Remove Wall'),
            onPressed: () {
              setGridState(() {
                grid.removeEntity(inWall);
                selectedEntity = null;
              });
            },
          ),
        ],
      );
    }
//----------
//DOOR
//----------
    else if (selectedEntity is Door) {
      final door = selectedEntity as Door;
      return Row(
        children: [
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              setGridState(() {
                grid.removeEntity(door);
                selectedEntity = null;
              });
            },
          ),
          TextButton(
            child: const Text('Rotate Right'),
            onPressed: () {
              setGridState(() {
                door.rotateClockwise();
              });
            },
          ),
          TextButton(
            child: const Text('Rotate Left'),
            onPressed: () {
              setGridState(() {
                door.rotateCounterclockwise();
              });
            },
          ),
        ],
      );
    }
//----------
//WINDOW
//----------
    else if (selectedEntity is Window) {
      final window = selectedEntity as Window;
      return Row(
        children: [
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              setGridState(() {
                grid.removeEntity(window);
                selectedEntity = null;
              });
            },
          ),
          TextButton(
            child: const Text('Snap to Closest Wall'),
            onPressed: () {
              setGridState(() {
                // TODO: Optimize later, the double call is a bandaid solution for a misalighnment problem
                (selectedEntity as Window).snapToClosestWall(
                    grid.entities.whereType<Wall>().toList());
                (selectedEntity as Window).snapToClosestWall(
                    grid.entities.whereType<Wall>().toList());
              });
            },
          ),
        ],
      );
    }
//----------
//EQUIPMENT
//----------
    else if (selectedEntity is Equipment) {
      final equipment = selectedEntity as Equipment;
      return Row(
        children: [
          TextButton(
            child: const Text('Change Value'),
            onPressed: () async {
              final newVal = await showInputDialog(context, equipment.label);
              setGridState(() {
                equipment.updateValue(newVal);
              });
            },
          ),
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              setGridState(() {
                grid.removeEntity(equipment);
                selectedEntity = null;
              });
            },
          ),
        ],
      );
    }
//----------
//MOISTURE POINT
//----------
    else if (selectedEntity is MoisturePoint) {
      final mp = selectedEntity as MoisturePoint;
      return Row(
        children: [
          TextButton(
            child: const Text('Change Value'),
            onPressed: () async {
              final newVal = await showInputDialog(context, mp.label);
              setGridState(() {
                mp.updateValue(newVal);
              });
            },
          ),
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              setGridState(() {
                grid.removeEntity(mp);
                selectedEntity = null;
              });
            },
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    noWallMessage() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a wall to add this")));
    return BottomNavigationBar(
      fixedColor: Colors.black,
      unselectedItemColor: Colors.black,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      iconSize: 15,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'In-Wall'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Door'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Window'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Equipment'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'M-Point'),
      ],
      onTap: (value) async {
        if (value == 0) {
          if (selectedEntity is! Wall) {
            noWallMessage();
            return;
          }
          Wall wall = selectedEntity as Wall;
          Offset center = Wall.getCenter(wall);

          Offset perpVector = Wall.getPerpendicularDirectionVector(wall);

          // normalize vector to unit length
          double vectorLength = sqrt(
              perpVector.dx * perpVector.dx + perpVector.dy * perpVector.dy);
          Offset unitVector = Offset(
              perpVector.dx / vectorLength, perpVector.dy / vectorLength);

          const double handleOffset = 80.0; //length

          Offset handleAOffset = center;
          Offset handleBOffset = Offset(
            center.dx + unitVector.dx * handleOffset,
            center.dy + unitVector.dy * handleOffset,
          );

          setGridState(() {
            final inWall = InternalWall(
              id: generateGuid(),
              thickness: 10,
              handleA: DragHandle(
                id: generateGuid(),
                x: handleAOffset.dx,
                y: handleAOffset.dy,
                parentEntity: ParentEntity.internalWall,
                handleType: HandleType.transparent,
              ),
              handleB: DragHandle(
                id: generateGuid(),
                x: handleBOffset.dx,
                y: handleBOffset.dy,
                parentEntity: ParentEntity.internalWall,
                handleType: HandleType.transparent,
              ),
            );
            grid.addEntity(inWall);
            selectedEntity = inWall;
          });
        } else if (value == 1) {
          if (selectedEntity is! Wall) {
            noWallMessage();
            return;
          }
          final wall = (selectedEntity as Wall);
          final wallCenter = Wall.getCenter(wall);
          final wallAngle = Wall.getAngle(wall);
          loadedDoorAsset = loadedDoorAsset ??
              await SketchHelpers.loadImage('assets/door.png');
          loadedActiveDoorAsset = loadedActiveDoorAsset ??
              await SketchHelpers.loadImage('assets/door_active.png');
          setGridState(() {
            final door = Door(
              id: generateGuid(),
              x: wallCenter.dx,
              y: wallCenter.dy,
              rotation: wallAngle,
              doorAsset: loadedDoorAsset!,
              doorActiveAsset: loadedActiveDoorAsset!,
            );
            grid.addEntity(door);
            selectedEntity = door;
          });
        } else if (value == 2) {
          if (selectedEntity is! Wall) {
            noWallMessage();
            return;
          }
          setGridState(() {
            final window = Window(
              id: generateGuid(),
              thickness: 15,
              handleA: DragHandle(
                id: generateGuid(),
                x: canvasSize.width / 2,
                y: canvasSize.height / 2,
                parentEntity: ParentEntity.window,
                handleType: HandleType.transparent,
              ),
              handleB: DragHandle(
                id: generateGuid(),
                x: canvasSize.width / 2,
                y: canvasSize.height / 2 + 40,
                parentEntity: ParentEntity.window,
                handleType: HandleType.transparent,
              ),
            );
            grid.addEntity(window);

            selectedEntity = window;
          });
        } else if (value == 3) {
          loadedEquipmentAsset = loadedEquipmentAsset ??
              await SketchHelpers.loadImage('assets/equipment.png');
          loadedActiveEquipmentAsset = loadedActiveEquipmentAsset ??
              await SketchHelpers.loadImage('assets/equipment_active.png');
          setGridState(() {
            final equipment = Equipment(
              label: '2',
              id: generateGuid(),
              x: canvasSize.width / 2,
              y: canvasSize.height / 2,
              equipmentAsset: loadedEquipmentAsset!,
              activeEquipmentAsset: loadedActiveEquipmentAsset!,
            );
            grid.addEntity(equipment);

            selectedEntity = equipment;
          });
        } else if (value == 4) {
          loadedMPAsset = loadedMPAsset ??
              await SketchHelpers.loadImage('assets/moisture.png');
          loadedActiveMPAsset = loadedActiveMPAsset ??
              await SketchHelpers.loadImage('assets/moisture_active.png');
          setGridState(() {
            final equipment = Equipment(
              label: '2',
              id: generateGuid(),
              x: canvasSize.width / 2,
              y: canvasSize.height / 2,
              equipmentAsset: loadedMPAsset!,
              activeEquipmentAsset: loadedActiveMPAsset!,
            );
            grid.addEntity(equipment);

            selectedEntity = equipment;
          });
        }
      },
    );
  }
}

Future<String?> showInputDialog(BuildContext context, String? preValue) async {
  TextEditingController textController =
      TextEditingController(text: preValue ?? '');

  String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter Value'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Type here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(textController.text);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  return result;
}
