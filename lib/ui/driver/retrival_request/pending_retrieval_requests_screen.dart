import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/api/driver/sessions_pending_api.dart';
import 'package:niloufer_valet_mobile/bloc/driver/pass_available_drivers/pass_available_drivers_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/pass_available_drivers/pass_available_drivers_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/pass_available_drivers/pass_available_drivers_state.dart';
import 'package:niloufer_valet_mobile/bloc/retrival_request/retrival_request_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/retrival_request/retrival_request_event.dart';
import 'package:niloufer_valet_mobile/bloc/retrival_request/retrival_requesy_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pending_session.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/services/vibration_controller.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/confirm_arrival/confirm_arrival_screen.dart';
import 'package:niloufer_valet_mobile/ui/driver/retrival_request/retrieval_request_sheet.dart';
import 'package:niloufer_valet_mobile/utils/session_converter.dart';

class PendingRetrievalRequestsScreen extends StatefulWidget {
  const PendingRetrievalRequestsScreen({super.key});

  @override
  State<PendingRetrievalRequestsScreen> createState() =>
      _PendingRetrievalRequestsScreenState();
}

class _PendingRetrievalRequestsScreenState
    extends State<PendingRetrievalRequestsScreen> {
  // Global retrieval sheet from DriverHome already handles newly assigned
  // sessions across routes. Keep local auto-sheet off to avoid duplicate
  // bottom sheets in Pending/Arrival flow.
  static const bool _enableLocalAssignedSheetAutoPopup = false;

  // List state — updated on every poll (no loading spinner after first load)
  List<PendingSession>? _retrievals;
  bool _isInitialLoading = true;
  Object? _error;

  // Sheet guard — prevents opening a second sheet while one is already visible
  bool _isShowingSheet = false;
  final Set<String> _assignmentSheetShownSessionIds = <String>{};

  static const Duration _pollInterval = Duration(seconds: 2);
  Timer? _pollTimer;
  final Map<String, String> _stablePhotoUrlBySessionId = <String, String>{};

  DateTime? _sessionFifoTime(PendingSession session) {
    final assignedAtRaw = (session.assignedAt ?? '').trim();
    if (assignedAtRaw.isNotEmpty) {
      final assignedAt = DateTime.tryParse(assignedAtRaw);
      if (assignedAt != null) return assignedAt;
    }
    final createdAtRaw = session.createdAt.trim();
    if (createdAtRaw.isNotEmpty) {
      return DateTime.tryParse(createdAtRaw);
    }
    return null;
  }

  int _compareSessionFifo(PendingSession a, PendingSession b) {
    final ta = _sessionFifoTime(a);
    final tb = _sessionFifoTime(b);
    if (ta == null && tb == null) {
      return a.sessionId.compareTo(b.sessionId);
    }
    if (ta == null) return 1;
    if (tb == null) return -1;
    final c = ta.compareTo(tb);
    if (c != 0) return c;
    return a.sessionId.compareTo(b.sessionId);
  }

  String _normalizePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final q = url.indexOf('?');
    return q < 0 ? url : url.substring(0, q);
  }

  String _retrievalRowSignature(PendingSession s) {
    final normalizedPhoto = _normalizePhotoUrl(_photoUrl(s));
    return [
      s.sessionId,
      s.status.trim().toUpperCase(),
      (s.taskType ?? '').trim().toUpperCase(),
      (s.parkingLocation ?? '').trim(),
      normalizedPhoto,
    ].join('|');
  }

  String _retrievalListSignature(List<PendingSession> sessions) {
    return sessions.map(_retrievalRowSignature).join('||');
  }

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentPoll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Data loading ────────────────────────────────────────────────────────

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isInitialLoading = true;
        _error = null;
      });
    }
    try {
      final res = await SessionsPendingApiService.getPendingSessions();
      if (!mounted) return;
      final list = res.sessions.where(_isRetrievalTask).toList()
        ..sort(_compareSessionFifo);

      final currentIds = list.map((s) => s.sessionId).toSet();
      _stablePhotoUrlBySessionId
          .removeWhere((sessionId, _) => !currentIds.contains(sessionId));

      final previous = _retrievals ?? const <PendingSession>[];
      final hasMeaningfulChange =
          _retrievalListSignature(previous) != _retrievalListSignature(list);

      if (!silent ||
          _isInitialLoading ||
          _retrievals == null ||
          hasMeaningfulChange) {
        setState(() {
          _retrievals = list;
          _isInitialLoading = false;
          _error = null;
        });
      }
      if (_enableLocalAssignedSheetAutoPopup) {
        _checkForNewAssignment(res.sessions);
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent)
        setState(() {
          _isInitialLoading = false;
          _error = e;
        });
    }
  }

  Future<void> _silentPoll() async {
    if (!mounted) return;
    await _load(silent: true);
  }

  Future<void> _refresh() => _load();

  // ─── Filter helpers ───────────────────────────────────────────────────────

  bool _isRetrievalTask(PendingSession session) {
    final taskType = (session.taskType ?? '').trim().toUpperCase();
    if (taskType.contains('RETRIEVAL') || taskType.contains('RETRIEVE')) {
      return true;
    }
    return session.isAccepted || session.isArrived;
  }

  /// A retrieval session that has just been assigned and not yet accepted/acted on.
  bool _isNewlyAssignedRetrieval(PendingSession session) {
    final taskType = (session.taskType ?? '').trim().toUpperCase();
    if (!taskType.contains('RETRIEVAL') && !taskType.contains('RETRIEVE')) {
      return false;
    }
    return !session.isAccepted &&
        !session.isArrived &&
        !session.isCheckedIn &&
        !session.isReparking;
  }

  // ─── Sheet logic ─────────────────────────────────────────────────────────

  void _checkForNewAssignment(List<PendingSession> sessions) {
    if (!mounted || _isShowingSheet) return;
    final newlyAssigned = sessions.where(_isNewlyAssignedRetrieval).toList()
      ..sort(_compareSessionFifo);
    final activeNewlyAssignedIds = newlyAssigned
        .map((s) => s.sessionId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Allow future sheets only when a session truly leaves the "newly assigned" state.
    _assignmentSheetShownSessionIds
        .removeWhere((id) => !activeNewlyAssignedIds.contains(id));

    if (newlyAssigned.isEmpty) return;
    final nextToShow = newlyAssigned.firstWhere(
      (session) => !_assignmentSheetShownSessionIds.contains(session.sessionId),
      orElse: () => newlyAssigned.first,
    );
    if (_assignmentSheetShownSessionIds.contains(nextToShow.sessionId)) {
      return;
    }
    _showAssignedSheet(nextToShow);
  }

  void _showAssignedSheet(PendingSession pendingSession) {
    if (_isShowingSheet || !mounted) return;
    _isShowingSheet = true;
    _assignmentSheetShownSessionIds.add(pendingSession.sessionId);

    final assignedSession = SessionConverter.pendingToAssigned(pendingSession);
    VibrationController.startRetrievalAlert();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => RetrivalRequestBloc()),
          BlocProvider(create: (_) => PassAvailableDriversBloc()),
        ],
        child: PopScope(
          canPop: false,
          child: _AssignedSheetBody(
            session: assignedSession,
            onAccepted: (DateTime acceptedAt) async {
              _isShowingSheet = false;
              VibrationController.stop();
              await _refresh();
              await _navigateToConfirmArrivalFifo(
                acceptedSessionId: assignedSession.id,
                acceptedAt: acceptedAt,
              );
            },
            onDismiss: () {
              _isShowingSheet = false;
              VibrationController.stop();
              _refresh();
            },
          ),
        ),
      ),
    ).then((_) {
      _isShowingSheet = false;
      VibrationController.stop();
    });
  }

  void _navigateToConfirmArrival(AssignedSession session, DateTime? acceptedAt,
      {bool showHandoverOnLoad = false}) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmArrivalScreen(
          session: session,
          preventBackNavigation: true,
          showHandoverOnLoad: showHandoverOnLoad,
          acceptTriggeredAt: acceptedAt,
        ),
      ),
    );
  }

  bool _isInConfirmArrivalFlowStatus(PendingSession session) {
    return session.isAccepted || session.isArrived;
  }

  Future<PendingSession?> _resolveFifoConfirmArrivalTarget(
    String acceptedSessionId,
  ) async {
    List<PendingSession> sessions;
    try {
      final res = await SessionsPendingApiService.getPendingSessions();
      sessions = res.sessions.where(_isRetrievalTask).toList()
        ..sort(_compareSessionFifo);
    } catch (_) {
      sessions =
          List<PendingSession>.from(_retrievals ?? const <PendingSession>[])
            ..sort(_compareSessionFifo);
    }

    if (sessions.isEmpty) return null;

    for (final session in sessions) {
      if (_isInConfirmArrivalFlowStatus(session)) return session;
    }

    for (final session in sessions) {
      if (session.sessionId == acceptedSessionId) return session;
    }

    return sessions.first;
  }

  Future<void> _navigateToConfirmArrivalFifo({
    required String acceptedSessionId,
    required DateTime acceptedAt,
  }) async {
    final target = await _resolveFifoConfirmArrivalTarget(acceptedSessionId);
    if (!mounted || target == null) return;
    final assigned = SessionConverter.pendingToAssigned(target);
    _navigateToConfirmArrival(
      assigned,
      target.sessionId == acceptedSessionId ? acceptedAt : null,
      showHandoverOnLoad: target.isArrived,
    );
  }

  // ─── Existing helpers ─────────────────────────────────────────────────────

  Future<void> _continueRetrievalFlow(PendingSession session) async {
    final assignedSession = SessionConverter.pendingToAssigned(session);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmArrivalScreen(
          session: assignedSession,
          preventBackNavigation: true,
          showHandoverOnLoad: session.isArrived,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  String _statusLabel(PendingSession session) {
    final normalized = session.status.trim().toUpperCase();
    if (normalized == 'ACCEPT' || normalized == 'ACCEPTED') return 'Accepted';
    if (normalized == 'ARRIVED') return 'Arrived';
    return normalized.isEmpty ? 'Pending' : normalized;
  }

  Color _statusColor(PendingSession session) {
    final normalized = session.status.trim().toUpperCase();
    if (normalized == 'ARRIVED') return AppColors.primary;
    if (normalized == 'ACCEPT' || normalized == 'ACCEPTED') {
      return AppColors.success;
    }
    return AppColors.mutedText;
  }

  String? _photoUrl(PendingSession session) {
    if (session.photos.isEmpty) return null;
    final first = session.photos.first;
    if (first is String && first.trim().isNotEmpty) return first.trim();
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      final candidates = [
        map['url'],
        map['photoUrl'],
        map['imageUrl'],
        map['secureUrl'],
      ];
      for (final value in candidates) {
        final url = value?.toString().trim() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  String? _displayPhotoUrl(PendingSession session) {
    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty) return _photoUrl(session);

    final latest = _photoUrl(session);
    final existing = _stablePhotoUrlBySessionId[sessionId];

    if (latest == null || latest.isEmpty) {
      return existing;
    }

    if (existing != null &&
        _normalizePhotoUrl(existing) == _normalizePhotoUrl(latest)) {
      return existing;
    }

    _stablePhotoUrlBySessionId[sessionId] = latest;
    return latest;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Scaffold(
      backgroundColor: AppColors.lightBeigeBackground,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        showOverflowMenu: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(t),
      ),
    );
  }

  Widget _buildBody(AppTranslationsNotifier t) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _retrievals == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextComponent(
                labelText: getDisplayErrorMessage(_error),
                textAlign: TextAlign.center,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      );
    }

    final retrievals = _retrievals ?? const <PendingSession>[];
    if (retrievals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          Center(
            child: TextComponent(
              labelText: t.get(TextConstants.retrievalRequests),
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextComponent(
                labelText: t.get(TextConstants.noPendingRetrievalRequests),
                textAlign: TextAlign.center,
                color: AppColors.mutedText,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      itemBuilder: (context, index) {
        final session = retrievals[index];
        final photoUrl = _displayPhotoUrl(session);
        final isTopFifoItem = index == 0;
        return Container(
          key: ValueKey('retrieval-${session.sessionId}'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow10,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: (photoUrl != null && photoUrl.isNotEmpty)
                  ? () => FullImageViewerDialog.show(context, photoUrl)
                  : null,
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, _, __) => Container(
                          color: AppColors.greyLight.withOpacity(0.35),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.mutedText),
                        ),
                      )
                    : Container(
                        color: AppColors.greyLight.withOpacity(0.35),
                        alignment: Alignment.center,
                        child: const Icon(Icons.directions_car_filled,
                            color: AppColors.mutedText, size: 34),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextComponent(
                          labelText:
                              '${TextConstants.cardNumber} ${session.cardNumber}',
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(session).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TextComponent(
                          labelText: _statusLabel(session),
                          color: _statusColor(session),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextComponent(
                    labelText:
                        '${TextConstants.parkingLocationLabel}: ${session.parkingLocation?.trim().isNotEmpty == true ? session.parkingLocation : '-'}',
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 6),
                  TextComponent(
                    labelText: 'Pending for: ${session.pendingForMinutes} min',
                    color: AppColors.mutedText,
                  ),
                  if (isTopFifoItem) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _continueRetrievalFlow(session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: TextComponent(
                          labelText: t.getByKey(
                            'continueLabel',
                            TextConstants.continueLabel,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: retrievals.length,
    );
  }
}

// ─── Inline sheet body for newly-assigned retrievals ────────────────────────

class _AssignedSheetBody extends StatefulWidget {
  final AssignedSession session;
  final void Function(DateTime acceptedAt) onAccepted;
  final VoidCallback onDismiss;

  const _AssignedSheetBody({
    required this.session,
    required this.onAccepted,
    required this.onDismiss,
  });

  @override
  State<_AssignedSheetBody> createState() => _AssignedSheetBodyState();
}

class _AssignedSheetBodyState extends State<_AssignedSheetBody> {
  bool _isAcceptLoading = false;
  String? _passErrorMessage;

  void _pop() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RetrivalRequestBloc, RetrivalRequestState>(
          listener: (context, state) {
            if (state is RetrivalRequestLoading) {
              if (mounted) setState(() => _isAcceptLoading = true);
            } else if (state is RetrivalRequestAccepted) {
              final acceptedAt = DateTime.now();
              SnackBars.showSuccessSnackBar(context, state.message);
              if (mounted) setState(() => _isAcceptLoading = false);
              _pop();
              widget.onAccepted(acceptedAt);
            } else if (state is RetrivalRequestError) {
              SnackBars.showErrorSnackBar(context, state.message);
              if (mounted) setState(() => _isAcceptLoading = false);
            }
          },
        ),
        BlocListener<PassAvailableDriversBloc, PassAvailableDriversState>(
          listener: (context, state) {
            if (state is SessionPassedToDriver) {
              SnackBars.showSuccessSnackBar(context, state.message);
              if (mounted) setState(() => _passErrorMessage = null);
              _pop();
              widget.onDismiss();
            } else if (state is PassToDriverError) {
              SnackBars.showErrorSnackBar(context, state.message);
              if (mounted) setState(() => _passErrorMessage = state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<PassAvailableDriversBloc, PassAvailableDriversState>(
        builder: (context, passState) {
          final isPassing = passState is PassingSessionToDriver;
          final actionsLocked = _isAcceptLoading || isPassing;

          return RetrievalRequestSheet(
            session: widget.session,
            isLoading: false,
            isAcceptLoading: _isAcceptLoading,
            isPassing: isPassing,
            passErrorMessage: _passErrorMessage,
            onAccept: actionsLocked
                ? null
                : () {
                    VibrationController.stop();
                    setState(() => _isAcceptLoading = true);
                    context.read<RetrivalRequestBloc>().add(
                          AcceptRetrivalRequest(
                            widget.session.id,
                            assignedSession: widget.session,
                          ),
                        );
                  },
            onPass: actionsLocked
                ? null
                : () {
                    if (mounted) setState(() => _passErrorMessage = null);
                    VibrationController.stop();
                    context.read<PassAvailableDriversBloc>().add(
                          PassSessionToDriver(sessionId: widget.session.id),
                        );
                  },
          );
        },
      ),
    );
  }
}
