import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instegram/core/globall.dart';
import 'package:instegram/core/resources/color_manager.dart';
import 'package:instegram/data/models/comment.dart';
import 'package:instegram/data/models/user_personal_info.dart';
import 'package:instegram/injector.dart';
import 'package:instegram/presentation/cubit/firestoreUserInfoCubit/user_info_cubit.dart';
import 'package:instegram/presentation/cubit/postInfoCubit/commentsInfo/comments_info_cubit.dart';
import 'package:instegram/presentation/cubit/postInfoCubit/commentsInfo/repliesInfo/reply_info_cubit.dart';
import 'package:instegram/presentation/widgets/circle_avatar_of_profile_image.dart';
import 'package:instegram/presentation/widgets/commentator.dart';

import '../widgets/toast_show.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _textController = TextEditingController();
  // bool rebuildComments = false;
  Comment? selectedCommentInfo;
  bool addReply = false;
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      UserPersonalInfo? myPersonalInfo =
          FirestoreUserInfoCubit.get(context).myPersonalInfo;

      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: ColorManager.white,
          title: const Text('Comments'),
        ),
        body: BlocBuilder<CommentsInfoCubit, CommentsInfoState>(
            bloc: CommentsInfoCubit.get(context)
              ..getSpecificComments(postId: widget.postId),
            buildWhen: (previous, current) {
              if (previous != current && (current is CubitCommentsInfoLoaded)) {
                return true;
              }
              if (previous != current && (current is CubitCommentsInfoFailed)) {
                return true;
              }

              return false;
            },
            builder: (context, state) {
              if (state is CubitCommentsInfoLoaded) {
                return buildListView(state, myPersonalInfo!);
              } else if (state is CubitCommentsInfoFailed) {
                ToastShow.toastStateError(state);
                return const Text("Something Wrong");
              } else {
                return const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 1, color: ColorManager.black54),
                );
              }
            }),
        bottomSheet: addCommentBottomSheet(myPersonalInfo!),
      );
    });
  }

  selectedComment(Comment commentInfo) {
    setState(() {
      selectedCommentInfo = commentInfo;
    });
  }

  Widget buildListView(
      CubitCommentsInfoLoaded state, UserPersonalInfo myPersonalInfo) {
    return state.commentsOfThePost.isNotEmpty
        ? Scrollbar(
            child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                primary: false,
                itemBuilder: (context, index) {
                  return BlocProvider<ReplyInfoCubit>(
                    create: (_) => injector<ReplyInfoCubit>(),
                    child: CommentInfo(
                      commentInfo: state.commentsOfThePost[index],
                      textController: _textController,
                      selectedCommentInfo: selectedComment,
                      myPersonalInfo: myPersonalInfo,
                      addReply: addReply,
                    ),
                  );
                },
                itemCount: state.commentsOfThePost.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(
                      height: 20,
                    )),
          )
        : const Center(
            child: Text("There is no comments!",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic)),
          );
  }

  SingleChildScrollView addCommentBottomSheet(
      UserPersonalInfo userPersonalInfo) {
    return SingleChildScrollView(
      child: Container(
        color: ColorManager.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selectedCommentInfo != null)
              Container(
                width: double.infinity,
                height: 45,
                color: ColorManager.lightGrey,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 17),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Text(
                                "Replying to ${selectedCommentInfo!.whoCommentInfo!.userName}",
                                style: const TextStyle(
                                    color: ColorManager.black54)),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCommentInfo = null;
                                _textController.text = '';
                              });
                            },
                            child: const Icon(Icons.close, size: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                'put emoticons here',
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: _textController.text.length < 70
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {},
                    child: CircleAvatarOfProfileImage(
                        imageUrl: userPersonalInfo.profileImageUrl,
                        bodyHeight: 330,),
                  ),
                  const SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.multiline,
                      cursorColor: ColorManager.teal,
                      maxLines: null,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: ColorManager.black26)),
                      autofocus: false,
                      controller: _textController,
                      onChanged: (e) {
                        setState(() {
                          _textController;
                        });
                      },
                    ),
                  ),
                  BlocBuilder<CommentsInfoCubit, CommentsInfoState>(
                      builder: (context1, state) {
                    //TODO here we want to make comment loading when he loading
                    return InkWell(
                      onTap: () {
                        if (_textController.text.isNotEmpty) {
                          postTheComment(userPersonalInfo);
                        }
                      },
                      child: Text(
                        'Post',
                        style: TextStyle(
                            color: _textController.text.isNotEmpty
                                ? ColorManager.blue
                                : ColorManager.lightBlue),
                      ),
                    );
                  })
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> postTheComment(UserPersonalInfo myPersonalInfo) async {
    if (selectedCommentInfo == null) {
      CommentsInfoCubit commentsInfoCubit =
          BlocProvider.of<CommentsInfoCubit>(context);
      await commentsInfoCubit.addComment(
          commentInfo:
              newCommentInfo(myPersonalInfo, DateOfNow.dateOfNow()));
    } else {
      Comment replyInfo = newReplyInfo( DateOfNow.dateOfNow(),
          selectedCommentInfo!, myPersonalInfo.userId);

      await ReplyInfoCubit.get(context)
          .replyOnThisComment(replyInfo: replyInfo);
    }
    setState(() {
      selectedCommentInfo = null;
      _textController.text = '';
    });
  }

  Comment newCommentInfo(
      UserPersonalInfo myPersonalInfo, String formattedDate) {
    final _whitespaceRE = RegExp(r"\s+");
    String textWithOneSpaces =
        _textController.text.replaceAll(_whitespaceRE, " ");
    return Comment(
        theComment: textWithOneSpaces,
        whoCommentId: myPersonalInfo.userId,
        datePublished: formattedDate,
        postId: widget.postId,
        likes: [],
        replies: []);
  }

  Comment newReplyInfo(
      String formattedDate, Comment commentInfo, String myPersonalId) {
    final _whitespaceRE = RegExp(r"\s+");
    String textWithOneSpaces =
        _textController.text.replaceAll(_whitespaceRE, " ");
    return Comment(
        datePublished: formattedDate,
        parentCommentId: commentInfo.parentCommentId,
        postId: commentInfo.postId,
        theComment: textWithOneSpaces,
        whoCommentId: myPersonalId,
        likes: []);
  }
}
