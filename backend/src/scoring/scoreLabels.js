const INDICATOR_LABELS = Object.freeze({
    energy: 'Năng lượng',
    energyFromSaturatedFat: 'Năng lượng từ chất béo bão hòa',
    sugars: 'Đường',
    saturatedFat: 'Chất béo bão hòa',
    saturatedFatRatio: 'Tỷ lệ béo bão hòa trên tổng chất béo',
    salt: 'Muối',
    nonNutritiveSweeteners: 'Chất tạo ngọt không đường',
    proteins: 'Chất đạm',
    fiber: 'Chất xơ',
    fruitsVegetablesLegumes: 'Rau củ, quả, đậu'
});

const MISSING_LABELS = Object.freeze({
    'nutrition.productType': 'Danh mục sản phẩm (để xác định loại sản phẩm)',
    'nutrition.energy': 'Năng lượng',
    'nutrition.fat': 'Chất béo',
    'nutrition.saturatedFat': 'Chất béo bão hòa',
    'nutrition.sugars': 'Đường',
    'nutrition.salt': 'Muối hoặc natri',
    'nutrition.proteins': 'Chất đạm',
    'nutrition.fiber': 'Chất xơ',
    'nutrition.fruitsVegetablesLegumes': 'Tỷ lệ rau củ, quả, đậu',
    'nutrition.ingredients': 'Danh sách thành phần (để kiểm tra chất tạo ngọt)',
    'nutrition.preparedNutrition': 'Dinh dưỡng của sản phẩm sau khi pha chế',
    'additives.ingredients': 'Danh sách thành phần',
    'additives.recognizedIngredients': 'Danh sách thành phần nhận diện được (hơn một nửa thành phần chưa nhận diện)'
});

const PRODUCT_TYPE_LABELS = Object.freeze({
    food: 'Thực phẩm',
    beverage: 'Đồ uống',
    water: 'Nước',
    fat_oil_nuts_seeds: 'Dầu, mỡ và các loại hạt',
    cheese: 'Phô mai',
    red_meat: 'Thịt đỏ'
});

const LEVEL_LABELS = Object.freeze({
    good: 'Tốt',
    moderate: 'Trung bình',
    limit: 'Nên hạn chế'
});

const INDICATOR_NOTES = Object.freeze({
    proteinsNotCountedFood: 'Không tính vì tổng điểm trừ từ 11 trở lên (quy tắc Nutri-Score).',
    proteinsNotCountedFat: 'Không tính vì tổng điểm trừ từ 7 trở lên (quy tắc Nutri-Score cho dầu, mỡ, hạt).',
    proteinsRedMeatCap: 'Thịt đỏ: điểm đạm tối đa là 2 (quy tắc Nutri-Score).',
    estimatedFromIngredients: 'Ước tính từ danh sách thành phần (Open Food Facts).',
    saturatedFatFromZeroFat: 'Bằng 0 vì tổng chất béo bằng 0.',
    sugarsFromZeroCarbohydrates: 'Bằng 0 vì carbohydrate bằng 0.',
    saltFromSodium: 'Quy đổi từ natri × 2,5.',
    energyFromKcal: 'Quy đổi từ kcal × 4,184.',
    energyFromSaturatedFat: 'Tính bằng chất béo bão hòa × 37 kJ/g.',
    preparedProduct: 'Theo số liệu sau khi pha chế.'
});

const DISCLAIMER = 'Điểm Fluw là thông tin tham khảo, tính từ dữ liệu cộng đồng Open Food Facts theo công thức công khai, '
    + 'không phải chẩn đoán hay tư vấn y tế. Các phụ gia được liệt kê là chất được phép sử dụng; '
    + 'điểm phụ gia chỉ phản ánh mức độ sử dụng phụ gia, không đánh giá độ an toàn của từng chất.';

const toMissingItem = (key) => ({ key, label: MISSING_LABELS[key] });

module.exports = { INDICATOR_LABELS, PRODUCT_TYPE_LABELS, LEVEL_LABELS, INDICATOR_NOTES, DISCLAIMER, toMissingItem };
