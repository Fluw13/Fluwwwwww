// Thresholds Fluw chose itself, without a published source. FLuw can change them; the "Cách Fluw tính" screen reads
// them from here, so its text always matches the rules.

/// Calories count as on target within ±10% of the daily target: a day is never exactly on the number, and the target
/// itself is an estimate.
const double calorieToleranceShare = 0.10;

/// A day below half the calorie target was more likely logged in part than eaten that little, so the day review says
/// "Có thể chưa ghi đủ món" instead of "too little".
const double underLoggedShare = 0.5;

/// From this share of the sugar suggestion or the sodium limit, Trang Chủ advises cutting down.
const double nearLimitShare = 0.8;

/// From this hour, with at least [eveningKcalLeft] still to eat, Trang Chủ says how much is left for dinner.
const int eveningStartHour = 18;
const double eveningKcalLeft = 300;

/// One portion taking this share of a nutrient the user's conditions watch is highlighted on the food detail.
const double watchedPortionShare = 0.5;
