# PCOS theme + content update

Drop these files into the matching paths in wellness-saheli-app, overwriting
what's there, then run `flutter pub get` and `flutter analyze`.

## lib/theme/app_theme.dart
New palette pulled from the PCOS reference deck's colors (warm terracotta,
olive-sage, clay, warm parchment background) instead of the old lavender
palette. All existing AppColors names are kept (background, surface, primary,
accent, textPrimary, textSecondary, cardBorder, periodRed, moodYellow,
symptomOrange, ovulationTeal) plus two new ones: `sage` and `clay`. Since
every screen already reads colors through AppColors, this one file re-themes
the whole app. Headline font switched from Playfair Display to Fraunces
(warmer, more organic serif); body font switched from DM Sans to Jost
(geometric sans, closer to the deck's Century Gothic).

## lib/screens/pcos_screen.dart
Added six new info cards to the Information tab using content from the
reference deck that wasn't already covered: prevalence/family-risk stats,
a "conditions that look similar" differential-diagnosis card, the
Ferriman–Gallwey hirsutism scoring explanation, a BMI-risk-category card,
a fertility/OHSS/pregnancy-risk card, and a concrete monitoring-plan
checklist. All use the existing PcosCard/PcosLine/PcosTag components already
in the file — no new widgets introduced.

## lib/screens/protection_screen.dart
Two hardcoded hex colors (olive, tan) swapped for the new named
AppColors.sage / AppColors.clay tokens so they track the theme.

## lib/widgets/month_calendar.dart
Hardcoded period-dot color swapped for AppColors.periodRed.

## docs/reference/PCOS_reference_deck.pptx
The source deck itself, archived for reference/traceability.

## Not touched
- main.dart still wires a single light theme only (no dark variant) — same
  as before this change, not in scope here.
- upload-keystore.jks is sitting in your repo root and is public on GitHub.
  If that's your real release-signing key, pull it out of git history and
  rotate it — anyone can currently download it.
