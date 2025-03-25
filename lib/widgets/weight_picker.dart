import 'package:flutter/material.dart';
import 'ruler_painter.dart';

class WeightPicker extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onWeightSelected;

  const WeightPicker({
    Key? key,
    required this.initialWeight,
    required this.onWeightSelected,
  }) : super(key: key);

  @override
  _WeightPickerState createState() => _WeightPickerState();
}

class _WeightPickerState extends State<WeightPicker> {
  late double selectedWeight;
  final double minWeight = 30.0;
  final double maxWeight = 200.0;
  late double rulerOffset;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.initialWeight;
    rulerOffset = (selectedWeight - minWeight) * 10;
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
              double newWeight = (minWeight + rulerOffset / 10).clamp(
                minWeight,
                maxWeight,
              );
              selectedWeight = double.parse(newWeight.toStringAsFixed(1));
              rulerOffset = (selectedWeight - minWeight) * 10;
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
        
        Container(width: 2, height: 40, color: const Color.fromARGB(255, 33, 13, 92)),
      ],
    );
  }
}
