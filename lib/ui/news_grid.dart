import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news_app/model/headlines.dart';
import 'package:cached_network_image/cached_network_image.dart';


Future<List<Headlines>> getJson() async{

  String url = 'https://newsapi.org/v2/top-headlines?country=us&apiKey=2331f4053d7647e8a3c595f6c0a49db0';
  http.Response response = await http.get(url);

  if(response.statusCode == 200){
    List data = json.decode(response.body)['articles'];
    List<Headlines> headlines = new List();
    print('Length: ${data.length}');
    for (int i=0; i<data.length;i++){
      headlines.add(Headlines.fromJson(data[i]));
      print(Headlines.fromJson(data[i]).title);
    }
    print('Length Head: ${headlines.length}');
    return headlines;
  }else{
    throw Exception('Failed to load post');
  }
}

void main() async{
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.deepPurple,
    ),
    home: new NewsHeadlines(),
  ));
}

class NewsHeadlines extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return NewsHeadlinesState();
  }
}

class NewsHeadlinesState extends State<NewsHeadlines>{

  Future<List<Headlines>> headlines;

  @override
  void initState() {
    super.initState();
    headlines = getJson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Center(
          child: Text('News App',
          style: TextStyle(
            color: Colors.white
          ),),
        ),
      ),*/

      body: gridViewNews(context),
    );
  }

  Widget gridViewNews(BuildContext context){
    return FutureBuilder<List<Headlines>>(
        future: headlines,
        builder: (context,snapshot){

          if (!snapshot.hasData){
            return new Container(
              child: new Center(
                child: new CircularProgressIndicator(),
              ),
            );
          }

          print('Text: ${snapshot.data[3].description}');
          return CustomScrollView(
            primary: false,
            slivers: <Widget>[
              SliverAppBar(
                title: Text('News app'),
                elevation: 8.0,
                centerTitle: true,
                floating: true,
                snap: true,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid.count(
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: newsCardItem(snapshot.data, context),


                ),)
            ],
          );
        });
  }
  List<Widget> newsCardItem(List<Headlines> data, BuildContext context) {

    List<Widget> newsHeadlinesWidget = new List<Widget>();
    if(data.isNotEmpty){
      for(int i=0; i<data.length; i++){
        Headlines headline = data[i];

        Widget widget = Card(
          margin: EdgeInsets.all(2.0),
          elevation: 8.0,
          child: GridTile(
            child: headline.urlToImage != null ? CachedNetworkImage(
              imageUrl: headline.urlToImage,
              fit: BoxFit.fill,
              placeholder: (context, url) => Image.network(url),
              errorWidget: (context, url, error) => new Icon(Icons.error),
            ) : Image.asset('images/error_bk.png'),
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              title: Container(
                child: Padding(
                    padding: EdgeInsets.all(0.0),
                    child: Text(headline.title,
                      maxLines: 3,
                      style: TextStyle(
                          fontWeight: FontWeight.bold
                      ),)
                ),
              ),
            ),
          ),
        );

        newsHeadlinesWidget.add(widget);
      }
      return newsHeadlinesWidget;
    }else{
      return [Text('No Data')];
    }
  }
}