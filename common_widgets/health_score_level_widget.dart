import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class HealthScoreLevelWidget extends StatefulWidget {
  final double healtFactor;
  HealthScoreLevelWidget({@required this.healtFactor});
  @override
  _HealthScoreLevelWidgetState createState() => _HealthScoreLevelWidgetState();
}

class _HealthScoreLevelWidgetState extends State<HealthScoreLevelWidget> {
  // RangeValues _currentRangeValues = const RangeValues(40, 80);
  @override
  Widget build(BuildContext context) {

    // print(widget.healtFactor);
    int _currentStep = 10 - widget.healtFactor.toInt();
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Health Factor : ${widget.healtFactor}",
          style: Theme.of(context).textTheme.headline1.copyWith(
              fontWeight: FontWeight.bold, color: Colours.aave_purple),
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Riskier",
              style: Theme.of(context)
                  .textTheme
                  .subtitle2
                  .copyWith(color: Colours.red),
            ),
            Text("Safer",
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(color: Colours.green))
          ],
        ),
        SizedBox(
          height: 10,
        ),
        StepProgressIndicator(
          totalSteps: 5,
          currentStep: widget.healtFactor.toInt(),
          selectedColor: Colours.aave_purple
          // unselectedColor: Colors.red,
        )
      ],
    ));
  }
}
