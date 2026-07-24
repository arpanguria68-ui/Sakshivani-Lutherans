String cleanCatechismMarkdown(String source) {
  return source
      .replaceAll('[cite_start]', '')
      .replaceAll(RegExp(r'\[cite:\s*[^\]]*\]'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
