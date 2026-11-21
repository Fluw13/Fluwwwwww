/// The amounts, in g or ml, a portion may have: below 1 is a typo, above 2000 is not one meal.
const double minPortion = 1;
const double maxPortion = 2000;

bool isValidPortion(double amount) => amount >= minPortion && amount <= maxPortion;
