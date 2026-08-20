/// All available custom font families in Null Notes.
/// Copied from `_ApplePerfection/fonts` and configured in `pubspec.yaml`.
class AppFonts {
  // --- Apple San Francisco Family ---
  static const String sfPro = 'SFPro';
  static const String sfProDisplay = 'SFProDisplay';
  static const String sfProText = 'SFProText';
  static const String sfProRounded = 'SFProRounded';

  // --- Clean Sans / Modern UI ---
  static const String inter = 'Inter';
  static const String lato = 'Lato';
  static const String montserrat = 'Montserrat';
  static const String montserratAlternates = 'MontserratAlternates';
  static const String poppins = 'Poppins';
  static const String futura = 'Futura';
  static const String helvetica = 'Helvetica';
  static const String gotham = 'Gotham';
  static const String coolvetica = 'Coolvetica';
  static const String basementGrotesque = 'BasementGrotesque';
  static const String europaNova = 'EuropaNova';
  static const String novecento = 'Novecento';
  static const String tacticSans = 'TacticSans';
  static const String nexa = 'Nexa';
  static const String bebasNeue = 'BebasNeue';

  // --- Editorial & Serif ---
  static const String beatrice = 'Beatrice';
  static const String kaftan = 'Kaftan';
  static const String timesNewRoman = 'TimesNewRoman';
  static const String foreverFreedom = 'ForeverFreedom';

  // --- Display & Condensed / Heavy ---
  static const String impact = 'Impact';
  static const String lemonMilk = 'LemonMilk';
  static const String morganite = 'Morganite';
  static const String monoton = 'Monoton';
  static const String quicking = 'Quicking';
  static const String runtime = 'Runtime';
  static const String refile = 'Refile';
  static const String skiwar = 'Skiwar';
  static const String trevon = 'Trevon';
  static const String melanin = 'Melanin';
  static const String nevanta = 'Nevanta';

  // --- Expressive, Handwritten & Script ---
  static const String lobster = 'Lobster';
  static const String edwardianScript = 'EdwardianScript';
  static const String grestalScript = 'GrestalScript';
  static const String beautyMountains = 'BeautyMountains';
  static const String aloevera = 'Aloevera';
  static const String agitha = 'Agitha';
  static const String avifan = 'Avifan';
  static const String candyCane = 'CandyCane';
  static const String comicSansMS = 'ComicSansMS';
  static const String feyra = 'Feyra';
  static const String glasskin = 'Glasskin';
  static const String helloChristmas = 'HelloChristmas';
  static const String maison = 'Maison';
  static const String orletta = 'Orletta';
  static const String sacrifice = 'Sacrifice';
  static const String salcio = 'Salcio';
  static const String silkroad = 'Silkroad';

  /// List of all registered font family names
  static const List<String> all = [
    sfProDisplay,
    sfProText,
    sfProRounded,
    sfPro,
    inter,
    lato,
    montserrat,
    montserratAlternates,
    poppins,
    futura,
    helvetica,
    gotham,
    coolvetica,
    basementGrotesque,
    europaNova,
    novecento,
    tacticSans,
    nexa,
    bebasNeue,
    beatrice,
    kaftan,
    timesNewRoman,
    foreverFreedom,
    impact,
    lemonMilk,
    morganite,
    monoton,
    quicking,
    runtime,
    refile,
    skiwar,
    trevon,
    melanin,
    nevanta,
    lobster,
    edwardianScript,
    grestalScript,
    beautyMountains,
    aloevera,
    agitha,
    avifan,
    candyCane,
    comicSansMS,
    feyra,
    glasskin,
    helloChristmas,
    maison,
    orletta,
    sacrifice,
    salcio,
    silkroad,
  ];

  /// Categorized font groups for easy selection and typography previews
  static const Map<String, List<String>> categories = {
    'Apple SF Pro': [
      sfProDisplay,
      sfProText,
      sfProRounded,
      sfPro,
    ],
    'Modern Sans': [
      inter,
      montserrat,
      montserratAlternates,
      poppins,
      futura,
      helvetica,
      gotham,
      lato,
      coolvetica,
      basementGrotesque,
      europaNova,
      novecento,
      tacticSans,
      nexa,
      bebasNeue,
    ],
    'Serif & Editorial': [
      beatrice,
      kaftan,
      timesNewRoman,
      foreverFreedom,
    ],
    'Display & Heavy': [
      impact,
      lemonMilk,
      morganite,
      monoton,
      quicking,
      runtime,
      refile,
      skiwar,
      trevon,
      melanin,
      nevanta,
    ],
    'Script & Creative': [
      lobster,
      edwardianScript,
      grestalScript,
      beautyMountains,
      aloevera,
      agitha,
      avifan,
      candyCane,
      comicSansMS,
      feyra,
      glasskin,
      helloChristmas,
      maison,
      orletta,
      sacrifice,
      salcio,
      silkroad,
    ],
  };
}
