const double _waterMlPerKg = 35;

double calculateWaterTargetMl({required double weightKg}) => weightKg * _waterMlPerKg;
