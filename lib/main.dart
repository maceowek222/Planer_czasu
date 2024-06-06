import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do App',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          background: const Color.fromARGB(255, 39, 39, 39),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'To Do App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _tasks = <TaskStatus, List<Task>>{};
  final ScrollController _mainListScrollController = ScrollController();
  int _counter = 0;
  Timer? _timer;
  bool? _lastMoveRight;
  TextEditingController _taskNameController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.important;

  @override
  void initState() {
    TaskStatus.values.forEach((status) {
      _tasks[status] = <Task>[];
    });

    super.initState();
  }

  void _removeTask(Task task) {
    setState(() {
      _tasks[task.status]?.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: CustomScrollView(
                scrollDirection: Axis.horizontal,
                controller: _mainListScrollController,
                slivers: [
                  ...TaskStatus.values.map(
                        (status) {
                      return SliverToBoxAdapter(
                        child: RowStatusCard(
                          tasks: _tasks[status] ?? [],
                          taskStatus: status,
                          screenSize: screenSize,
                          taskAccepted: (task, newStatus) {
                            _tasks[task.status]?.remove(task);
                            _tasks[newStatus]?.add(
                              Task(
                                title: task.title,
                                status: newStatus,
                                category: task.category,
                              ),
                            );
                            setState(() {});
                          },
                          onDrag: (isRight) {
                            if (_lastMoveRight == isRight) {
                              return;
                            }

                            _lastMoveRight = isRight;
                            _moveMainList(isRight);
                          },
                          cancelDrag: () {
                            _lastMoveRight = null;
                            _timer?.cancel();
                          },
                          onRemove: _removeTask,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Task'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter task name',
                      ),
                    ),
                    DropdownButton<TaskCategory>(
                      value: _selectedCategory,
                      items: TaskCategory.values.map((category) {
                        return DropdownMenuItem<TaskCategory>(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (TaskCategory? newCategory) {
                        setState(() {
                          _selectedCategory = newCategory!;
                        });
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _tasks[TaskStatus.todo]?.add(
                        Task(
                          title: _taskNameController.text,
                          status: TaskStatus.todo,
                          category: _selectedCategory,
                        ),
                      );
                      _taskNameController.clear();
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _moveMainList(bool isRight) {
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: 100), () {
      if (_mainListScrollController.offset <= 20 && !isRight) {
        _timer?.cancel();
        return;
      }

      if (_mainListScrollController.offset >
          (_mainListScrollController.position.maxScrollExtent)) {
        _timer?.cancel();
        return;
      }

      _mainListScrollController.animateTo(
        _mainListScrollController.offset + (isRight ? 50 : -50),
        duration: Duration(milliseconds: 50),
        curve: Curves.easeIn,
      );

      _moveMainList(isRight);
    });
  }
}

class RowStatusCard extends StatelessWidget {
  final void Function(Task task, TaskStatus newStatus) taskAccepted;
  final void Function(bool isRight) onDrag;
  final void Function() cancelDrag;
  final void Function(Task task) onRemove;

  final TaskStatus taskStatus;
  final List<Task> tasks;
  final Size screenSize;

  const RowStatusCard({
    required this.tasks,
    required this.taskStatus,
    required this.screenSize,
    required this.taskAccepted,
    required this.onDrag,
    required this.cancelDrag,
    required this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenSize.height * 0.8,
      width: screenSize.width * 0.8,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            taskStatus.displayTitle,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 2,
              color: Colors.black38,
            ),
          ),
          Expanded(
            child: DragTarget<Task>(
              builder: (BuildContext context, List<Task?> candidateData,
                  List<dynamic> rejectedData) {
                return ListStatusColumnWidget(
                  tasks: tasks,
                  taskStatus: taskStatus,
                  screenSize: screenSize,
                  onDrag: onDrag,
                  cancelDrag: cancelDrag,
                  onRemove: onRemove,
                );
              },
              onWillAccept: (details) => true,
              onAccept: (details) {
                taskAccepted(details!, taskStatus);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ListStatusColumnWidget extends StatefulWidget {
  final void Function(bool isRight) onDrag;
  final void Function() cancelDrag;
  final void Function(Task task) onRemove;

  final TaskStatus taskStatus;
  final List<Task> tasks;
  final Size screenSize;

  const ListStatusColumnWidget({
    required this.tasks,
    required this.taskStatus,
    required this.screenSize,
    required this.onDrag,
    required this.cancelDrag,
    required this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  _ListStatusColumnWidgetState createState() => _ListStatusColumnWidgetState();
}

class _ListStatusColumnWidgetState extends State<ListStatusColumnWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(
            child: Text(
              "Drag a task here",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Draggable<Task>(
            data: widget.tasks[index],
            feedback: TaskWidget(
              task: widget.tasks[index],
              backgroundColor: widget.tasks[index].status.backgroundColor,
              onRemove: () {}, // Nie wymaga działania, ponieważ to jest feedback
              onCategoryChange: (category) {}, // Nie wymaga działania
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: TaskWidget(
                task: widget.tasks[index],
                backgroundColor: widget.tasks[index].status.backgroundColor,
                onRemove: () {}, // Nie wymaga działania, ponieważ to jest childWhenDragging
                onCategoryChange: (category) {}, // Nie wymaga działania
              ),
            ),
            onDragStarted: () {
              // Start dragging
            },
            onDragEnd: (_) {
              widget.cancelDrag();
            },
            onDraggableCanceled: (velocity, offset) {
              widget.cancelDrag();
            },
            onDragUpdate: (details) {
              if (details.localPosition.dx > widget.screenSize.width * 0.8) {
                widget.onDrag(true);
              } else if (details.localPosition.dx < widget.screenSize.width * 0.2) {
                widget.onDrag(false);
              } else {
                widget.cancelDrag();
              }
            },
            child: TaskWidget(
              task: widget.tasks[index],
              backgroundColor: widget.tasks[index].status.backgroundColor,
              onRemove: () => widget.onRemove(widget.tasks[index]),
              onCategoryChange: (category) {
                setState(() {
                  widget.tasks[index].category = category;
                });
              },
            ),
          ),
        );
      },
      itemCount: widget.tasks.length,
    );
  }
}

class TaskWidget extends StatelessWidget {
  final Task task;
  final Color backgroundColor;
  final VoidCallback onRemove;
  final ValueChanged<TaskCategory> onCategoryChange;

  const TaskWidget({
    required this.task,
    required this.backgroundColor,
    required this.onRemove,
    required this.onCategoryChange,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                DropdownButton<TaskCategory>(
                  value: task.category,
                  items: TaskCategory.values.map((category) {
                    return DropdownMenuItem<TaskCategory>(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (TaskCategory? newCategory) {
                    onCategoryChange(newCategory!);
                  },
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final TaskStatus status;
  TaskCategory category;

  Task({
    required this.title,
    required this.status,
    required this.category,
  });
}

enum TaskStatus {
  todo,
  inProgress,
  done,
}

extension TaskStatusExtension on TaskStatus {
  String get displayTitle {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TaskStatus.todo:
        return Colors.yellow;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }
}

enum TaskCategory {
  important,
  normal,
  optional,
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.important:
        return 'Important';
      case TaskCategory.normal:
        return 'Normal';
      case TaskCategory.optional:
        return 'Optional';
    }
  }
}
