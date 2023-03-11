import 'package:foap/helper/common_import.dart';
import 'package:get/get.dart';

class Explore extends StatefulWidget {
  const Explore({Key? key}) : super(key: key);

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final ExploreController _exploreController = Get.find();
  final PostController _postController = Get.find();
  final SettingsController _settingsController = Get.find();

  @override
  void initState() {
    super.initState();
    _exploreController.getSuggestedUsers();
  }

  @override
  void didUpdateWidget(covariant Explore oldWidget) {
    // TODO: implement didUpdateWidget
    _exploreController.getSuggestedUsers();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _exploreController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: KeyboardDismissOnTap(
            child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                if (_settingsController.setting.value!.enableChat)
                  const ThemeIconWidget(
                    ThemeIcon.backArrow,
                    size: 25,
                  ).ripple(() {
                    Get.back();
                  }),
                if (_settingsController.setting.value!.enableChat)
                  const SizedBox(
                    width: 10,
                  ),
                Expanded(
                  child: SearchBar(
                      showSearchIcon: true,
                      iconColor: Theme.of(context).primaryColor,
                      onSearchChanged: (value) {
                        _exploreController.searchTextChanged(value);
                      },
                      onSearchStarted: () {
                        //controller.startSearch();
                      },
                      onSearchCompleted: (searchTerm) {}),
                ),
                Obx(() => _exploreController.searchText.isNotEmpty
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          Container(
                            height: 50,
                            width: 50,
                            color: Theme.of(context).primaryColor,
                            child: ThemeIconWidget(
                              ThemeIcon.close,
                              color: Theme.of(context).backgroundColor,
                              size: 25,
                            ),
                          ).round(20).ripple(() {
                            _exploreController.closeSearch();
                          }),
                        ],
                      )
                    : Container())
              ],
            ).setPadding(left: 16, right: 16, top: 25, bottom: 20),
            GetBuilder<ExploreController>(
                init: _exploreController,
                builder: (ctx) {
                  return _exploreController.searchText.isNotEmpty
                      ? Expanded(
                          child: Column(
                            children: [
                              segmentView(),
                              divider(context: context, height: 0.2),
                              searchedResult(
                                  segment: _exploreController.selectedSegment),
                            ],
                          ),
                        )
                      : searchSuggestionView();
                })
          ],
        )),
      ),
    );
  }

  Widget segmentView() {
    return HorizontalSegmentBar(
        width: MediaQuery.of(context).size.width,
        onSegmentChange: (segment) {
          _exploreController.segmentChanged(segment);
        },
        segments: [
          LocalizationString.top,
          LocalizationString.account,
          LocalizationString.hashTags,
          // LocalizationString.locations,
        ]);
  }

  Widget searchSuggestionView() {
    ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.position.pixels) {
        if (!_exploreController.suggestUserIsLoading) {
          _exploreController.getSuggestedUsers();
        }
      }
    });

    return _exploreController.suggestUserIsLoading
        ? Expanded(child: const ShimmerUsers().hP16)
        : _exploreController.suggestedUsers.isNotEmpty
            ? Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      LocalizationString.suggestedUsers,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.only(top: 20, bottom: 50),
                          itemCount: _exploreController.suggestedUsers.length,
                          itemBuilder: (BuildContext ctx, int index) {
                            return UserTile(
                              profile: _exploreController.suggestedUsers[index],
                              followCallback: () {
                                _exploreController.followUser(
                                    _exploreController.suggestedUsers[index]);
                              },
                              unFollowCallback: () {
                                _exploreController.unFollowUser(
                                    _exploreController.suggestedUsers[index]);
                              },
                            );
                          },
                          separatorBuilder: (BuildContext ctx, int index) {
                            return const SizedBox(
                              height: 20,
                            );
                          }),
                    ),
                  ],
                ).hP16,
              )
            : Container();
  }

  Widget searchedResult({required int segment}) {
    switch (segment) {
      case 0:
        return topPosts();
      case 1:
        return Expanded(child: usersView().hP16);
      case 2:
        return Expanded(child: hashTagView().hP16);
      // case 3:
      //   return Expanded(child: locationView()).hP16;
    }
    return usersView();
  }

  Widget usersView() {
    ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.position.pixels) {
        if (!_exploreController.accountsIsLoading) {
          _exploreController.searchData();
        }
      }
    });

    return _exploreController.accountsIsLoading
        ? const ShimmerUsers()
        : _exploreController.searchedUsers.isNotEmpty
            ? ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 20),
                itemCount: _exploreController.searchedUsers.length,
                itemBuilder: (BuildContext ctx, int index) {
                  return UserTile(
                    profile: _exploreController.searchedUsers[index],
                    followCallback: () {
                      _exploreController
                          .followUser(_exploreController.searchedUsers[index]);
                    },
                    unFollowCallback: () {
                      _exploreController.unFollowUser(
                          _exploreController.searchedUsers[index]);
                    },
                  );
                },
                separatorBuilder: (BuildContext ctx, int index) {
                  return const SizedBox(
                    height: 20,
                  );
                })
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: emptyUser(
                    context: context,
                    title: LocalizationString.noUserFound,
                    subTitle: ''),
              );
  }

  Widget hashTagView() {
    ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.position.pixels) {
        if (!_exploreController.hashtagsIsLoading) {
          _exploreController.searchData();
        }
      }
    });

    return _exploreController.hashtagsIsLoading
        ? const ShimmerHashtag()
        : _exploreController.hashTags.isNotEmpty
            ? ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 20),
                itemCount: _exploreController.hashTags.length,
                itemBuilder: (BuildContext ctx, int index) {
                  return HashTagTile(
                    hashtag: _exploreController.hashTags[index],
                    onItemCallback: () {
                      Get.to(() => Posts(
                            hashTag: _exploreController.hashTags[index].name,
                            source: PostSource.posts,
                          ));
                    },
                  );
                },
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: emptyData(
                    context: context,
                    title: LocalizationString.noHashtagFound,
                    subTitle: ''),
              );
  }

  // Widget locationView() {
  //   return ListView.builder(
  //     padding: const EdgeInsets.only(top: 20),
  //     itemCount: controller.locations.length,
  //     itemBuilder: (BuildContext ctx, int index) {
  //       return LocationTile(
  //         location: controller.locations[index],
  //         onItemCallback: () {
  //           Get.to(() => Posts(locationId: controller.locations[index].id));
  //         },
  //       );
  //     },
  //   );
  // }

  Widget topPosts() {
    ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.position.pixels) {
        if (!_postController.isLoadingPosts) {
          _exploreController.searchData();
        }
      }
    });

    return GetBuilder<PostController>(
        init: _postController,
        builder: (ctx) {
          return Expanded(
              child: _postController.isLoadingPosts
                  ? const PostBoxShimmer()
                  : _postController.posts.isNotEmpty
                      ? MasonryGridView.count(
                          controller: scrollController,
                          padding: const EdgeInsets.only(top: 20),
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          itemCount: _postController.posts.length,
                          itemBuilder: (BuildContext context, int index) =>
                              _postController.posts[index].gallery.first
                                          .isVideoPost ==
                                      true
                                  ? Stack(children: [
                                      AspectRatio(
                                          aspectRatio: 1,
                                          child: CachedNetworkImage(
                                            imageUrl: _postController
                                                .posts[index]
                                                .gallery
                                                .first
                                                .videoThumbnail!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                AppUtil.addProgressIndicator(
                                                    context, 100),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                              Icons.error,
                                            ),
                                          ).round(10)),
                                      const Positioned(
                                        right: 5,
                                        top: 5,
                                        child: ThemeIconWidget(
                                          ThemeIcon.play,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      )
                                    ]).ripple(() {
                                      Get.to(() => Posts(
                                            posts: List.from(
                                                _postController.posts),
                                            index: index,
                                            source: PostSource.posts,
                                            page: _postController
                                                .postsCurrentPage,
                                          ));
                                    })
                                  : AspectRatio(
                                          aspectRatio: 1,
                                          child: CachedNetworkImage(
                                            imageUrl: _postController
                                                .posts[index]
                                                .gallery
                                                .first
                                                .filePath,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                AppUtil.addProgressIndicator(
                                                    context, 100),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ).round(10))
                                      .ripple(() {
                                      Get.to(() => Posts(
                                            posts: List.from(
                                                _postController.posts),
                                            index: index,
                                            source: PostSource.posts,
                                            page: _postController
                                                .postsCurrentPage,
                                            totalPages:
                                                _postController.totalPages,
                                          ));
                                    }),
                          mainAxisSpacing: 4.0,
                          crossAxisSpacing: 4.0,
                        ).hP16
                      : SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: emptyPost(
                              context: context,
                              title: LocalizationString.noPostFound,
                              subTitle: ''),
                        ));
        });
  }
}
