.timelineItems.nodes | [ .[] | [
  .__typename,
  (.updatedAt // .createdAt),
  (.author.login // .actor.login),
  ((.body // .source.title // "") | @base64),
  (.state // ""),
  (.label.name // .source.number // ""),
  (.requestedReviewer.login // ""),
  (.commit.abbreviatedOid // ""),
  ((.commit.message // "") | @base64),
  (.commit.statusCheckRollup.state // ""),
  ((.beforeCommit.abbreviatedOid // .previousTitle // "") | @base64),
  ((.afterCommit.abbreviatedOid // .currentTitle // "") | @base64),
  ((.comments // "") | @base64)
] | join("|")] | join("$")
