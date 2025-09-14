import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/app/app_preference.dart';
import '../../../data/app/constants.dart';
import '../../../data/datasources/resources/assets_manager.dart';
import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/datasources/resources/language/language_manager.dart';
import '../../../data/datasources/resources/language/language_notifier.dart';
import '../../../data/datasources/resources/routes_manager.dart';
import '../../../data/datasources/resources/values_manager.dart';
import '../../../data/models/sliderViewObject/SliderViewObject.dart';
import '../../../data/models/slider_objects/Slider_objects.dart';
import 'onBoarding_viewmodel.dart';

class OnBoardingView extends ConsumerStatefulWidget {
  const OnBoardingView({super.key});

  @override
  ConsumerState<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends ConsumerState<OnBoardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onBoardingViewModelProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Container( // Apply gradient to the whole screen
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1],
            colors: [Colors.white, Color(0xFFD1E4FC)],
          ),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context, localeNotifier),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSize.s50),
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LocaleNotifier localeNotifier) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AppSize.s120), // Adjust height as needed
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent, // AppBar should be transparent to let the background gradient show
        elevation: AppSize.s0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: ColorManager.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset('assets/images/png/logo.png',height: 60,width:80,),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageDropdown(context, localeNotifier),
                _buildSkipButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, LocaleNotifier localeNotifier) {
    SizedBox(height: 40);

    return DropdownButton<String>(

      value: context.locale.languageCode.toUpperCase(),
      icon: Icon(Icons.keyboard_arrow_down, color: ColorManager.black),
      underline: const SizedBox(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          newValue.toLowerCase() == 'en'
              ? localeNotifier.setLocale(context, ENGLISH_LOCAL)
              : localeNotifier.setLocale(context, ARABIC_LOCAL);
        }
      },
      items: <String>['EN', 'AR'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorManager.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildSkipButton(BuildContext context) {
    return
      TextButton(
          onPressed: () async {
            try {
              final prefs = await ref.read(sharedPreferencesProvider.future);
              await AppPreferences(prefs).setOnBoardingScreenViewed();
              if (mounted) {
                Navigator.pushReplacementNamed(context, Routes.loginRoute);
              }
            } catch (e) {
              log("Failed to save onboarding preference: $e");
              // Optionally, show an error to the user
            }
          },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p8),
          minimumSize: const Size(AppSize.s60, AppSize.s36),
          // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          "skip".tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColorManager.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ));


  }

  Widget _buildBody(SliderViewObject state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [


            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(onBoardingViewModelProvider),
              child: Text("retry".tr()),
            ),
          ],
        ),
      );
    }

    if (state.sliderObjects == null || state.sliderObjects!.isEmpty) {
      return Center(
        child: Text("onBoarding_error".tr()),
      );
    }

    return Column(
      children: [
        SizedBox(height: 5,),

        Expanded(

          child: PageView.builder(
            controller: _pageController,
            itemCount: state.numOfSlides,
            onPageChanged: (index) {
              ref.read(onBoardingViewModelProvider.notifier).onPageChanged(index);
            },
            itemBuilder: (context, index) {
              if (index < 0 || index >= state.sliderObjects!.length) {
                return Center(child: Text("error Loading".tr()));
              }
              return OnBoardingPage(state.sliderObjects![index]);
            },
          ),
        ),
        _BottomNavigation(
          pageController: _pageController,
          sliderViewObject: state,
        ),
      ],
    );
  }
}

class _BottomNavigation extends ConsumerWidget {
  final PageController pageController;
  final SliderViewObject sliderViewObject;

  const _BottomNavigation({
    required this.pageController,
    required this.sliderViewObject,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(onBoardingViewModelProvider.notifier);
    final bool isLastSlide = sliderViewObject.currentIndex == (sliderViewObject.numOfSlides ?? 0) - 1;

    return Container(
      color: ColorManager.transparent,
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.p16,
        horizontal: AppPadding.p24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          const SizedBox(width: AppSize.s40),

          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final dotCount = sliderViewObject.numOfSlides ?? 1;
                final maxDotWidth = (maxWidth / dotCount).clamp(8.0, 32.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    dotCount,
                        (index) {
                      final isActive = index == sliderViewObject.currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? maxDotWidth : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ColorManager.blue
                              : ColorManager.blue,
                          borderRadius: BorderRadius.circular(isActive ? 6 : 12),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          isLastSlide
              ? _buildFinishButton(context, ref) // Pass ref here
              : _buildArrowButton(
            context,
            icon: ImageAssets.rightArrowIc,
            onTap: () {
              pageController.animateToPage(
                viewModel.goNext(),
                duration: const Duration(milliseconds: Constants.sliderAnimationTime),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(
      BuildContext context, {
        required String icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.s30),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.p10),
        decoration: BoxDecoration(
          color: ColorManager.blue,
          shape: BoxShape.circle,
          border: Border.all(color: ColorManager.blue),
        ),
        child: Image.asset(
          icon,
          width: AppSize.s20,
          height: AppSize.s20,
          color: ColorManager.white,
          // colorFilter: ColorFilter.mode(ColorManager.white, BlendMode.srcIn),
        ),
      ),
    );
  }
  Widget _buildFinishButton(BuildContext context, WidgetRef ref) { // Accept WidgetRef
    return
      InkWell(
        onTap: () async {
          try {
            final prefs = await ref.read(sharedPreferencesProvider.future);
            await AppPreferences(prefs).setOnBoardingScreenViewed();



            if (context.findRenderObject()?.attached ?? false) {
              Navigator.pushReplacementNamed(context, Routes.loginRoute);
            }
          } catch (e) {
            log("Failed to save onboarding preference: $e");
          }
        },
      borderRadius: BorderRadius.circular(AppSize.s14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p20,
          vertical: AppPadding.p10,
        ),
        decoration: BoxDecoration(
          color: ColorManager.blue,
          borderRadius: BorderRadius.circular(AppSize.s14),
        ),
        child: Text(
          "finish".tr(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: ColorManager.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class OnBoardingPage extends StatelessWidget {
  final SliderObject _sliderObject;

  const OnBoardingPage(this._sliderObject, {super.key});

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              appBarHeight -
              MediaQuery.of(context).padding.top -
              100, // Adjusted appBarMaxHeight
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSize.s30),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: ColorManager.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSize.s12),
              ),
              child: _getImageWidget(_sliderObject.image, context),
            ),
            const SizedBox(height: AppSize.s32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p8),
              child: Text(
                _sliderObject.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: AppSize.s24,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.black,
                ),
              ),
            ),
            const SizedBox(height: AppSize.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p8),
              child: Text(
                _sliderObject.subTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppSize.s16,
                  color: ColorManager.black,
                ),
              ),
            ),
            const SizedBox(height: AppSize.s32),
          ],
        ),
      ),
    );
  }

  Widget _getImageWidget(String imagePath, BuildContext context) {
    if (imagePath.toLowerCase().startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    } else if (imagePath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        fit: BoxFit.contain,
      );
    } else if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}