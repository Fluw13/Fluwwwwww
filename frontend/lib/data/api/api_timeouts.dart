/// Per-request time budgets. Until `/health` answers in this session the
/// server may still be cold-starting on Render (about 50 s), so the first
/// requests get a longer budget.
class ApiTimeouts {
  const ApiTimeouts({
    this.coldHealth = const Duration(seconds: 70),
    this.coldSearch = const Duration(seconds: 70),
    this.coldProduct = const Duration(seconds: 70),
    this.coldAnalysis = const Duration(seconds: 90),
    this.warmHealth = const Duration(seconds: 20),
    this.warmSearch = const Duration(seconds: 20),
    this.warmProduct = const Duration(seconds: 20),
    this.warmAnalysis = const Duration(seconds: 35),
  });

  final Duration coldHealth;
  final Duration coldSearch;
  final Duration coldProduct;
  final Duration coldAnalysis;
  final Duration warmHealth;
  final Duration warmSearch;
  final Duration warmProduct;
  final Duration warmAnalysis;

  Duration health({required bool serverAwake}) =>
      serverAwake ? warmHealth : coldHealth;

  Duration search({required bool serverAwake}) =>
      serverAwake ? warmSearch : coldSearch;

  Duration product({required bool serverAwake}) =>
      serverAwake ? warmProduct : coldProduct;

  Duration analysis({required bool serverAwake}) =>
      serverAwake ? warmAnalysis : coldAnalysis;
}
