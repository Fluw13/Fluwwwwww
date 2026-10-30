// Any change to a threshold, band, weight or data rule must bump this version and be recorded in docs/SCORING.md.
const SCORE_VERSION = 'fluw-score-1.0';

const SCORE_WEIGHTS = Object.freeze({ nutrition: 0.7, additives: 0.3 });

module.exports = { SCORE_VERSION, SCORE_WEIGHTS };
