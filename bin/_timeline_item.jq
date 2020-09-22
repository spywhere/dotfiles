.timelineItems.nodes | [ .[] | [
  .__typename,
  (.updatedAt // .createdAt),
  (.author.login // .actor.login),
  ((.body // "") | @base64),
  (.state // ""),
  (.label.name // ""),
  (.requestedReviewer.login // ""),
  (.commit.abbreviatedOid // ""),
  ((.commit.message // "") | @base64),
  (.commit.statusCheckRollup.state // ""),
  ((.beforeCommit.abbreviatedOid // .previousTitle // "") | @base64),
  ((.afterCommit.abbreviatedOid // .currentTitle // "") | @base64),
  ((.comments // "") | @base64)
] | join("|")] | join("$")
