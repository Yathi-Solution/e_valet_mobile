import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/profile/profile_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/profile/profile_event.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/profile/profile_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/profile_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc()..add(const ProfileStarted()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
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
              child: Center(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoading || state is ProfileInitial) {
                      return const CircularProgressIndicator();
                    }

                    if (state is ProfileError) {
                      return TextComponent(
                        labelText: state.message,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                        textAlign: TextAlign.center,
                      );
                    }

                    if (state is ProfileLoaded) {
                      return ProfileContent(
                        profile: state.profile,
                        loggedInOutletDisplay: state.loggedInOutletDisplay,
                      );
                    }

                    // Fallback – shouldn't normally reach here
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
