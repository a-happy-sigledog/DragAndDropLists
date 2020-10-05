import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:drag_and_drop_lists/measure_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DragAndDropItemWrapper extends StatefulWidget {
  final DragAndDropItem child;
  final Function(PointerMoveEvent event) onPointerMove;
  final Function(PointerUpEvent event) onPointerUp;
  final Function(PointerDownEvent event) onPointerDown;
  final Function(DragAndDropItem reorderedItem, DragAndDropItem receiverItem)
      onItemReordered;
  final Widget ghost;
  final double draggingWidth;
  final double ghostOpacity;
  final int sizeAnimationDuration;
  final bool dragOnLongPress;
  final CrossAxisAlignment verticalAlignment;
  final Axis axis;
  final Decoration decorationWhileDragging;

  /// Set a custom drag handle to use iOS-like handles to drag rather than long
  /// or short presses
  final Widget dragHandle;
  final bool dragHandleOnLeft;

  DragAndDropItemWrapper(
      {@required this.child,
      @required this.onPointerMove,
      @required this.onPointerUp,
      @required this.onPointerDown,
      @required this.onItemReordered,
      this.ghost,
      this.draggingWidth,
      this.ghostOpacity = 0.3,
      this.sizeAnimationDuration = 300,
      this.dragOnLongPress = true,
      this.verticalAlignment = CrossAxisAlignment.start,
      this.axis = Axis.vertical,
      this.dragHandle,
      this.dragHandleOnLeft = false,
      this.decorationWhileDragging,
      Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DragAndDropItemWrapper();
}

class _DragAndDropItemWrapper extends State<DragAndDropItemWrapper>
    with TickerProviderStateMixin {
  DragAndDropItem _hoveredDraggable;

  bool _draggingWithHandle = false;
  Size _draggingWithHandleContainerSize = Size.zero;
  double _draggingWithHandleContainerLeftPosition = 0;
  Size _draggingWithHandleDragHandleSize = Size.zero;
  double _draggingWithHandleDragHandleLeftPosition = 0;

  @override
  Widget build(BuildContext context) {
    Widget draggable;
    if (widget.child.canDrag) {
      if (widget.dragHandle != null) {
        double dragHandleCenter = _draggingWithHandleDragHandleLeftPosition +
            (_draggingWithHandleDragHandleSize.width / 2.0);
        double containerLeftToDragHandleCenter =
            dragHandleCenter - _draggingWithHandleContainerLeftPosition;

        Widget feedback = Container(
          width: widget.draggingWidth ?? _draggingWithHandleContainerSize.width,
          child: Stack(
            children: [
              widget.child.child,
              Positioned(
                right: widget.dragHandleOnLeft ? null : 0,
                left: widget.dragHandleOnLeft ? 0 : null,
                top: 0,
                bottom: 0,
                child: widget.dragHandle,
              ),
            ],
          ),
        );

        var positionedDragHandle = Positioned(
          right: widget.dragHandleOnLeft ? null : 0,
          left: widget.dragHandleOnLeft ? 0 : null,
          top: 0,
          bottom: 0,
          child: Draggable<DragAndDropItem>(
            data: widget.child,
            axis: widget.axis == Axis.vertical ? Axis.vertical : null,
            child: MeasureSize(
              onSizeChange: (size) {
                setState(() {
                  _draggingWithHandleDragHandleSize = size;
                });
              },
              onLeftPositionChange: (leftPosition) {
                setState(() {
                  _draggingWithHandleDragHandleLeftPosition = leftPosition;
                });
              },
              child: widget.dragHandle,
            ),
            feedback: Transform.translate(
              offset: Offset(
                  -containerLeftToDragHandleCenter +
                      _draggingWithHandleContainerLeftPosition,
                  0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: widget.decorationWhileDragging,
                  child: feedback,
                ),
              ),
            ),
            childWhenDragging: Container(),
            onDragStarted: () {
              setState(() {
                _draggingWithHandle = true;
              });
            },
            onDragCompleted: () {
              setState(() {
                _draggingWithHandle = false;
              });
            },
            onDraggableCanceled: (_, __) {
              setState(() {
                _draggingWithHandle = false;
              });
            },
            onDragEnd: (_) {
              setState(() {
                _draggingWithHandle = false;
              });
            },
          ),
        );

        draggable = MeasureSize(
          onSizeChange: (size) {
            setState(() {
              _draggingWithHandleContainerSize = size;
            });
          },
          onLeftPositionChange: (leftPosition) {
            setState(() {
              _draggingWithHandleContainerLeftPosition = leftPosition;
            });
          },
          child: Stack(
            children: [
              Visibility(
                visible: !_draggingWithHandle,
                child: widget.child.child,
              ),
              // dragAndDropListContents,
              positionedDragHandle,
            ],
          ),
        );
      } else if (widget.dragOnLongPress) {
        draggable = LongPressDraggable<DragAndDropItem>(
          data: widget.child,
          axis: widget.axis == Axis.vertical ? Axis.vertical : null,
          child: widget.child.child,
          feedback: Container(
            width: widget.draggingWidth ?? MediaQuery.of(context).size.width,
            child: Material(
              child: widget.child.child,
              color: Colors.transparent,
            ),
          ),
          childWhenDragging: Container(),
        );
      } else {
        draggable = Draggable<DragAndDropItem>(
          data: widget.child,
          axis: widget.axis == Axis.vertical ? Axis.vertical : null,
          child: widget.child.child,
          feedback: Container(
            width: widget.draggingWidth ?? MediaQuery.of(context).size.width,
            child: Material(
              child: widget.child.child,
              color: Colors.transparent,
            ),
          ),
          childWhenDragging: Container(),
        );
      }
    } else {
      draggable = AnimatedSize(
        duration: Duration(milliseconds: widget.sizeAnimationDuration),
        vsync: this,
        alignment: Alignment.bottomCenter,
        child: _hoveredDraggable != null ? Container() : widget.child.child,
      );
    }
    return Stack(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.verticalAlignment,
          children: <Widget>[
            AnimatedSize(
              duration: Duration(milliseconds: widget.sizeAnimationDuration),
              vsync: this,
              alignment: Alignment.topLeft,
              child: _hoveredDraggable != null
                  ? Opacity(
                      opacity: widget.ghostOpacity,
                      child: widget.ghost ?? _hoveredDraggable.child,
                    )
                  : Container(),
            ),
            Listener(
              child: draggable,
              onPointerMove: widget.onPointerMove,
              onPointerDown: widget.onPointerDown,
              onPointerUp: widget.onPointerUp,
            ),
          ],
        ),
        Positioned.fill(
          child: DragTarget<DragAndDropItem>(
            builder: (context, candidateData, rejectedData) {
              if (candidateData != null && candidateData.isNotEmpty) {}
              return Container();
            },
            onWillAccept: (incoming) {
              setState(() {
                _hoveredDraggable = incoming;
              });
              return true;
            },
            onLeave: (incoming) {
              setState(() {
                _hoveredDraggable = null;
              });
            },
            onAccept: (incoming) {
              setState(() {
                if (widget.onItemReordered != null)
                  widget.onItemReordered(incoming, widget.child);
                _hoveredDraggable = null;
              });
            },
          ),
        )
      ],
    );
  }
}
