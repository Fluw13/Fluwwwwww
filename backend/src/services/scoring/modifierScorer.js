const { pointsRange } = require('./pointsLookup');
const { PROTEIN_BASELINE_LIMIT, PROTEIN_FVNL_POINTS_OVERRIDE } = require('./scoringRules');

const NOT_APPLICABLE = { min: 0, max: 0 };

const rangeOf = (slot) => (slot ? pointsRange(slot.measure, slot.table) : null);

const scoreModifiers = (modifierSlots) => ({
    fvnl: rangeOf(modifierSlots.fvnl),
    protein: rangeOf(modifierSlots.protein),
    fiber: rangeOf(modifierSlots.fiber)
});

// HSR v9: protein points count when baseline < 13, or when baseline >= 13 and FVNL points >= 5.
const isProteinEligible = (baselinePoints, fvnlPoints) =>
    baselinePoints < PROTEIN_BASELINE_LIMIT || fvnlPoints >= PROTEIN_FVNL_POINTS_OVERRIDE;

const rawScoreAt = ({ baseline, fvnl, protein, fiber, proteinApplies }) => {
    const proteinPoints = proteinApplies && isProteinEligible(baseline, fvnl) ? protein : 0;
    return baseline - fvnl - proteinPoints - fiber;
};

// R = B - V - P - F decreases as modifiers grow and as B shrinks (which can also unlock protein), so the
// best and worst achievable raw scores are reached at the opposite ends of every interval.
const rawScoreBounds = (baseline, modifiers) => {
    const fvnl = modifiers.fvnl ?? NOT_APPLICABLE;
    const protein = modifiers.protein ?? NOT_APPLICABLE;
    const fiber = modifiers.fiber ?? NOT_APPLICABLE;
    const proteinApplies = modifiers.protein !== null;

    return {
        best: rawScoreAt({ baseline: baseline.min, fvnl: fvnl.max, protein: protein.max, fiber: fiber.max, proteinApplies }),
        worst: rawScoreAt({ baseline: baseline.max, fvnl: fvnl.min, protein: protein.min, fiber: fiber.min, proteinApplies }),
        proteinEligibility: proteinApplies
            ? [isProteinEligible(baseline.min, fvnl.max), isProteinEligible(baseline.max, fvnl.min)]
            : [false, false]
    };
};

module.exports = { scoreModifiers, rawScoreBounds, isProteinEligible };
