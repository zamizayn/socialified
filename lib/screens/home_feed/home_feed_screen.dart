import 'package:foap/helper/common_import.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({Key? key}) : super(key: key);

  @override
  HomeFeedState createState() => HomeFeedState();
}

class HomeFeedState extends State<HomeFeedScreen> {
  final HomeController _homeController = Get.find();
  final AddPostController _addPostController = Get.find();
  final AgoraLiveController _agoraLiveController = Get.find();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final SettingsController _settingsController = Get.find();

  final _controller = ScrollController();

  String? selectedValue;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(isRecent: true);
      _homeController.loadQuickLinksAccordingToSettings();
    });

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
        } else {
          loadData(isRecent: false);
        }
      }
    });
  }

  loadMore({required bool? isRecent}) {
    loadPosts(isRecent);
  }

  refreshData() {
    _homeController.clear();
    loadData(isRecent: false);
  }

  @override
  void dispose() {
    super.dispose();
    _homeController.clear();
    _homeController.closeQuickLinks();
  }

  loadPosts(bool? isRecent) {
    _homeController.getPosts(
        isRecent: isRecent,
        callback: () {
          _refreshController.refreshCompleted();
        });
  }

  void loadData({required bool? isRecent}) {
    loadPosts(isRecent);
    _homeController.getStories();
  }

  @override
  void didUpdateWidget(covariant HomeFeedScreen oldWidget) {
    loadData(isRecent: false);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        // floatingActionButton: Container(
        //   height: 50,
        //   width: 50,
        //   color: Theme.of(context).primaryColor,
        //   child: const ThemeIconWidget(
        //     ThemeIcon.edit,
        //     size: 25,
        //   ),
        // ).circular.ripple(() {
        //   Future.delayed(
        //     Duration.zero,
        //     () => showGeneralDialog(
        //         context: context,
        //         pageBuilder: (context, animation, secondaryAnimation) =>
        //             const SelectMedia()),
        //   );
        // }),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            menuView(),
            const SizedBox(
              height: 55,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      AppConfigConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).primaryColor),
                    )
                  ],
                ),
                const Spacer(),
                // const ThemeIconWidget(
                //   ThemeIcon.map,
                //   // color: Theme.of(context).primaryColor,
                //   size: 25,
                // ).ripple(() {
                //   Get.to(() => MapsUsersScreen());
                // }),
                const SizedBox(
                  width: 20,
                ),
                if (_settingsController.setting.value!.enableChat)
                  const ThemeIconWidget(
                    ThemeIcon.search,
                    size: 25,
                  ).ripple(() {
                    Get.to(() => const Explore());
                  }),
                const SizedBox(
                  width: 20,
                ),
                Obx(() => Container(
                      color: Theme.of(context).backgroundColor,
                      height: 25,
                      width: 25,
                      child: ThemeIconWidget(
                        _homeController.openQuickLinks.value == true
                            ? ThemeIcon.close
                            : ThemeIcon.menuIcon,
                        // color: Theme.of(context).primaryColor,
                        size: 25,
                      ),
                    ).ripple(() {
                      _homeController.quickLinkSwitchToggle();
                    })),
              ],
            ).hp(20),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: postsView(),
            ),
          ],
        ));
  }

  Widget menuView() {
    return Obx(() => AnimatedContainer(
          height: _homeController.openQuickLinks.value == true ? 325 : 0,
          width: Get.width,
          color: Theme.of(context).primaryColor,
          duration: const Duration(milliseconds: 500),
          child: QuickLinkWidget(callback: () {
            _homeController.closeQuickLinks();
          }),
        ));
  }

  Widget postingView() {
    return Obx(() => _addPostController.isPosting.value
        ? Container(
            height: 55,
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Image.memory(
                  _addPostController.postingMedia.first.thumbnail!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                ).round(5),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  _addPostController.isErrorInPosting.value
                      ? LocalizationString.postFailed
                      : LocalizationString.posting,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _addPostController.isErrorInPosting.value
                    ? Row(
                        children: [
                          Text(
                            LocalizationString.discard,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ).ripple(() {
                            _addPostController.discardFailedPost();
                          }),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            LocalizationString.retry,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ).ripple(() {
                            _addPostController.retryPublish(context);
                          }),
                        ],
                      )
                    : Container()
              ],
            ).hP8,
          ).shadow(context: context, radius: 10).bp(20)
        : Container());
  }

  Widget storiesView() {
    return SizedBox(
      height: 110,
      child: GetBuilder<HomeController>(
          init: _homeController,
          builder: (ctx) {
            return StoryUpdatesBar(
              stories: _homeController.stories,
              liveUsers: _homeController.liveUsers,
              addStoryCallback: () {
                // Get.to(() => const TextStoryMaker());
                Get.to(() => const ChooseMediaForStory());
              },
              viewStoryCallback: (story) {
                Get.to(() => StoryViewer(story: story));
              },
              joinLiveUserCallback: (user) {
                Live live = Live(
                    channelName: user.liveCallDetail!.channelName,
                    isHosting: false,
                    host: user,
                    token: user.liveCallDetail!.token,
                    liveId: user.liveCallDetail!.id);
                _agoraLiveController.joinAsAudience(
                  live: live,
                );
              },
            ).vP16;
          }),
    );
  }

  postsView() {
    return Obx(() {
      return ListView.separated(
              controller: _controller,
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _homeController.posts.length + 3,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Obx(() =>
                      _homeController.isRefreshingStories.value == true
                          ? const StoryAndHighlightsShimmer()
                          : storiesView());
                }
                // else if (index == 1) {
                //   return const QuickLinkWidget();
                // }
                else if (index == 1) {
                  return postingView().hP16;
                } else if (index == 2) {
                  return Obx(() => Column(
                        children: [
                          HorizontalMenuBar(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              onSegmentChange: (segment) {
                                _homeController.categoryIndexChanged(
                                    index: segment,
                                    callback: () {
                                      _refreshController.refreshCompleted();
                                    });
                              },
                              selectedIndex:
                                  _homeController.categoryIndex.value,
                              menus: [
                                LocalizationString.all,
                                LocalizationString.following,
                                // LocalizationString.trending,
                                LocalizationString.recent,
                                LocalizationString.your,
                              ]),
                          _homeController.isRefreshingPosts.value == true
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: const HomeScreenShimmer())
                              : _homeController.posts.isEmpty
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5,
                                      child: emptyPost(
                                          context: context,
                                          title: LocalizationString.noPostFound,
                                          subTitle: LocalizationString
                                              .followFriendsToSeeUpdates),
                                    )
                                  : Container()
                        ],
                      ));
                } else {
                  PostModel model = _homeController.posts[index - 3];

                  return PostCard(
                    model: model,
                    textTapHandler: (text) {
                      _homeController.postTextTapHandler(
                          post: model, text: text);
                    },
                    // mediaTapHandler: (post) {
                    //   // Get.to(()=> PostMediaFullScreen(post: post));
                    // },
                    removePostHandler: () {
                      _homeController.removePostFromList(model);
                    },
                  );
                }
              },
              separatorBuilder: (context, index) {
                // if ((index + 1) % 5 == 0) {
                //   return FutureBuilder<Widget>(
                //     future: BannerAdsWidget.getBannerWidget(
                //         context: context, index: (index + 1) % 5),
                //     builder: (_, snapshot) {
                //       if (!snapshot.hasData) {
                //         return Container();
                //       } else {
                //         return SizedBox(
                //           height: 50,
                //           width: MediaQuery.of(context).size.width,
                //           child: snapshot.data,
                //         );
                //       }
                //     },
                //   );
                // }
                if (index == 1) {
                  return Container();
                } else {
                  return const SizedBox(
                    height: 20,
                  );
                }
              })
          .addPullToRefresh(
              refreshController: _refreshController,
              enablePullUp: false,
              onRefresh: refreshData,
              onLoading: () {});
    });
  }
}
