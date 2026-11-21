import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';

/// One formula or rule, with the published sources it follows. No source means Fluw chose it, which the text says.
final class MethodItem {
  const MethodItem(this.title, this.text, {this.sources = const []});

  final String title;
  final String text;
  final List<String> sources;
}

final class MethodSection {
  const MethodSection(this.title, this.items);

  final String title;
  final List<MethodItem> items;
}

String _percent(double share) => '${formatWhole(share * 100)}%';

const String _iom2005 =
    'Institute of Medicine (2005), Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, '
    'Cholesterol, Protein, and Amino Acids.';

/// Every formula behind the daily targets and the day review, as the code applies them. Kept as data so the screen
/// only lays it out; the thresholds Fluw chose come from `fluw_thresholds.dart`.
final List<MethodSection> methodologySections = [
  const MethodSection('Năng lượng', [
    MethodItem(
      'Năng lượng cơ bản (BMR)',
      'Công thức Mifflin–St Jeor. Nam: 10 × cân nặng (kg) + 6.25 × chiều cao (cm) − 5 × tuổi + 5. Nữ: như trên '
          'nhưng trừ 161 thay vì cộng 5. Giới tính Khác: theo công thức Nam hoặc Nữ bạn chọn. Sai số có thể từ 10% '
          'trở lên, nhất là ở người trên 75 tuổi.',
      sources: ['Mifflin MD, St Jeor ST và cs. (1990), Am J Clin Nutr 51:241–247.'],
    ),
    MethodItem(
      'Năng lượng mỗi ngày (TDEE)',
      'TDEE = BMR × hệ số vận động thông dụng (ước tính, không phải hệ số của FAO/WHO): ít vận động 1.2, hoạt động '
          'nhẹ 1.375, hoạt động vừa 1.55, hoạt động nhiều 1.725, hoạt động rất cao 1.9. Mức vận động tính cả công '
          'việc, đi lại và tập luyện.',
    ),
    MethodItem(
      'Mục tiêu calo',
      'Giữ cân: bằng TDEE. Tăng hoặc giảm cân: cộng hoặc trừ tốc độ (kg/tuần) × 7,700 kcal ÷ 7 ngày, tốc độ tối đa '
          '0.5 kg/tuần (khoảng 550 kcal/ngày).',
    ),
    MethodItem(
      'Mức tối thiểu khi giảm cân',
      'Mục tiêu không thấp hơn BMR và không thấp hơn 1,200 kcal/ngày (nữ) hoặc 1,500 kcal/ngày (nam); ăn thấp hơn '
          'cần bác sĩ theo dõi. Khi mức tối thiểu bằng hoặc cao hơn TDEE, mục tiêu giữ bằng TDEE (mức giữ cân).',
      sources: [
        'NIH/NHLBI (2000), The Practical Guide: Identification, Evaluation, and Treatment of Overweight and Obesity '
            'in Adults.',
      ],
    ),
    MethodItem(
      'Số tuần ước tính',
      'Mức chênh với TDEE × 7 ÷ 7,700 kcal cho mỗi kg. Cân thường thay đổi chậm dần, nên số tuần chỉ là ước tính '
          'tối thiểu.',
      sources: ['Hall KD và cs. (2011), The Lancet 378:826–837.'],
    ),
  ]),
  const MethodSection('Protein (đạm)', [
    MethodItem(
      'Cách tính',
      'Protein (g/ngày) = cân nặng tham chiếu × hệ số theo hình thức tập. Fluw coi là đủ khi đạt cận dưới; đây là '
          'mức tham khảo, không phải giới hạn tối đa.',
    ),
    MethodItem('Không tập thường xuyên: 0.8 g/kg', 'Nhu cầu khuyến nghị (RDA) cho người lớn.', sources: [_iom2005]),
    MethodItem(
      'Sức bền (chạy bộ, đạp xe, bơi): 1.2–1.4 g/kg',
      'Mức Fluw dùng, thấp hơn khuyến nghị chung 1.4–2.0 g/kg cho người tập luyện.',
      sources: ['Jäger R và cs. (2017), ISSN Position Stand: protein and exercise, J Int Soc Sports Nutr 14:20.'],
    ),
    MethodItem(
      'Gym, tăng cơ: 1.6–2.2 g/kg',
      'Theo phân tích gộp về tập sức mạnh; 2.2 g/kg là cận trên của khoảng tin cậy, không phải mức bắt buộc.',
      sources: ['Morton RW và cs. (2018), Br J Sports Med 52:376–384.'],
    ),
    MethodItem(
      'Gym kèm giảm cân (giảm mỡ giữ cơ): 1.6–2.4 g/kg',
      'Khi thâm hụt calo, ăn nhiều đạm hơn giúp giữ cơ.',
      sources: ['Hector AJ, Phillips SM (2018), Int J Sport Nutr Exerc Metab 28:170–177.'],
    ),
    MethodItem(
      'Cân nặng tham chiếu',
      'Đạm và nước tính theo số nhỏ hơn giữa cân nặng thật và 24.9 × chiều cao (m)², tức cân nặng ở BMI 24.9: các '
          'khoảng đạm trên đến từ nghiên cứu trên người phần lớn không béo phì. BMR và BMI vẫn theo cân nặng thật. '
          'Khi khoảng đạm cao hơn 1.2 g/kg, Fluw nhắc người có bệnh thận hỏi bác sĩ trước.',
    ),
  ]),
  const MethodSection('Chất béo, đường, carb, natri', [
    MethodItem(
      'Chất béo: 25% năng lượng mục tiêu ÷ 9',
      'Nằm trong khoảng 20–35% năng lượng của khuyến nghị.',
      sources: [_iom2005],
    ),
    MethodItem(
      'Béo bão hòa: dưới 10% năng lượng ÷ 9',
      'Có mỡ máu cao: dưới 7%.',
      sources: [
        'WHO (2023), Saturated fatty acid and trans-fatty acid intake for adults and children: WHO guideline.',
        'NCEP (2001), Third Report of the Expert Panel on Detection, Evaluation, and Treatment of High Blood '
            'Cholesterol in Adults (ATP III).',
      ],
    ),
    MethodItem(
      'Đường tổng (mức gợi ý): dưới 10% năng lượng ÷ 4',
      'Có tiểu đường hoặc bật giảm ngọt: dưới 5%. WHO khuyên đường tự do (đường thêm vào, mật ong, nước ép) dưới '
          '10% năng lượng, tốt hơn dưới 5%. Nhãn chỉ ghi đường tổng (gồm cả đường sữa, đường trái cây), nên đây chỉ '
          'là mức gợi ý: cao hơn thì Fluw ghi "Cao hơn mức gợi ý". Đây không phải chế độ ăn cho người tiểu đường; '
          'lượng carb phù hợp do bác sĩ chỉ định.',
      sources: ['WHO (2015), Guideline: Sugars intake for adults and children.'],
    ),
    MethodItem(
      'Carb (bột đường)',
      '(Năng lượng mục tiêu − protein cận dưới × 4 − chất béo × 9) ÷ 4. Carb gồm tinh bột và đường. Ra số âm thì '
          'ghi "Chưa tính được". Số liệu USDA tính cả chất xơ vào carb; Open Food Facts thì không.',
    ),
    MethodItem(
      'Natri: tối đa 2,000 mg/ngày',
      'Khoảng 5 g muối, cho mọi người lớn.',
      sources: ['WHO (2012), Guideline: Sodium intake for adults and children.'],
    ),
  ]),
  const MethodSection('Nước và BMI', [
    MethodItem(
      'Nước: 35 ml × cân nặng tham chiếu',
      'Tổng lượng nước mỗi ngày, gồm cả nước trong thức ăn; khoảng 70–80% đến từ đồ uống. 35 ml/kg là mức Fluw '
          'chọn; để đối chiếu, EFSA khuyến nghị tổng 2.0 lít (nữ) và 2.5 lít (nam) mỗi ngày. Người bệnh tim, thận '
          'cần hỏi bác sĩ về lượng nước.',
      sources: ['EFSA (2010), Scientific Opinion on Dietary Reference Values for water, EFSA Journal 8(3):1459.'],
    ),
    MethodItem(
      'BMI thang châu Á',
      'BMI = cân nặng (kg) ÷ chiều cao (m)², cắt xuống 0.1. Dưới 18.5: thiếu cân; 18.5 đến dưới 23: bình thường; '
          '23 đến dưới 25: thừa cân; từ 25: béo phì. Fluw không cho đặt mục tiêu giảm cân xuống dưới BMI 18.5, hay '
          'giảm cân khi đang thiếu cân.',
      sources: [
        'WHO khu vực Tây Thái Bình Dương (2000), The Asia-Pacific perspective: redefining obesity and its treatment.',
        'Bộ Y tế (2022), Quyết định 2892/QĐ-BYT.',
      ],
    ),
  ]),
  MethodSection('Ngưỡng Fluw tự chọn (không có nguồn)', [
    const MethodItem(
      'So theo số hiện trên màn',
      'kcal và mg làm tròn đến đơn vị, gam đến 0.1 g, rồi mới so: 25.0 / 25.0 g là chưa vượt, 25.1 / 25.0 g là vượt.',
    ),
    MethodItem(
      'Năng lượng ±${_percent(calorieToleranceShare)}',
      'Đánh giá ngày coi là đạt mục tiêu calo khi trong khoảng ±${_percent(calorieToleranceShare)}, vì mục tiêu cũng '
          'chỉ là ước tính.',
    ),
    MethodItem(
      'Dưới ${_percent(underLoggedShare)} mục tiêu calo',
      'Đánh giá ngày ghi "Có thể chưa ghi đủ món", không kết luận bạn ăn quá ít.',
    ),
    MethodItem(
      'Từ ${_percent(nearLimitShare)} mức gợi ý đường hoặc giới hạn natri',
      'Trang Chủ gợi ý hạn chế đồ ngọt hoặc muối. Có tiểu đường, giảm ngọt hay huyết áp cao thì luôn gợi ý.',
    ),
    MethodItem(
      'Buổi tối còn từ ${formatWhole(eveningKcalLeft)} kcal',
      'Từ $eveningStartHour giờ, nếu còn từ ${formatWhole(eveningKcalLeft)} kcal so với mục tiêu, Trang Chủ nhắc '
          'đừng bỏ bữa tối.',
    ),
    MethodItem(
      'Một khẩu phần từ ${_percent(watchedPortionShare)}',
      'Món chiếm từ ${_percent(watchedPortionShare)} chỉ số bạn đang theo dõi (đường khi tiểu đường hoặc giảm ngọt, '
          'natri khi huyết áp cao, béo bão hòa khi mỡ máu cao) được tô màu cảnh báo ở màn chi tiết.',
    ),
  ]),
];
