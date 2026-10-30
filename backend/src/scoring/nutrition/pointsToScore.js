// Fluw's own conversion from Nutri-Score points to 0-100. Band edges match the 2023 A-E grade limits;
// inside a band the score falls linearly from scoreMax (best points) to scoreMin (worst points).
const BANDS = Object.freeze({
    food: [
        { pointsMin: -17, pointsMax: 0, scoreMin: 80, scoreMax: 100 },
        { pointsMin: 1, pointsMax: 2, scoreMin: 70, scoreMax: 79 },
        { pointsMin: 3, pointsMax: 10, scoreMin: 40, scoreMax: 69 },
        { pointsMin: 11, pointsMax: 18, scoreMin: 20, scoreMax: 39 },
        { pointsMin: 19, pointsMax: 55, scoreMin: 0, scoreMax: 19 }
    ],
    fat_oil_nuts_seeds: [
        { pointsMin: -17, pointsMax: -6, scoreMin: 80, scoreMax: 100 },
        { pointsMin: -5, pointsMax: 2, scoreMin: 70, scoreMax: 79 },
        { pointsMin: 3, pointsMax: 10, scoreMin: 40, scoreMax: 69 },
        { pointsMin: 11, pointsMax: 18, scoreMin: 20, scoreMax: 39 },
        { pointsMin: 19, pointsMax: 55, scoreMin: 0, scoreMax: 19 }
    ],
    // Only water reaches the top band for beverages, so the first band starts at 79.
    beverage: [
        { pointsMin: -18, pointsMax: 2, scoreMin: 70, scoreMax: 79 },
        { pointsMin: 3, pointsMax: 6, scoreMin: 40, scoreMax: 69 },
        { pointsMin: 7, pointsMax: 9, scoreMin: 20, scoreMax: 39 },
        { pointsMin: 10, pointsMax: 54, scoreMin: 0, scoreMax: 19 }
    ]
});

const WATER_SCORE = 100;

const findBand = (bands, points) => {
    const clamped = Math.min(bands[bands.length - 1].pointsMax, Math.max(bands[0].pointsMin, points));
    return bands.find((band) => clamped >= band.pointsMin && clamped <= band.pointsMax);
};

const pointsToScore = (table, points) => {
    const band = findBand(BANDS[table], points);
    const clamped = Math.min(band.pointsMax, Math.max(band.pointsMin, points));
    const span = band.pointsMax - band.pointsMin;
    const raw = band.scoreMax - ((clamped - band.pointsMin) * (band.scoreMax - band.scoreMin)) / span;

    return { value: Math.round(raw), band: { ...band } };
};

module.exports = { pointsToScore, WATER_SCORE };
