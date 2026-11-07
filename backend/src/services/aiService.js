const geminiClient = require('./ai/geminiClient');
const { SYSTEM_INSTRUCTION, ANALYSIS_SCHEMA, buildPrompt } = require('./ai/analysisPrompt');
const { parseAnalysis } = require('./ai/analysisParser');

const analyzeProduct = async (product, fns) => {
    const responseText = await geminiClient.generateJson({
        systemInstruction: SYSTEM_INSTRUCTION,
        prompt: buildPrompt(product, fns),
        schema: ANALYSIS_SCHEMA
    });

    return parseAnalysis(responseText);
};

module.exports = { analyzeProduct };
