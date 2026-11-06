// A subscribed podcast in the user's library.
//
// NOTE: this is the original author's quick implementation of the Library
// feature. It does not follow the conventions used elsewhere in the app.
class SubscribedPodcast {
  SubscribedPodcast({
    required this.id,
    required this.title,
    required this.author,
    this.artworkUrl,
  });

  int id;
  String title;
  String author;
  String? artworkUrl;
}
