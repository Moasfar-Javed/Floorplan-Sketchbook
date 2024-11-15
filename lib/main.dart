import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/enums/wall_state.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/painters/base_painter.dart';
import 'package:sketchbook/painters/icon_painter.dart';
import 'package:sketchbook/sketch_helpers.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

String generateGuid() {
  var id = _uuid.v4();
  return id;
}

void main() {
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

class _MyHomePageState extends State<MyHomePage> {
  late Size canvasSize;
  late Grid grid;
  Entity? selectedEntity;
  Offset cameraOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    canvasSize = MediaQuery.of(context).size;
    grid = Grid(
        gridWidth: canvasSize.width,
        gridHeight: canvasSize.height,
        cellSize: 20);
    _generateInitialSquare();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
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
        onTap: (value) {
          if (value == 0) {
            grid.addEntity(
              InternalWall(
                id: generateGuid(),
                thickness: 10,
                handleA: DragHandle(
                    id: generateGuid(),
                    x: canvasSize.width / 2,
                    y: canvasSize.height / 2),
                handleB: DragHandle(
                    id: generateGuid(),
                    x: canvasSize.width / 2,
                    y: canvasSize.height / 2 + 100),
              ),
            );
            setState(() {});
          }
        },
      ),
      body: GestureDetector(
        onPanStart: (details) {
          selectedEntity = SketchHelpers.getDragHandleAtPosition(
                details.localPosition,
                grid,
              ) ??
              SketchHelpers.getWallAtPosition(
                details.localPosition,
                grid,
              ) ??
              SketchHelpers.getInternalWallAtPosition(
                details.localPosition,
                grid,
              );

          if (selectedEntity != null) {
            if (selectedEntity is Wall) {
              selectedEntity = (selectedEntity as Wall)
                  .getClosestHandle(details.localPosition);
            }
            setState(() {});
          }
        },
        onPanUpdate: (details) {
          if (selectedEntity != null) {
            selectedEntity?.move(
              details.delta.dx,
              details.delta.dy,
            );
            setState(() {});
          }
        },
        onPanEnd: (details) {
          if (selectedEntity != null) {
            grid.snapEntityToGrid(selectedEntity!);
            selectedEntity = null;
            setState(() {});
          }
        },
        onTapUp: (details) {
          Entity? entity = SketchHelpers.getDragHandleAtPosition(
                  details.localPosition, grid) ??
              SketchHelpers.getWallAtPosition(details.localPosition, grid);

          if (entity != null) {
            if (entity is Wall) {
              selectedEntity = entity;
              setState(() {});
              _openWallContextMenu(entity, details.localPosition);
            } else if (entity is DragHandle) {
              _openDragHandleContextMenu(entity, details.localPosition);
            }
          }
        },
        // Icon(Icons.drag_indicator)
        child: Stack(
          children: [
            CustomPaint(
              size: canvasSize,
              painter: BasePainter(
                  grid: grid,
                  selectedEntity: selectedEntity,
                  cameraOffset: cameraOffset),
            ),
            if (selectedEntity != null && selectedEntity is DragHandle)
              CustomPaint(
                size: canvasSize,
                painter: IconPainter(
                  position:
                      Offset(selectedEntity?.x ?? 0, selectedEntity?.y ?? 0),
                  icon: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.yellow,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openWallContextMenu(Wall wall, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (wall.wallState == WallState.active)
          const PopupMenuItem(
            value: 'addPoint',
            child: Text('Add a Point'),
          ),
        if (wall.wallState == WallState.active)
          const PopupMenuItem(
            value: 'remove',
            child: Text('Remove Wall'),
          ),
        if (wall.wallState == WallState.removed)
          const PopupMenuItem(
            value: 'add',
            child: Text('Add Wall'),
          ),
      ],
    ).then((value) {
      selectedEntity = null;
      if (value == 'add') {
        wall.wallState = WallState.active;
        setState(() {});
      } else if (value == 'remove') {
        wall.wallState = WallState.removed;
        setState(() {});
      } else if (value == 'addPoint') {
        var childWalls = wall.split(wall, position);
        grid.removeEntity(wall);
        grid.addEntity(childWalls.$1);
        grid.addEntity(childWalls.$2);
        grid.snapEntityToGrid(childWalls.$1);
        grid.snapEntityToGrid(childWalls.$2);
        setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  void _openDragHandleContextMenu(DragHandle handle, Offset position) {
    if (grid.entities.whereType<Wall>().toList().length <= 3) return;
    selectedEntity = handle;
    setState(() {});
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove Point'),
        ),
      ],
    ).then((value) {
      selectedEntity = null;
      if (value == 'remove') {
        final walls = grid.entities
            .where((e) =>
                e is Wall &&
                ((e).handleA.isEqual(handle) || (e).handleB.isEqual(handle)))
            .cast<Wall>()
            .toList();
        final newCommonHandle = walls.first.handleA.isEqual(handle)
            ? walls.first.handleB
            : walls.first.handleA;
        walls.last.replaceHandle(handle, newCommonHandle);
        grid.removeEntity(walls.first);
        setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  /// HELPERS
  void _generateInitialSquare() {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;
    const squareSide = 300.0;

    final topLeft = Offset(centerX - squareSide / 2, centerY - squareSide / 2);
    final topRight = Offset(centerX + squareSide / 2, centerY - squareSide / 2);
    final bottomRight =
        Offset(centerX + squareSide / 2, centerY + squareSide / 2);
    final bottomLeft =
        Offset(centerX - squareSide / 2, centerY + squareSide / 2);

    final topLeftHandle =
        DragHandle(id: generateGuid(), x: topLeft.dx, y: topLeft.dy);
    final topRightHandle =
        DragHandle(id: generateGuid(), x: topRight.dx, y: topRight.dy);
    final bottomRightHandle =
        DragHandle(id: generateGuid(), x: bottomRight.dx, y: bottomRight.dy);
    final bottomLeftHandle =
        DragHandle(id: generateGuid(), x: bottomLeft.dx, y: bottomLeft.dy);

    final wall1 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: topLeftHandle,
      handleB: topRightHandle,
    );

    final wall2 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: topRightHandle,
      handleB: bottomRightHandle,
    );

    final wall3 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: bottomRightHandle,
      handleB: bottomLeftHandle,
    );

    final wall4 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: bottomLeftHandle,
      handleB: topLeftHandle,
    );

    // Add walls to the grid
    grid.addAllEntity([
      wall1,
      wall2,
      wall3,
      wall4,
    ]);
    grid.snapEntityToGrid(wall1);
    grid.snapEntityToGrid(wall2);
    grid.snapEntityToGrid(wall3);
    grid.snapEntityToGrid(wall4);
  }
}
