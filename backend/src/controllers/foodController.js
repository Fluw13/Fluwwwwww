const createFoodController = ({ foodSearchService, barcodeService, recognitionService }) => ({
    search: async (request, response) => {
        response.json(await foodSearchService.search(request.query.q, { usdaQuery: request.query.en }));
    },
    lookUpBarcode: async (request, response) => {
        response.json(await barcodeService.lookUp(request.params.code));
    },
    recognize: async (request, response) => {
        response.json(await recognitionService.recognize({ image: request.body, contentType: request.get('content-type') }));
    },
});

module.exports = createFoodController;
