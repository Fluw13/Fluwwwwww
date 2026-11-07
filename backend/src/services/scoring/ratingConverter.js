const { RATING_BANDS, LOWEST_RATING } = require('./scoringRules');

const HIGHEST_RATING = 5;
const RATING_SPAN = HIGHEST_RATING - LOWEST_RATING;

const referenceRatingFor = (category, rawScore) => {
    const band = RATING_BANDS[category].find(([maxRawScore]) => rawScore <= maxRawScore);
    return band ? band[1] : LOWEST_RATING;
};

// FNS = round(((H - 0.5) / 4.5) * 10, 1): 0.5 maps to 0.0 and 5.0 maps to 10.0.
const toFnsScore = (referenceRating) => Math.round(((referenceRating - LOWEST_RATING) / RATING_SPAN) * 100) / 10;

module.exports = { referenceRatingFor, toFnsScore };
