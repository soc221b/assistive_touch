import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

@immutable
class AssistiveTouch extends StatefulWidget {
  const AssistiveTouch({
    Key? key,
    this.child = const _DefaultChild(),
    this.visible = true,
    this.draggable = true,
    this.shouldStickToSide = true,
    this.margin = const EdgeInsets.all(8.0),
    this.initialOffset = Offset.infinite,
    this.onTap,
    this.animatedBuilder,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Switches between showing the [child] or hiding it.
  final bool visible;

  /// Whether it can be dragged.
  final bool draggable;

  /// Whether it sticks to the side.
  final bool shouldStickToSide;

  /// Empty space to surround the [child].
  final EdgeInsets margin;

  /// Initial position.
  ///
  /// For example, if you want to put Assistive Touch to left-bottom cornor:
  ///
  /// ```dart
  /// AssistiveTouch(
  ///   initialOffset: const Offset(double.infinity, 0);
  ///   ...
  /// )
  /// ```
  final Offset initialOffset;

  /// A tap with a primary button has occurred.
  final VoidCallback? onTap;

  /// Custom animated builder.
  final Widget Function(
    BuildContext context,
    Widget child,
    bool visible,
  )? animatedBuilder;

  @override
  _AssistiveTouchState createState() => _AssistiveTouchState();
}

class _AssistiveTouchState extends State<AssistiveTouch>
    with TickerProviderStateMixin {
  bool isInitialized = false;
  late double left;
  late double top;
  Size size = Size.zero;
  bool isDragging = false;
  bool isIdle = true;
  Timer? timer;
  late final AnimationController _scaleAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addListener(() {
          setState(() {});
        });
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _scaleAnimationController,
    curve: Curves.easeInOut,
  );
  Timer? scaleTimer;

  @override
  void initState() {
    super.initState();
    scaleTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (mounted == false) {
        return;
      }

      if (widget.visible) {
        _scaleAnimationController.forward();
      } else {
        _scaleAnimationController.reverse();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInitialized == false) {
      left = widget.initialOffset.dx;
      top = widget.initialOffset.dy;
      isInitialized = true;
      _setOffset(Offset(left, top));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    scaleTimer?.cancel();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    child = _MyMeasuredSize(
      child: child,
      onChange: (size) {
        setState(() {
          this.size = size;
        });
        _setOffset(Offset(left, top));
      },
    );

    child = widget.draggable
        ? Draggable(
            onDragStarted: _onDragStart,
            onDragUpdate: _onDragUpdate,
            onDragEnd: _onDragEnd,
            child: child,
            feedback: child,
          )
        : child;

    child = GestureDetector(
      onTap: _onTap,
      child: child,
    );

    child = widget.animatedBuilder != null
        ? widget.animatedBuilder!(context, child, widget.visible)
        : ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedOpacity(
              opacity: isIdle ? .3 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          );

    child = Positioned(
      left: left,
      top: top,
      child: child,
    );

    return child;
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      setState(() {
        isIdle = false;
      });
      _scheduleIdle();
    }
  }

  void _onDragStart() {
    setState(() {
      isDragging = true;
      isIdle = false;
    });
    timer?.cancel();
  }

  void _onDragUpdate(DragUpdateDetails detail) {
    _setOffset(Offset(left + detail.delta.dx, top + detail.delta.dy));
  }

  void _onDragEnd(DraggableDetails detail) {
    setState(() {
      isDragging = false;
    });
    _scheduleIdle();

    _setOffset(Offset(left, top));
  }

  void _scheduleIdle() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 2), () {
      if (isDragging == false) {
        setState(() {
          isIdle = true;
        });
      }
    });
  }

  void _setOffset(Offset offset) {
    if (isDragging) {
      setState(() {
        this.left = offset.dx;
        this.top = offset.dy;
      });

      return;
    }

    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final left = screenPadding.left +
        viewInsets.left +
        viewPadding.left +
        widget.margin.left;
    final top = screenPadding.top +
        viewInsets.top +
        viewPadding.top +
        widget.margin.top;
    final right = screenSize.width -
        screenPadding.right -
        viewInsets.right -
        viewPadding.right -
        widget.margin.right -
        size.width;
    final bottom = screenSize.height -
        screenPadding.bottom -
        viewInsets.bottom -
        viewPadding.bottom -
        widget.margin.bottom -
        size.height;

    final halfWidth = (right - left) / 2;

    if (widget.shouldStickToSide) {
      setState(() {
        this.top = max(min(offset.dy, bottom), top);
        this.left = max(
          min(
            this.top == bottom || this.top == top
                ? offset.dx
                : offset.dx < halfWidth
                    ? left
                    : right,
            right,
          ),
          left,
        );
      });
    } else {
      setState(() {
        this.top = max(min(offset.dy, bottom), top);
        this.left = max(min(offset.dx, right), left);
      });
    }
  }
}

class _MyMeasuredSize extends StatefulWidget {
  const _MyMeasuredSize({
    Key? key,
    required this.onChange,
    required this.child,
  }) : super(key: key);

  final Widget child;

  final void Function(Size size) onChange;

  @override
  _MyMeasuredSizeState createState() => _MyMeasuredSizeState();
}

class _MyMeasuredSizeState extends State<_MyMeasuredSize> {
  @override
  void initState() {
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance!.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  final widgetKey = GlobalKey();
  Size? oldSize;

  void postFrameCallback(Duration _) async {
    final context = widgetKey.currentContext!;

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );
    if (mounted == false) return;

    final newSize = context.size!;
    if (newSize == Size.zero) return;
    if (oldSize == newSize) return;
    oldSize = newSize;
    widget.onChange(newSize);
  }
}

class _DefaultChild extends StatelessWidget {
  const _DefaultChild({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[400]!.withOpacity(.6),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        child: Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withOpacity(.6),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
          ),
          child: Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
