import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_main_title.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_section.dart';

/// Shared Guidelines screen for both Driver and Operator roles.
/// Accessible from the overflow menu (driver) and side drawer (operator).
/// When [isOperatorGuidelines] is true, shows only Operator Responsibilities
/// (used when operator clicks operator guidelines). Otherwise shows driver
/// guidelines (How to Park, How to Handover).
class GuidelinesScreen extends StatelessWidget {
  /// When true, shows only Operator Responsibilities section.
  /// When false (default), shows driver guidelines (How to Park, How to Handover).
  final bool isOperatorGuidelines;

  const GuidelinesScreen({super.key, this.isOperatorGuidelines = false});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Scaffold(
      backgroundColor: AppColors.primarySurface,
      appBar: CustomAppBar(
        showOverflowMenu: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildContent(t),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(AppTranslationsNotifier t) {
    if (isOperatorGuidelines) {
      // Operator: show only Operator Responsibilities
      return [
        GuidelinesMainTitle(title: t.get(TextConstants.guidelines)),
        const SizedBox(height: 24),
        GuidelinesSection(
          title: t.get(TextConstants.operatorResponsibilities),
          icon: Icons.admin_panel_settings,
          items: const [
            'English',
            '1. Monitor all parking & car handover requests',
            '2. Assign nearest available driver',
            '3. Ensure drivers accept and complete tasks',
            '4. Handle missed or manual requests',
            '5. Support drivers in case of issues',
            'हिंदी',
            '1. सभी पार्किंग और गाड़ी देने की रिक्वेस्ट देखें',
            '2. नजदीकी उपलब्ध ड्राइवर को असाइन करें',
            '3. ड्राइवर रिक्वेस्ट Accept करे और काम पूरा करे यह देखें',
            '4. मिस या मैनुअल रिक्वेस्ट संभालें',
            '5. समस्या होने पर ड्राइवर की मदद करें',
            'తెలుగు',
            '1. అన్ని పార్కింగ్ మరియు కారు ఇవ్వడం రిక్వెస్ట్లను చూడండి',
            '2. దగ్గరలో ఉన్న డ్రైవర్ కు అసైన్ చేయండి',
            '3. డ్రైవర్ రిక్వెస్ట్ Accept చేసి పని పూర్తి చేశాడో చూడండి',
            '4. మిస్ అయిన లేదా మాన్యువల్ రిక్వెస్ట్లను నిర్వహించండి',
            '5. సమస్యలు వచ్చినప్పుడు డ్రైవర్లకు సహాయం చేయండి',
          ],
        ),
      ];
    }

    // Driver: show How to Park and How to Handover (no Operator Responsibilities)
    // Keep English for driver screen - translations only on operator screen
    return [
      GuidelinesMainTitle(title: t.get(TextConstants.guidelines)),
      const SizedBox(height: 24),
      GuidelinesSection(
        title: 'How to Park',
        icon: Icons.local_parking,
        items: const [
          'English',
          '1. Give QR valet card to customer',
          '2. Sit in car and scan QR in app',
          '3. Park the vehicle',
          '4. Take clear photo of car & number plate',
          '5. Enter correct parking location (B1/B2/B3)',
          '6. Press Submit',
          'हिंदी',
          '1. ग्राहक को QR वैलेट कार्ड दें',
          '2. कार में बैठकर ऐप से QR स्कैन करें',
          '3. गाड़ी पार्क करें',
          '4. कार और नंबर प्लेट की साफ फोटो लें.',
          '5. सही पार्किंग लोकेशन डालें (B1/B2/B3)',
          '6. "Submit" दबाएं',
          'తెలుగు',
          '1. కస్టమర్ కు QR వాలెట్ కార్డ్ ఇవ్వండి',
          '2. కారులో కూర్చుని యాప్ లో QR స్కాన్ చేయండి',
          '3. వాహనాన్ని పార్క్ చేయండి',
          '4. కారు & నంబర్ ప్లేట్ స్పష్టమైన ఫోటో తీయండి',
          '5. సరైన పార్కింగ్ లొకేషన్ నమోదు చేయండి (B1/B2/B3)',
          '6. "Submit" నొక్కండి',
        ],
      ),
      const SizedBox(height: 20),
      GuidelinesSection(
        title: 'How to Handover',
        icon: Icons.handshake,
        items: const [
          'English',
          '1. Accept request in app',
          '2. Collect keys from supervisor',
          '3. Bring car to pickup area',
          '4. Tap "Confirm Arrival"',
          '5. Give car & keys to customer',
          '6. Collect QR valet card back',
          'हिंदी',
          '1. ऐप में रिक्वेस्ट Accept करें',
          '2. सुपरवाइज़र से चाबियां लें',
          '3. गाड़ी को पिकअप एरिया में लाएं',
          '4. "Confirm Arrival" दबाएं',
          '5. ग्राहक को गाड़ी और चाबी दें',
          '6. ग्राहक से QR कार्ड वापस लें',
          'తెలుగు',
          '1. యాప్ లో రిక్వెస్ట్ Accept చేయండి',
          '2. సూపర్వైజర్ వద్ద నుంచి కీలు తీసుకోండి',
          '3. కారును పికప్ ప్రాంతానికి తీసుకురండి',
          '4. "Confirm Arrival" నొక్కండి',
          '5. కస్టమర్ కు కారు మరియు కీలు ఇవ్వండి',
          '6. QR వాలెట్ కార్డ్ తిరిగి తీసుకోండి',
        ],
      ),
    ];
  }
}
