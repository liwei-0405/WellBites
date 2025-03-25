import 'package:flutter/material.dart';
import 'ruler_painter.dart';

class HeightPicker extends StatefulWidget {
  final double initialHeight;
  final ValueChanged<double> onHeightSelected;

  const HeightPicker({
    Key? key,
    required this.initialHeight,
    required this.onHeightSelected,
  }) : super(key: key);

  @override
  _HeightPickerState createState() => _HeightPickerState();
}

class _HeightPickerState extends State<HeightPicker> {
  late double selectedHeight;
  final double minHeight = 50.0;
  final double maxHeight = 250.0;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    selectedHeight = widget.initialHeight;
    _scrollController = FixedExtentScrollController(
      initialItem: ((maxHeight - selectedHeight) * 2).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      
        Text(
          "${selectedHeight.toStringAsFixed(1)} cm",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 10),

        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 200,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 40,
                    physics: FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHeight = maxHeight - (index * 0.5);
                      });
                      widget.onHeightSelected(selectedHeight);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        double height = maxHeight - (index * 0.5);
                        bool isSelected = height == selectedHeight;
                        return Center(
                          child: Text(
                            "${height.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                          ),
                        );
                      },
                      childCount: ((maxHeight - minHeight) * 2).toInt() + 1,
                    ),
                  ),
                ),

                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    _scrollController.jumpTo(
                      _scrollController.offset - details.primaryDelta!,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPaint(painter: UniversalRulerPainter(isHorizontal: false)),
                  ),
                ),
              ],
            ),

            Positioned(
              top: 99,
              right: 45,
              child: Container(width: 120, height: 2, color: const Color.fromARGB(255, 33, 13, 92)),
            ),
          ],
        ),
      ],
    );
  }
}
