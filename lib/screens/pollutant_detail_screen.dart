import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/small_card.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/air_quality_home.dart';

class _PollutantInfo {
  final String name;
  final String description;
  final String sources;
  final String healthEffects;

  const _PollutantInfo({
    required this.name,
    required this.description,
    required this.sources,
    required this.healthEffects,
  });
}

final Map<String, _PollutantInfo> _pollutantInfo = {
  'pm25': const _PollutantInfo(
    name: 'PM2.5',
    description: 'Pył zawieszony o średnicy cząstek nieprzekraczającej 2,5 mikrometra. '
        'Ze względu na niewielkie rozmiary cząstki te mogą przenikać przez barierę pęcherzykowo-włośniczkową '
        'do krwioobiegu i rozprzestrzeniać się po całym organizmie.',
    sources: 'Głównie ze spalania paliw kopalnych w transporcie, energetyce i przemyśle, '
        'a także z pożarów lasów i ogrzewania domów.',
    healthEffects: 'Związane z chorobami układu krążenia i oddechowego. '
        'Długotrwała ekspozycja może prowadzić do zmniejszenia wydolności płuc, '
        'zaostrzenia astmy, udaru mózgu i przedwczesnej śmierci.',
  ),
  'pm10': const _PollutantInfo(
    name: 'PM10',
    description: 'Pył zawieszony o średnicy cząstek nieprzekraczającej 10 mikrometrów. '
        'Cząstki te są na tyle małe, aby przenikać przez górne drogi oddechowe '
        'i osadzać się w oskrzelach oraz płucach.',
    sources: 'Pochodzi z procesów mechanicznych takich jak ścieranie opon i nawierzchni dróg, '
        'prace budowlane, rolnictwo, a także z emisji przemysłowych.',
    healthEffects: 'Podrażnienie dróg oddechowych, kaszel, duszności. '
        'Może zaostrzać objawy astmy i przewlekłej obturacyjnej choroby płuc (POChP).',
  ),
  'o3': const _PollutantInfo(
    name: 'Ozon (O₃)',
    description: 'Gaz występujący w dwóch warstwach atmosfery – ozon stratosferyczny '
        'chroni nas przed promieniowaniem UV, natomiast ozon przygruntowy (troposferyczny) '
        'jest szkodliwym zanieczyszczeniem powstającym w wyniku reakcji fotochemicznych.',
    sources: 'Powstaje w wyniku reakcji tlenków azotu (NOx) i lotnych związków organicznych '
        '(VOCs) pod wpływem promieniowania słonecznego. Nasila się w gorące, słoneczne dni.',
    healthEffects: 'Podrażnia drogi oddechowe, powoduje kaszel, ból gardła i zmniejszenie '
        'wydolności płuc. Szczególnie niebezpieczny dla osób z astmą i dzieci.',
  ),
  'no2': const _PollutantInfo(
    name: 'Dwutlenek azotu (NO₂)',
    description: 'Czerwono-brązowy gaz o ostrym zapachu, powstający głównie podczas '
        'spalania paliw w wysokich temperaturach. Jest prekursorem powstawania ozonu '
        'przygruntowego i smogu fotochemicznego.',
    sources: 'Głównym źródłem są spaliny samochodowe (szczególnie silniki diesla), '
        'elektrownie i zakłady przemysłowe.',
    healthEffects: 'Działa drażniąco na drogi oddechowe, zwiększa podatność na infekcje '
        'układu oddechowego oraz nasila objawy astmy.',
  ),
  'so2': const _PollutantInfo(
    name: 'Dwutlenek siarki (SO₂)',
    description: 'Bezbarwny gaz o charakterystycznym, duszącym zapachu. '
        'Powstaje głównie podczas spalania paliw kopalnych zawierających siarkę – '
        'przede wszystkim węgla i ropy naftowej.',
    sources: 'Energetyka oparta na węglu, przemysł ciężki, rafinerie oraz ogrzewanie domów '
        'paliwami stałymi.',
    healthEffects: 'Powoduje podrażnienie oczu, nosa i gardła oraz skurcz oskrzeli. '
        'Szczególnie szkodliwy dla osób z astmą i chorobami układu oddechowego.',
  ),
  'co': const _PollutantInfo(
    name: 'Tlenek węgla (CO)',
    description: 'Bezbarwny i bezwonny gaz powstający w wyniku niepełnego spalania '
        'paliw zawierających węgiel. Jest trujący nawet w niewielkich stężeniach.',
    sources: 'Silniki spalinowe (szczególnie na biegu jałowym), piece węglowe i gazowe, '
        'pożary lasów, dym tytoniowy.',
    healthEffects: 'Łączy się z hemoglobiną 200-250 razy silniej niż tlen, '
        'ograniczając dopływ tlenu do tkanek. Powoduje bóle głowy, zawroty, '
        'zaburzenia koncentracji, a w wysokich stężeniach – utratę przytomności i śmierć.',
  ),
};

class PollutantDetailScreen extends StatelessWidget {
  final PollutantCardData data;
  final VoidCallback? onBack;

  const PollutantDetailScreen({super.key, required this.data, this.onBack});

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = _pollutantInfo[data.code.toLowerCase()];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => _handleBack(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.of(context, AppIconKind.chevronLeft),
                  size: 20,
                  color: AppColors.systemOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  "Powrót",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.systemOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
        leadingWidth: 100,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 16),

            SmallCard(
              title: data.title,
              value: data.subtitle.isNotEmpty
                  ? data.subtitle
                  : data.value,
              subtitle: data.subtitle.isNotEmpty
                  ? data.value
                  : null,
              iconKind: data.iconKind,
              badgeForeground: data.badgeForeground,
              badgeBackground: data.badgeBackground,
            ),

            if (info != null) ...[
              const SizedBox(height: 20),

              _Section(
                colorScheme: colorScheme,
                title: 'Czym jest ${info.name}?',
                body: info.description,
              ),

              const SizedBox(height: 12),

              _Section(
                colorScheme: colorScheme,
                title: 'Źródła',
                body: info.sources,
              ),

              const SizedBox(height: 12),

              _Section(
                colorScheme: colorScheme,
                title: 'Wpływ na zdrowie',
                body: info.healthEffects,
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final ColorScheme colorScheme;
  final String title;
  final String body;

  const _Section({
    required this.colorScheme,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
