import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/door.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/equipment.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/moisture_point.dart';
import 'package:sketchbook/models/entities/window.dart';
import 'package:sketchbook/models/enums/handle_type.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
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

class _MyHomePageState extends State<MyHomePage>
    with AutomaticKeepAliveClientMixin {
  late Size canvasSize;
  late Grid grid;
  bool initialized = false;
  Entity? selectedEntity;
  Offset cameraOffset = Offset.zero;
  ui.Image? loadedDoorAsset;
  ui.Image? loadedEquipmentAsset;
  ui.Image? loadedActiveEquipmentAsset;
  ui.Image? loadedMPAsset;
  ui.Image? loadedActiveMPAsset;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    if (!initialized) {
      initialized = true;
      canvasSize = MediaQuery.of(context).size;
      grid = Grid(
          gridWidth: canvasSize.width,
          gridHeight: canvasSize.height,
          cellSize: 20);
      SketchHelpers.generateInitialSquare(grid, canvasSize);
    }
    super.didChangeDependencies();
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
                  setState(() {});
                }
              },
              onTapUp: (details) {
                selectedEntity = SketchHelpers.getEntityAtPosition(
                    details.localPosition, grid);
                setState(() {});
              },
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
                        position: Offset(
                            selectedEntity?.x ?? 0, selectedEntity?.y ?? 0),
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
            _buildContextButtons()
          ],
        ),
      ),
    );
  }

  _buildContextButtons() {
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
                var childWalls = wall.split(wall);
                grid.removeEntity(wall);
                grid.addEntity(childWalls.$1);
                grid.addEntity(childWalls.$2);
                grid.snapEntityToGrid(childWalls.$1);
                grid.snapEntityToGrid(childWalls.$2);
                selectedEntity = null;
                setState(() {});
              },
            ),
          if (wall.wallState == WallState.active)
            TextButton(
              child: const Text('Remove Wall'),
              onPressed: () {
                wall.wallState = WallState.removed;
                setState(() {});
              },
            ),
          if (wall.wallState == WallState.removed)
            TextButton(
              child: const Text('Add Wall'),
              onPressed: () {
                wall.wallState = WallState.active;
                setState(() {});
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
              setState(() {});
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
              grid.removeEntity(inWall);
              selectedEntity = null;
              setState(() {});
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
              grid.removeEntity(door);
              selectedEntity = null;
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Rotate Right'),
            onPressed: () {
              door.rotateClockwise();
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Rotate Left'),
            onPressed: () {
              door.rotateCounterclockwise();
              setState(() {});
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
              grid.removeEntity(window);
              selectedEntity = null;
              setState(() {});
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
              equipment.updateValue(newVal);
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              grid.removeEntity(equipment);
              selectedEntity = null;
              setState(() {});
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
              mp.updateValue(newVal);
              setState(() {});
            },
          ),
          TextButton(
            child: const Text('Remove'),
            onPressed: () {
              grid.removeEntity(mp);
              selectedEntity = null;
              setState(() {});
            },
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
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
          final inWall = InternalWall(
            id: generateGuid(),
            thickness: 10,
            handleA: DragHandle(
              id: generateGuid(),
              x: canvasSize.width / 2,
              y: canvasSize.height / 2,
              parentEntity: ParentEntity.internalWall,
              handleType: HandleType.transparent,
            ),
            handleB: DragHandle(
              id: generateGuid(),
              x: canvasSize.width / 2,
              y: canvasSize.height / 2 + 100,
              parentEntity: ParentEntity.internalWall,
              handleType: HandleType.transparent,
            ),
          );
          grid.addEntity(inWall);
          setState(() {
            selectedEntity = inWall;
          });
        } else if (value == 1) {
          loadedDoorAsset = loadedDoorAsset ??
              await SketchHelpers.loadImage('assets/door.png');

          final door = Door(
            id: generateGuid(),
            x: canvasSize.width / 2,
            y: canvasSize.height / 2,
            doorAsset: loadedDoorAsset!,
          );
          grid.addEntity(door);
          setState(() {
            selectedEntity = door;
          });
        } else if (value == 2) {
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
          setState(() {
            selectedEntity = window;
          });
        } else if (value == 3) {
          loadedEquipmentAsset = loadedEquipmentAsset ??
              await SketchHelpers.loadImage('assets/equipment.png');
          loadedActiveEquipmentAsset = loadedActiveEquipmentAsset ??
              await SketchHelpers.loadImage('assets/equipment_active.png');

          final equipment = Equipment(
            label: '2',
            id: generateGuid(),
            x: canvasSize.width / 2,
            y: canvasSize.height / 2,
            equipmentAsset: loadedEquipmentAsset!,
            activeEquipmentAsset: loadedActiveEquipmentAsset!,
          );
          grid.addEntity(equipment);
          setState(() {
            selectedEntity = equipment;
          });
        } else if (value == 4) {
          loadedMPAsset = loadedMPAsset ??
              await SketchHelpers.loadImage('assets/moisture.png');
          loadedActiveMPAsset = loadedActiveMPAsset ??
              await SketchHelpers.loadImage('assets/moisture_active.png');

          final equipment = Equipment(
            label: '2',
            id: generateGuid(),
            x: canvasSize.width / 2,
            y: canvasSize.height / 2,
            equipmentAsset: loadedMPAsset!,
            activeEquipmentAsset: loadedActiveMPAsset!,
          );
          grid.addEntity(equipment);
          setState(() {
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
              Navigator.of(context).pop(null); // Return null on cancel
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pop(textController.text); // Return entered text on save
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  return result; // Return the result (entered text or null)
}
