// Fluw's own choice; EFSA 2010 gives 2.0 L (women) and 2.5 L (men) of total water a day, food included.
const double _waterMlPerKg = 35;

/// Total water a day, food included. [weightKg] is the reference weight, so it stops growing above BMI 24.9.
double calculateWaterTargetMl({required double weightKg}) => weightKg * _waterMlPerKg;
