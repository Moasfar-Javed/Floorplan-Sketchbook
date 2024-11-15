import 'package:flutter/material.dart';
import 'package:sketchbook/free_scroll_view.dart';
import 'package:sketchbook/models/drag_handle.dart';
import 'package:sketchbook/models/entity.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/wall.dart';
import 'package:sketchbook/painters/grid_painter.dart';
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
      body: GestureDetector(
        onPanStart: (details) {
          selectedEntity = _getEntityAtPosition(details.localPosition);
          if (selectedEntity is Wall) {
            selectedEntity = (selectedEntity as Wall)
                .getClosestHandle(details.localPosition);
          }
          setState(() {});
        },
        onPanUpdate: (details) {
          selectedEntity?.move(
            details.delta.dx,
            details.delta.dy,
          );
          setState(() {});
        },
        onPanEnd: (details) {
          if (selectedEntity != null) {
            grid.snapEntityToGrid(selectedEntity!);
            selectedEntity = null;
            setState(() {});
          }
        },
        onLongPressStart: (details) {
          Wall? wall = _getWallAtPosition(details.localPosition);
          print(wall);
          if (wall != null) {
            var splitWalls = wall.split(wall, details.localPosition);
            grid.removeEntity(wall);
            grid.addEntity(splitWalls.$1);
            grid.addEntity(splitWalls.$2);
            setState(() {});
          }
        },
        child: CustomPaint(
          size: canvasSize,
          painter: GridPainter(
              grid: grid,
              selectedEntity: selectedEntity,
              cameraOffset: cameraOffset),
        ),
      ),
    );
  }

  /// HELPERS

  void _generateInitialSquare() {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;
    const squareSide = 300.0;

    // Calculate the corner positions of the square
    final topLeft = Offset(centerX - squareSide / 2, centerY - squareSide / 2);
    final topRight = Offset(centerX + squareSide / 2, centerY - squareSide / 2);
    final bottomRight =
        Offset(centerX + squareSide / 2, centerY + squareSide / 2);
    final bottomLeft =
        Offset(centerX - squareSide / 2, centerY + squareSide / 2);

    // Create DragHandles at each corner
    final topLeftHandle =
        DragHandle(id: generateGuid(), x: topLeft.dx, y: topLeft.dy);
    final topRightHandle =
        DragHandle(id: generateGuid(), x: topRight.dx, y: topRight.dy);
    final bottomRightHandle =
        DragHandle(id: generateGuid(), x: bottomRight.dx, y: bottomRight.dy);
    final bottomLeftHandle =
        DragHandle(id: generateGuid(), x: bottomLeft.dx, y: bottomLeft.dy);

    // Create the four walls of the square, connecting them by shared handles
    final wall1 = Wall(
      id: generateGuid(),
      thickness: 10,
      leftHandle: topLeftHandle,
      rightHandle: topRightHandle,
    );

    final wall2 = Wall(
      id: generateGuid(),
      thickness: 10,
      leftHandle: topRightHandle,
      rightHandle: bottomRightHandle,
    );

    final wall3 = Wall(
      id: generateGuid(),
      thickness: 10,
      leftHandle: bottomRightHandle,
      rightHandle: bottomLeftHandle,
    );

    final wall4 = Wall(
      id: generateGuid(),
      thickness: 10,
      leftHandle: bottomLeftHandle,
      rightHandle: topLeftHandle,
    );

    // Add walls to the grid
    grid.addEntity(wall1);
    grid.addEntity(wall2);
    grid.addEntity(wall3);
    grid.addEntity(wall4);
  }

  // Method to find an entity at a given position with padding
  Entity? _getEntityAtPosition(Offset position) {
    final adjustedPosition = position - cameraOffset;
    for (var entity in grid.entities) {
      if (entity is Wall) {
        if (_comparePositionWithPadding(adjustedPosition, entity.leftHandle)) {
          return entity.leftHandle;
        } else if (_comparePositionWithPadding(
            adjustedPosition, entity.rightHandle)) {
          return entity.rightHandle;
        }
      } else if (_comparePositionWithPadding(adjustedPosition, entity)) {
        return entity;
      }
    }
    return null;
  }

  // Method to get a Wall entity at position
  Wall? _getWallAtPosition(Offset position) {
    for (var entity in grid.entities) {
      if (entity is Wall && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  bool _comparePositionWithPadding(Offset position, Entity entity) {
    const double padding = 20.0; // To increase the touch target
    return position.dx >= entity.x - padding &&
        position.dx <= entity.x + padding &&
        position.dy >= entity.y - padding &&
        position.dy <= entity.y + padding;
  }
}
