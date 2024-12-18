import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sketchbook/extensions.dart';
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

  double scaleFactor = 1;
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

    _animationController.addListener(() {
      if (_animationController.isAnimating ||
          _animationController.isCompleted) {
        _calculateScaleFactor();
      }
    });
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
                    bool isEntityWall = selectedEntity is Wall;
                    bool isEntityInWall = selectedEntity is InternalWall;
                    bool isEntityWallDragHandle =
                        selectedEntity is DragHandle &&
                            (selectedEntity as DragHandle).parentEntity ==
                                ParentEntity.wall;
                    bool isEntityInWallDragHandle =
                        selectedEntity is DragHandle &&
                            (selectedEntity as DragHandle).parentEntity ==
                                ParentEntity.internalWall;
                    bool isEntityWindowDragHandle =
                        selectedEntity is DragHandle &&
                            (selectedEntity as DragHandle).parentEntity ==
                                ParentEntity.window;
                    if (isEntityInWall) {
                      _handleInternalWallSnapping();
                    } else if (isEntityInWallDragHandle) {
                      _handleInternalWallSnapping(
                        selectedInWall: grid.entities
                            .whereType<InternalWall>()
                            .firstWhere(
                              (e) =>
                                  e.handleA
                                      .isEqual(selectedEntity as DragHandle) ||
                                  e.handleB
                                      .isEqual(selectedEntity as DragHandle),
                            ),
                      );
                    } else if (isEntityWall || isEntityWallDragHandle) {
                      for (var entity in grid.entities) {
                        if (entity is InternalWall) {
                          _handleInternalWallSnapping(selectedInWall: entity);
                        } else if (entity is Window) {
                          _handleWindowSnapping(selectedWindow: entity);
                        }
                      }
                    } else if (isEntityWindowDragHandle) {
                      _handleWindowSnapping(
                        selectedWindow: grid.entities
                            .whereType<Window>()
                            .firstWhere(
                              (e) =>
                                  e.handleA
                                      .isEqual(selectedEntity as DragHandle) ||
                                  e.handleB
                                      .isEqual(selectedEntity as DragHandle),
                            ),
                      );
                    }

                    setGridState(() {});
                  }
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      size: canvasSize,
                      painter: BasePainter(
                        scaleFactor: scaleFactor,
                        grid: grid,
                        selectedEntity: selectedEntity,
                      ),
                    ),
                    if (showUnits)
                      CustomPaint(
                        size: canvasSize,
                        painter: UnitPainter(
                          scaleFactor: scaleFactor,
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

  void _calculateScaleFactor() {
    setState(() {
      scaleFactor = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    _calculateScaleFactor();
    if (selectedEntity != null) {
      if (selectedEntity is Window) {
        _handleWindowMovement(details);
      } else if (selectedEntity is DragHandle) {
        _handleDragHandleInteraction(details);
      } else {
        selectedEntity?.move(
          details.focalPointDelta.dx,
          details.focalPointDelta.dy,
        );
      }
      setState(() {});
    }
  }

  void _handleWindowMovement(ScaleUpdateDetails details) {
    if (selectedEntity == null || selectedEntity is! Window) return;

    final window = selectedEntity as Window;
    double originalLength = window.length;
    Offset originalHandleA = window.handleA.position();
    Offset originalHandleB = window.handleB.position();
    Wall? parentWall;
    Path? wallsPath = SketchHelpers.getWallsPath(grid);
    if (wallsPath == null) return;

    // Find the parent wall
    for (var wall in grid.entities.whereType<Wall>()) {
      if (isOffsetInLine(
            window.handleA.position(),
            wall.handleA.position(),
            wall.handleB.position(),
          ) &&
          isOffsetInLine(
            window.handleB.position(),
            wall.handleA.position(),
            wall.handleB.position(),
          )) {
        parentWall = wall;
        break;
      }
    }

    if (parentWall == null) return;

    Offset movementDelta = details.focalPointDelta;

    // Move the window handles
    window.handleA.move(movementDelta.dx, movementDelta.dy);
    window.handleB.move(movementDelta.dx, movementDelta.dy);

    // Default behavior: Align to the wall
    window.handleA.move(movementDelta.dx, movementDelta.dy);
    window.handleB.move(movementDelta.dx, movementDelta.dy);

    Offset closestPointA = _getClosestPointOnWallSegment(
      window.handleA.position(),
      parentWall.handleA.position(),
      parentWall.handleB.position(),
    );
    Offset closestPointB = _getClosestPointOnWallSegment(
      window.handleB.position(),
      parentWall.handleA.position(),
      parentWall.handleB.position(),
    );

    window.handleA.setPosition(closestPointA.dx, closestPointA.dy);
    window.handleB.setPosition(closestPointB.dx, closestPointB.dy);

    if (window.length.toStringAsFixed(2) != originalLength.toStringAsFixed(2)) {
      // Revert if length changes
      window.handleA.setPosition(originalHandleA.dx, originalHandleA.dy);
      window.handleB.setPosition(originalHandleB.dx, originalHandleB.dy);
    }
  }

  bool isOffsetInLine(
      Offset targetOffset, Offset lineOffsetA, Offset lineOffsetB) {
    // Define a small tolerance to account for floating-point precision issues
    const double tolerance = 0.0001;

    // Calculate the distance from the target to the line segment
    double distance =
        _distanceFromPointToLine(targetOffset, lineOffsetA, lineOffsetB);

    // Check if the distance is within the tolerance
    if (distance > tolerance) {
      return false; // Target is not on the line
    }

    // Check if the target is within the bounds of the line segment
    double minX =
        lineOffsetA.dx < lineOffsetB.dx ? lineOffsetA.dx : lineOffsetB.dx;
    double maxX =
        lineOffsetA.dx > lineOffsetB.dx ? lineOffsetA.dx : lineOffsetB.dx;
    double minY =
        lineOffsetA.dy < lineOffsetB.dy ? lineOffsetA.dy : lineOffsetB.dy;
    double maxY =
        lineOffsetA.dy > lineOffsetB.dy ? lineOffsetA.dy : lineOffsetB.dy;

    return targetOffset.dx >= minX - tolerance &&
        targetOffset.dx <= maxX + tolerance &&
        targetOffset.dy >= minY - tolerance &&
        targetOffset.dy <= maxY + tolerance;
  }

  double _distanceFromPointToLine(
      Offset point, Offset lineStart, Offset lineEnd) {
    double dx = lineEnd.dx - lineStart.dx;
    double dy = lineEnd.dy - lineStart.dy;

    // Handle degenerate case where the line segment is a single point
    double lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) return (point - lineStart).distance;

    // Calculate projection factor (t) along the line segment
    double t =
        ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
            lengthSquared;
    t = t.clamp(0.0, 1.0); // Clamp to [0, 1] to stay within the line segment

    // Find the projected point on the line
    double projectionX = lineStart.dx + t * dx;
    double projectionY = lineStart.dy + t * dy;

    // Return the distance from the point to the projection
    return (point - Offset(projectionX, projectionY)).distance;
  }

  Offset _getClosestPointOnWallSegment(
      Offset targetOffset, Offset wallStart, Offset wallEnd) {
    // Calculate the vector from the start of the wall to the target
    Offset wallVector = wallEnd - wallStart;
    Offset targetVector = targetOffset - wallStart;

    // Calculate the length squared of the wall segment (to avoid unnecessary square roots)
    double wallLengthSquared =
        wallVector.dx * wallVector.dx + wallVector.dy * wallVector.dy;

    // Handle the degenerate case where the wall segment is effectively a single point
    if (wallLengthSquared == 0) return wallStart;

    // Calculate the projection factor (t) of the target onto the wall segment
    double t =
        (targetVector.dx * wallVector.dx + targetVector.dy * wallVector.dy) /
            wallLengthSquared;

    // Clamp t to [0, 1] to ensure the closest point lies within the wall segment
    t = t.clamp(0.0, 1.0);

    // Find the closest point on the wall segment
    return Offset(
        wallStart.dx + t * wallVector.dx, wallStart.dy + t * wallVector.dy);
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

  void _handleInternalWallSnapping({InternalWall? selectedInWall}) {
    final internalWall = selectedInWall ?? selectedEntity as InternalWall;
    List<Wall> walls = grid.entities.whereType<Wall>().toList();
    Wall? closestWall;
    DragHandle? closeInternalWallHandle;
    DragHandle? farInternalWallHandle;
    double minDistance = double.infinity;
    double preserveLength = internalWall.length;
    double initialAngle = InternalWall.getAngle(internalWall);

    // Find the closest wall and handles
    for (Wall wall in walls) {
      double distance =
          SketchHelpers.inWallDistanceFromWall(internalWall, wall);

      if (distance < minDistance) {
        minDistance = distance;
        closestWall = wall;

        double distanceToHandleA =
            SketchHelpers.handleDistanceFromWall(internalWall.handleA, wall);
        double distanceToHandleB =
            SketchHelpers.handleDistanceFromWall(internalWall.handleB, wall);

        closeInternalWallHandle = (distanceToHandleA <= distanceToHandleB)
            ? internalWall.handleA
            : internalWall.handleB;

        farInternalWallHandle = (distanceToHandleA >= distanceToHandleB)
            ? internalWall.handleA
            : internalWall.handleB;
      }
    }

    if (farInternalWallHandle == null ||
        closeInternalWallHandle == null ||
        closestWall == null) {
      return;
    }

    Offset closestPoint = SketchHelpers.getClosestPointOnWall(
        closeInternalWallHandle, closestWall);

    closeInternalWallHandle.setPosition(closestPoint.dx, closestPoint.dy);

    Offset newFarHandlePosition = _calculateNewFarInternalWallHandlePosition(
        internalWall, closestPoint, preserveLength, initialAngle);

    // Check if new far handle position is within the walls' bounds
    // aka inside the closed loop of walls
    if (!SketchHelpers.isPointInsidePath(newFarHandlePosition, null, grid)) {
      double currentLength =
          (Offset(farInternalWallHandle.x, farInternalWallHandle.y) -
                  closestPoint)
              .distance;
      double availableLength = internalWall.length;

      if (availableLength < 10) {
        return;
      } else if (availableLength < currentLength) {
        double trimmedLength = max(availableLength, 10);
        newFarHandlePosition = _calculateNewFarInternalWallHandlePosition(
            internalWall, closestPoint, trimmedLength, initialAngle);
      } else {
        initialAngle = initialAngle + pi;
        newFarHandlePosition = _calculateNewFarInternalWallHandlePosition(
            internalWall, closestPoint, preserveLength, initialAngle);

        if (!SketchHelpers.isPointInsidePath(
            newFarHandlePosition, null, grid)) {
          availableLength = SketchHelpers.calculateAvailableLengthWithinBounds(
              closestPoint, initialAngle, grid);
          if (availableLength < 10) {
            return;
          } else {
            double trimmedLength = max(availableLength, 10);
            newFarHandlePosition = _calculateNewFarInternalWallHandlePosition(
                internalWall, closestPoint, trimmedLength, initialAngle);
          }
        }
      }
    }

    farInternalWallHandle.setPosition(
        newFarHandlePosition.dx, newFarHandlePosition.dy);
  }

  void _handleWindowSnapping({Window? selectedWindow}) {
    final window = selectedWindow ?? selectedEntity as Window;
    List<Wall> walls = grid.entities.whereType<Wall>().toList();
    Wall? closestWall;
    double minDistance = double.infinity;

    for (Wall wall in walls) {
      double distance = SketchHelpers.windowDistanceFromWall(window, wall);

      if (distance < minDistance && wall.length > window.length) {
        minDistance = distance;
        closestWall = wall;
      }
    }

    if (closestWall == null) return;

    // Get the wall's drag handles (start and end points)
    Offset wallStart = closestWall.handleA.position();
    Offset wallEnd = closestWall.handleB.position();

    // Snap the first handle (handleA) to the closest point on the wall
    Offset closestPointA =
        SketchHelpers.getClosestPointOnWall(window.handleA, closestWall);

    // Calculate the position for handleB based on the preserved length and wall direction
    Offset directionVector = (wallEnd - wallStart).normalize();
    Offset newHandleB = closestPointA + directionVector * window.length;

    // Ensure handleB does not exceed the wall's bounds
    if ((newHandleB - wallStart).dot(directionVector) < 0) {
      // Clamp handleB to wall's start if it's before the start of the wall
      newHandleB = wallStart;
    } else if ((newHandleB - wallEnd).dot(directionVector) > 0) {
      // Clamp handleB to wall's end if it exceeds the end of the wall
      newHandleB = wallEnd;
    }

    // Adjust handleA to preserve window length within wall bounds
    Offset adjustedHandleA = newHandleB - directionVector * window.length;
    if ((adjustedHandleA - wallStart).dot(directionVector) < 0) {
      // Clamp handleA to wall's start if it exceeds wall bounds
      adjustedHandleA = wallStart;
      newHandleB = adjustedHandleA + directionVector * window.length;
    } else if ((adjustedHandleA - wallEnd).dot(directionVector) > 0) {
      // Clamp handleA to wall's end if it exceeds wall bounds
      adjustedHandleA = wallEnd;
      newHandleB = adjustedHandleA - directionVector * window.length;
    }

    // Update the positions of the window handles
    window.handleA.setPosition(adjustedHandleA.dx, adjustedHandleA.dy);
    window.handleB.setPosition(newHandleB.dx, newHandleB.dy);
  }

  Offset _calculateNewFarInternalWallHandlePosition(
      InternalWall internalWall,
      Offset newCloseHandlePosition,
      double originalLength,
      double originalAngle) {
    double newFarHandleX =
        newCloseHandlePosition.dx + originalLength * cos(originalAngle);
    double newFarHandleY =
        newCloseHandlePosition.dy + originalLength * sin(originalAngle);
    return Offset(newFarHandleX, newFarHandleY);
  }

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
              _calculateScaleFactor();
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
              _calculateScaleFactor();
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

                  selectedEntity = null;
                  for (var entity in grid.entities) {
                    if (entity is InternalWall) {
                      _handleInternalWallSnapping(selectedInWall: entity);
                    } else if (entity is Window) {
                      _handleWindowSnapping(selectedWindow: entity);
                    }
                  }
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
          )
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
          final wall = (selectedEntity as Wall);
          final wallCenter = Wall.getCenter(wall);
          final wallAngle = Wall.getAngle(wall);

          setGridState(() {
            double offsetX = 20 * cos(wallAngle);
            double offsetY = 20 * sin(wallAngle);

            final window = Window(
              id: generateGuid(),
              thickness: 15,
              handleA: DragHandle(
                id: generateGuid(),
                x: wallCenter.dx - offsetX,
                y: wallCenter.dy - offsetY,
                parentEntity: ParentEntity.window,
                handleType: HandleType.transparent,
              ),
              handleB: DragHandle(
                id: generateGuid(),
                x: wallCenter.dx + offsetX,
                y: wallCenter.dy + offsetY,
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
