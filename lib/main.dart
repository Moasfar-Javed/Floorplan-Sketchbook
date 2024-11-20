import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

  bool initialized = false;
  Entity? selectedEntity;
  ui.Image? loadedDoorAsset;
  ui.Image? loadedActiveDoorAsset;
  ui.Image? loadedEquipmentAsset;
  ui.Image? loadedActiveEquipmentAsset;
  ui.Image? loadedMPAsset;
  ui.Image? loadedActiveMPAsset;

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
  void didChangeDependencies() {
    if (!initialized) {
      initialized = true;
      canvasSize = const Size(2000, 2000);
      grid = Grid(
          width: canvasSize.width, height: canvasSize.height, cellSize: 20);
      SketchHelpers.generateInitialSquare(grid, canvasSize);
      SketchHelpers.centerCanvas(
        canvasSize,
        context,
        _animationController,
        _transformationController,
        animate: false,
      );
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
                onInteractionUpdate: (details) {
                  if (selectedEntity != null) {
                    selectedEntity?.move(
                      details.focalPointDelta.dx,
                      details.focalPointDelta.dy,
                    );
                    setState(() {});
                  }
                },
                onInteractionEnd: (details) {
                  if (selectedEntity != null) {
                    grid.snapEntityToGrid(selectedEntity!);
                    setState(() {});
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
                    _buildOverlayIcon(),
                  ],
                ),
              ),
            ),
            _buildContextButtons()
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayIcon() {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle) {
        return CustomPaint(
          size: canvasSize,
          painter: IconPainter(
            position: Offset(selectedEntity?.x ?? 0, selectedEntity?.y ?? 0),
            icon: const Icon(
              Icons.zoom_out_map,
              color: Color(0xFF2463EB),
              size: 40,
            ),
          ),
        );
      } else if (selectedEntity is Wall) {
        return CustomPaint(
          size: canvasSize,
          painter: IconPainter(
            position: Wall.getCenter(selectedEntity),
            icon: const Icon(
              Icons.zoom_out_map,
              color: Color(0xFF2463EB),
              size: 40,
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  _buildContextButtons() {
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
              child: const Text('Open Wall'),
              onPressed: () {
                wall.wallState = WallState.removed;
                setState(() {});
              },
            ),
          if (wall.wallState == WallState.removed)
            TextButton(
              child: const Text('Close Wall'),
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
          TextButton(
            child: const Text('Snap to Closest Wall'),
            onPressed: () {
              // TODO: Optimize later, the double call is a bandaid solution for a misalighnment problem
              (selectedEntity as Window)
                  .snapToClosestWall(grid.entities.whereType<Wall>().toList());
              (selectedEntity as Window)
                  .snapToClosestWall(grid.entities.whereType<Wall>().toList());

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
          loadedActiveDoorAsset = loadedActiveDoorAsset ??
              await SketchHelpers.loadImage('assets/door_active.png');
          final door = Door(
            id: generateGuid(),
            x: canvasSize.width / 2,
            y: canvasSize.height / 2,
            doorAsset: loadedDoorAsset!,
            doorActiveAsset: loadedActiveDoorAsset!,
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
