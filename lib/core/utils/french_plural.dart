/// French singular/plural agreement.
///
/// `frenchPlural(1, 'unité', 'unités')` → `"1 unité"`.
/// `frenchPlural(7, 'unité', 'unités')` → `"7 unités"`.
/// `frenchPlural(0, 'unité', 'unités')` → `"0 unités"` (zéro is plural in
/// French).
String frenchPlural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';
