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
      await loadHandles();
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

  _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle) {
        DragHandle handle = selectedEntity as DragHandle;
        List<Offset> offsetsToMatch = [];
        final commonWalls = grid.entities
            .whereType<Wall>()
            .where(
                (e) => e.handleA.isEqual(handle) || e.handleB.isEqual(handle))
            .toList();

        for (final wall in commonWalls) {
          final complementingHandle =
              wall.handleA.isEqual(handle) ? wall.handleB : wall.handleA;
          offsetsToMatch
              .add(Offset(complementingHandle.x, complementingHandle.y));
        }

        final snappingOffset = SketchHelpers.findExactPerpendicularOffset(
            Offset(selectedEntity!.x + details.focalPointDelta.dx,
                selectedEntity!.y + details.focalPointDelta.dy),
            offsetsToMatch);

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
        selectedEntity?.move(
          details.focalPointDelta.dx,
          details.focalPointDelta.dy,
        );
      }
      setState(() {});
    }
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

  Future<void> loadHandles() async {
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
          setGridState(() {
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
            selectedEntity = inWall;
          });
        } else if (value == 1) {
          loadedDoorAsset = loadedDoorAsset ??
              await SketchHelpers.loadImage('assets/door.png');
          loadedActiveDoorAsset = loadedActiveDoorAsset ??
              await SketchHelpers.loadImage('assets/door_active.png');
          setGridState(() {
            final door = Door(
              id: generateGuid(),
              x: canvasSize.width / 2,
              y: canvasSize.height / 2,
              doorAsset: loadedDoorAsset!,
              doorActiveAsset: loadedActiveDoorAsset!,
            );
            grid.addEntity(door);
            selectedEntity = door;
          });
        } else if (value == 2) {
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
