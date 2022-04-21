import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instegram/core/resources/color_manager.dart';
import 'package:instegram/data/models/post.dart';
import 'package:instegram/presentation/cubit/postInfoCubit/post_cubit.dart';
import 'package:instegram/presentation/cubit/postInfoCubit/specific_users_posts_cubit.dart';
import 'package:instegram/presentation/widgets/custom_app_bar.dart';
import 'package:instegram/presentation/widgets/post_list_view.dart';
import 'package:instegram/presentation/widgets/smart_refresher.dart';
import 'package:instegram/presentation/widgets/toast_show.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import '../../data/models/user_personal_info.dart';
import '../cubit/firestoreUserInfoCubit/user_info_cubit.dart';
import '../widgets/circle_avatar_of_profile_image.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool rebuild = true;
  bool loadingPosts = true;
  bool reLoadData = false;

  Future<void> getData() async {
    UserPersonalInfo? personalInfo;
    reLoadData = false;
    FirestoreUserInfoCubit userCubit =
        BlocProvider.of<FirestoreUserInfoCubit>(context, listen: false);
    await userCubit.getUserInfo(widget.userId, true);
    personalInfo = userCubit.myPersonalInfo;

    List usersIds = personalInfo!.followedPeople + personalInfo.followerPeople;

    SpecificUsersPostsCubit usersPostsCubit =
        BlocProvider.of<SpecificUsersPostsCubit>(context, listen: false);

    await usersPostsCubit
        .getSpecificUsersPostsInfo(usersIds: usersIds);

      List usersPostsIds = usersPostsCubit.usersPostsInfo;

      List postsIds = usersPostsIds + personalInfo.posts;

      PostCubit postCubit = PostCubit.get(context);
      await postCubit
          .getPostsInfo(postsIds: postsIds, isThatForMyPosts: true)
          .then((value) {
        Future.delayed(Duration.zero, () {
          setState(() {});
        });
        reLoadData = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bodyHeight = mediaQuery.size.height -
        AppBar().preferredSize.height -
        mediaQuery.padding.top;
    if (rebuild) {
      getData();
      rebuild = false;
    }
    return Scaffold(
      appBar: customAppBar(),
      body: SmarterRefresh(
        onRefreshData: getData,
        smartRefresherChild: blocBuilder(bodyHeight),
      ),
    );
  }

  BlocBuilder<PostCubit, PostState> blocBuilder(double bodyHeight) {
    return BlocBuilder<PostCubit, PostState>(
      buildWhen: (previous, current) {
        if (reLoadData && current is CubitMyPersonalPostsLoaded) {
          reLoadData = false;
          return true;
        }

        if (previous != current && current is CubitMyPersonalPostsLoaded) {
          return true;
        }
        if (previous != current && current is CubitPostFailed) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, PostState state) {
        if (state is CubitMyPersonalPostsLoaded) {
          return inViewNotifier(state, bodyHeight);
        } else if (state is CubitPostFailed) {
          ToastShow.toastStateError(state);
          return const Center(child: Text("There's no posts..."));
        } else {
          return const Center(
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: ColorManager.black54),
          );
        }
      },
    );
  }

  SingleChildScrollView inViewNotifier(
      CubitMyPersonalPostsLoaded state, double bodyHeight) {
    return SingleChildScrollView(
      child: InViewNotifierList(
        primary: false,
        scrollDirection: Axis.vertical,
        initialInViewIds: const ['0'],
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        isInViewPortCondition:
            (double deltaTop, double deltaBottom, double viewPortDimension) {
          return deltaTop < (0.5 * viewPortDimension) &&
              deltaBottom > (0.5 * viewPortDimension);
        },
        itemCount: state.postsInfo.length,
        builder: (BuildContext context, int index) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 0.5),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return InViewNotifierWidget(
                  id: '$index',
                  builder: (_, bool isInView, __) {
                    if (isInView) {}
                    return columnOfWidgets(
                      bodyHeight, state.postsInfo, index,
                      //     () {
                      //   WidgetsBinding.instance!.addPostFrameCallback((_) async {
                      //     setState(() {
                      //       isInView;
                      //     });
                      //   });
                      //   return isInView;
                      // }
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget columnOfWidgets(double bodyHeight, List<Post> postsInfo, int index) {
    return Column(
      children: [
        if (index == 0) storiesLines(bodyHeight, postsInfo),
        const Divider(thickness: 0.5),
        posts(postsInfo[index]),
      ],
    );
  }

  Widget posts(Post postInfo) {
    return ImageList(
      postInfo: postInfo,
      // isVideoInView: isVideoInView,
    );
  }

  Widget storiesLines(double bodyHeight, List<Post> postsInfo) {
    return SizedBox(
      width: double.infinity,
      height: bodyHeight * 0.155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: postsInfo.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          UserPersonalInfo publisherInfo = postsInfo[index].publisherInfo!;
          return CircleAvatarOfProfileImage(
            circleAvatarName:
                publisherInfo.name.isNotEmpty ? publisherInfo.name : '',
            bodyHeight: bodyHeight,
            thisForStoriesLine: true,
            imageUrl: publisherInfo.profileImageUrl.isNotEmpty
                ? publisherInfo.profileImageUrl
                : '',
          );
        },
      ),
    );
  }
}
