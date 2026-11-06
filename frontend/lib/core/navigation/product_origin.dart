/// How the user reached a product page. Products opened by scanning (or again
/// from the scan history) go into the scan history.
enum ProductOrigin {
  scan,
  search,
  history;

  bool get recordsScan => this != ProductOrigin.search;
}
