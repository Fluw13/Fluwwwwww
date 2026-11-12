/// Only [diabetes], [hypertension] and [dyslipidemia] change targets or trigger warnings; the others are kept as notes
/// because the food data has no purine, spiciness or glycaemic index to check against.
enum HealthCondition { diabetes, hypertension, dyslipidemia, stomach, lowBloodPressure, gout }
