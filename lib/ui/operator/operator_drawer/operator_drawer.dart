import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'operator_drawer_item.dart';

class OperatorDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const OperatorDrawer(
      {super.key, this.selectedIndex = 0, this.onItemSelected});

  // Menu item UI extracted to `OperatorDrawerItem` (operator_drawer_item.dart)

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final itemFontSize = isIOS ? 16.0 : 18.0;
    final itemRowHeight = isIOS ? 40.0 : 44.0;
    final itemIconSize = isIOS ? 30.0 : 35.0;
    final itemVerticalMargin = isIOS ? 3.0 : 4.0;
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              24,
              0,
              16,
            ),
            children: [
              OperatorDrawerItem(
                asset: 'assets/images/dashboard.png',
                title: t.get(TextConstants.dashboard),
                isSelected: selectedIndex == 0,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(0);
                },
              ),
              OperatorDrawerItem(
                asset: 'assets/images/slots.png',
                title: t.get(TextConstants.parkedCar),
                isSelected: selectedIndex == 1,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(1);
                },
              ),
              OperatorDrawerItem(
                asset: 'assets/images/drivers.png',
                title: t.get(TextConstants.valets),
                isSelected: selectedIndex == 2,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(2);
                },
              ),
              OperatorDrawerItem(
                asset: 'assets/images/cars.png',
                title: t.get(TextConstants.carLogs),
                isSelected: selectedIndex == 3,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(3);
                },
              ),
              OperatorDrawerItem(
                iconData: Icons.credit_card,
                title: t.get(TextConstants.cards),
                isSelected: selectedIndex == 10,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(10);
                },
              ),
              OperatorDrawerItem(
                iconData: Icons.groups,
                title: t.getByKey(
                  TextConstants.i18nKeyDriversGroup,
                  TextConstants.driversGroup,
                ),
                isSelected: selectedIndex == 9,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(9);
                },
              ),
              OperatorDrawerItem(
                iconData: Icons.schedule,
                title: t.getByKey('overtime', TextConstants.overTime),
                isSelected: selectedIndex == 4,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(4);
                },
              ),
              const SizedBox(height: 16),
              Divider(
                color: AppColors.black,
                thickness: 2,
                indent: 16,
                endIndent: 16,
              ),
              OperatorDrawerItem(
                asset: 'assets/images/profile.png',
                title: t.get(TextConstants.profile),
                isSelected: selectedIndex == 5,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(5);
                },
              ),
              OperatorDrawerItem(
                iconData: Icons.support_agent,
                title: t.getByKey('help', TextConstants.help),
                isSelected: selectedIndex == 6,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(6);
                },
              ),
              OperatorDrawerItem(
                iconData: Icons.menu_book_outlined,
                title: t.get(TextConstants.guidelines),
                isSelected: selectedIndex == 7,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(7);
                },
              ),
              OperatorDrawerItem(
                asset: 'assets/images/logout.png',
                title: t.get(TextConstants.logout),
                isSelected: selectedIndex == 8,
                fontSize: itemFontSize,
                rowHeight: itemRowHeight,
                iconSize: itemIconSize,
                verticalMargin: itemVerticalMargin,
                onTap: () {
                  Navigator.of(context).pop();
                  onItemSelected?.call(8);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
