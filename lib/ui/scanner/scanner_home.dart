import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_menu/scanner_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_menu/scanner_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_menu/scanner_menu_state.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_retrieval/scanner_retrieval_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_retrieval/scanner_retrieval_event.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_retrieval/scanner_retrieval_state.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_request.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/overflow_menu.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/profile_screen.dart';
import 'package:niloufer_valet_mobile/ui/scanner/scanner_qr_dialog.dart';
import 'package:niloufer_valet_mobile/ui/scanner/widgets/scanner_retrieval_request_card.dart';

/// Scanner role home screen: top bar (same style as driver) and menu with
/// Profile and Logout only.
class ScannerHomeScreen extends StatelessWidget {
  const ScannerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final logoSize = screenWidth > 1200
        ? screenWidth * 0.08
        : screenWidth > 600
            ? screenWidth * 0.12
            : screenWidth * 0.2;
    final iconSize = screenWidth > 1200
        ? screenWidth * 0.02
        : screenWidth > 600
            ? screenWidth * 0.035
            : screenWidth * 0.06;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScannerMenuBloc()),
        BlocProvider(
          create: (context) => ScannerRetrievalBloc(
            webSocketBloc: context.read<WebSocketBloc?>(),
          )..add(const ScannerRetrievalFetchRequested()),
        ),
      ],
      child: BlocListener<ScannerMenuBloc, ScannerMenuState>(
        listener: (context, state) {
          if (state is ScannerMenuLogoutSuccess) {
            SnackBars.showSuccessSnackBar(context, state.response.message);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            context.read<ScannerMenuBloc>().add(const ScannerMenuReset());
          } else if (state is ScannerMenuLogoutFailure) {
            SnackBars.showErrorSnackBar(context, state.message);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            context.read<ScannerMenuBloc>().add(const ScannerMenuReset());
          } else if (state is ScannerMenuAction) {
            if (state.action == ScannerMenuActionType.profile) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
              context.read<ScannerMenuBloc>().add(const ScannerMenuReset());
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.lightBeigeBackground,
          appBar: CustomAppBar(
            showLanguageIcon: true,
            logoSize: logoSize,
            iconSize: iconSize,
            actions: [
              const OverflowMenu(scannerMode: true),
              SizedBox(width: screenWidth * 0.04),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.025,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: TextComponent(
                    labelText: context
                        .watch<AppTranslationsNotifier>()
                        .get(TextConstants.scannerTapScanHint),
                    fontSize: screenWidth * 0.04,
                    color: AppColors.mutedText,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                // Scan button with horizontal padding (centered, button-style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Center(
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () async {
                          await ScannerQrDialog.show(context);
                          if (context.mounted) {
                            context.read<ScannerRetrievalBloc>().add(
                                  const ScannerRetrievalFetchRequested(),
                                );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.25,
                            vertical: size.height * 0.025,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: AppColors.white,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              TextComponent(
                                labelText: context
                                    .watch<AppTranslationsNotifier>()
                                    .get(TextConstants.scanTabLabel),
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Row(
                    children: [
                      TextComponent(
                        labelText: context
                            .watch<AppTranslationsNotifier>()
                            .get(TextConstants.retrievalRequest),
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Expanded(
                  child:
                      BlocBuilder<ScannerRetrievalBloc, ScannerRetrievalState>(
                    builder: (context, state) {
                      if (state is ScannerRetrievalLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (state is ScannerRetrievalError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextComponent(
                                  labelText: state.message,
                                  fontSize: screenWidth * 0.036,
                                  color: AppColors.error,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: size.height * 0.02),
                                TextButton.icon(
                                  onPressed: () => context
                                      .read<ScannerRetrievalBloc>()
                                      .add(
                                          const ScannerRetrievalFetchRequested()),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (state is ScannerRetrievalLoaded) {
                        final requests =
                            _sortedRequests(state.response.requests);
                        if (requests.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08),
                              child: TextComponent(
                                labelText: context
                                    .watch<AppTranslationsNotifier>()
                                    .get(TextConstants
                                        .noPendingRetrievalRequests),
                                fontSize: screenWidth * 0.038,
                                color: AppColors.mutedText,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.06,
                            0,
                            screenWidth * 0.06,
                            size.height * 0.02,
                          ),
                          itemCount: requests.length,
                          itemBuilder: (context, index) =>
                              ScannerRetrievalRequestCard(
                                  request: requests[index]),
                        );
                      }
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08),
                          child: TextComponent(
                            labelText: context
                                .watch<AppTranslationsNotifier>()
                                .get(TextConstants.scannerTapScanHint),
                            fontSize: screenWidth * 0.038,
                            color: AppColors.mutedText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Same status order as operator: RETRIEVAL_REQUESTED first, then ASSIGNED, ACCEPTED, ARRIVED.
  static int _statusOrder(String status) {
    switch (status.toUpperCase()) {
      case 'RETRIEVAL_REQUESTED':
        return 0;
      case 'ASSIGNED':
        return 1;
      case 'ACCEPTED':
        return 2;
      case 'ARRIVED':
        return 3;
      default:
        return 4;
    }
  }

  static List<RetrievalRequest> _sortedRequests(
      List<RetrievalRequest> requests) {
    final list = List<RetrievalRequest>.from(requests);
    list.sort(
        (a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
    return list;
  }
}
