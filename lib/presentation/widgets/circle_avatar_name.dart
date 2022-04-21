import 'package:flutter/material.dart';

class NameOfCircleAvatar extends StatelessWidget {
 final String circleAvatarName;
 final bool isForStoriesLine;

  const NameOfCircleAvatar(
    this.circleAvatarName,
    this.isForStoriesLine, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left:8.0),
      child: Text(
        circleAvatarName,
        maxLines: 1,
        style: TextStyle(
            fontWeight: isForStoriesLine ? FontWeight.normal : FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}
