class Headlines{

  final String author;
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;
  final String content;

  Headlines({this.author, this.title, this.description, this.url,
      this.urlToImage, this.publishedAt, this.content});

  factory Headlines.fromJson(Map<String, dynamic> json){
    return Headlines(
      author: json['author'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      content: json['content']
    );
  }


}