import 'package:flutter/material.dart';
import 'ruler_painter.dart';

class WeightPicker extends StatefulWidget {
  final double initialWeight;
  final double minWeight;
  final double maxWeight;
  final ValueChanged<double> onWeightSelected;

  const WeightPicker({
    Key? key,
    required this.initialWeight,
    required this.minWeight,
    required this.maxWeight,
    required this.onWeightSelected,
  }) : super(key: key);

  @override
  _WeightPickerState createState() => _WeightPickerState();
}

class _WeightPickerState extends State<WeightPicker> {
  late double selectedWeight;
  late double rulerOffset;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.initialWeight;
    rulerOffset = (selectedWeight - widget.minWeight) * 10;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),

        Text(
          selectedWeight.toStringAsFixed(1) + " kg",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),


        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              rulerOffset -= details.primaryDelta!/3;
              double newWeight = (widget.minWeight + rulerOffset / 10).clamp(
                widget.minWeight,
                widget.maxWeight,
              );
              selectedWeight = double.parse(newWeight.toStringAsFixed(1));
              rulerOffset = (selectedWeight - widget.minWeight) * 10;
              widget.onWeightSelected(selectedWeight);
            });
          },
          child: Container(
            width: 300,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomPaint(
              painter: UniversalRulerPainter(isHorizontal: true),
            ),
          ),
        ),
        
        Container(width: 2, height: 20, color: const Color.fromARGB(255, 33, 13, 92)),
      ],
    );
  }
}
