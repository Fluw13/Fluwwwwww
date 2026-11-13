const createFoodController = ({ foodSearchService, barcodeService }) => ({
    search: async (request, response) => {
        response.json(await foodSearchService.search(request.query.q));
    },
    lookUpBarcode: async (request, response) => {
        response.json(await barcodeService.lookUp(request.params.code));
    },
});

module.exports = createFoodController;
