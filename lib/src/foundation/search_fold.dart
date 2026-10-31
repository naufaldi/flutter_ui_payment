String foldForSearch(String value) {
  var result = value.toLowerCase();
  const groups = {
    'a': 'áàâäãåăạảấầẩẫậắằẳẵặ',
    'd': 'đ',
    'e': 'éèêëẹẻẽếềểễệ',
    'i': 'íìîïịỉĩ',
    'o': 'óòôöõøọỏốồổỗộớờởỡợơ',
    'u': 'úùûüũụủứừửữựư',
    'n': 'ñ',
    'c': 'ç',
    'y': 'ýỳỵỷỹ',
  };
  for (final entry in groups.entries) {
    for (final c in entry.value.split('')) {
      result = result.replaceAll(c, entry.key);
    }
  }
  return result;
}

bool matchesQuery(String folded, String query) =>
    folded.contains(foldForSearch(query).trim());
