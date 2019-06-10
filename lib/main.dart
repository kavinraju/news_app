import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'model/headlines.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async{
  runApp(NewsApp());
}

// Stateless Widget that returns MaterialApp
class NewsApp extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
            colorScheme: ColorScheme.light(
            primary: Colors.black,
            primaryVariant: Colors.black54
        ),
      ),
      home: new NewsHeadlines(),
    );
  }

}

// Here is the Stateful Widget
class NewsHeadlines extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return NewsHeadlinesState();
  }

}

// Here is the state for the above Stateful Widget
class NewsHeadlinesState extends State<NewsHeadlines>{


  static const String _page = 'page';
  static const String _grid = 'grid';

  PageController _pageController;
  //ValueNotifier<PopupMenuList> _selectedMenuItem;
  String _selectedMenuItem = 'page';
  var _currentPage = 0.0;
  Future<List<Headlines>> _headlines;
  bool _showDescription = false;
  bool isGridview = false;

  @override
  void initState() {
    super.initState();

    _headlines = getJson();  // get the headlines by making the http request
    //_selectedMenuItem = ValueNotifier<PopupMenuList>(PopupMenuList.PageView);
    _pageController = new PageController();  // Initialize page controller and add listener to update the current page value
    _pageController.addListener((){
      setState(() {
        _currentPage = _pageController.page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Center(
          child: Text('Daily News',
          style: TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 24.0,
            decorationColor: Colors.lightBlueAccent,
            decorationThickness: 1.0,
            decoration: TextDecoration.combine([
              TextDecoration.overline,
            ])
            ),
          ),
        ),
        centerTitle: true,

        actions: <Widget>[
          PopupMenuButton(
            onSelected: (value){
                  setState(() {
                    _selectedMenuItem = value;
                    switch(_selectedMenuItem){
                      case  _page:
                        isGridview = false;
                        break;
                      case _grid:
                        isGridview = true;
                        break;
                      default:
                        isGridview = false;
                        break;
                    }
                  });
            },
            itemBuilder: (BuildContext context) => [
              CheckedPopupMenuItem(
                checked: _selectedMenuItem == _page,
                value: _page,
                child: new Text('Page View'),
              ),
              new CheckedPopupMenuItem(
                checked: _selectedMenuItem == _grid,
                value: _grid,
                child: new Text('Grid view'),
              ),
            ],
          )
        ],
      ),

      body: isGridview ? gridViewNews(context, _headlines): pageViewNews(context, _headlines),
    );
  }

// Method to make http request and this returns List of Headlines objects.
  Future<List<Headlines>> getJson() async{

    String url = 'https://newsapi.org/v2/top-headlines?country=us&apiKey=2331f4053d7647e8a3c595f6c0a49db0';
    http.Response response = await http.get(url);

    if(response.statusCode == 200){
      List data = json.decode(response.body)['articles'];
      List<Headlines> headlines = new List();

      for (int i=0; i<data.length;i++){
        headlines.add(Headlines.fromJson(data[i]));
        /*
       data[i] is of Type _InternalLinkedHashMap<String, dynamic> and this is
       converted to Headline Object using factory method.
      */
      }
      return headlines;
    }else{
      throw Exception('Failed to load post');
    }
  }


  // This function returns the item of the PageView
  AnimatedContainer buildAnimatedNewsContainer(Headlines headline, BuildContext context, var position) {

    return AnimatedContainer(
               duration: Duration(milliseconds: 10),
               transform: Matrix4.identity()..rotateX(position),

                 child: Container(

                   child: Padding(
                     padding: const EdgeInsets.all(20.0),

                     child: GestureDetector(
                       onTap: (){
                         setState(() {
                           _showDescription = !_showDescription;
                         });
                       },
                       child: Stack(
                         children: <Widget>[

                           Card(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                             elevation: 4.0,
                             clipBehavior: Clip.hardEdge,

                             child: GridTile(
                               child: headline.urlToImage != null ?
                               CachedNetworkImage(
                                 imageUrl: headline.urlToImage,
                                 fit: BoxFit.fill,
                                 placeholder: (context, url) => Image.network(url),
                                 errorWidget: (context, url, error) => new Icon(Icons.error),) :
                               Image.asset('images/error_bk.png'),

                               footer: Visibility(
                                 visible: !_showDescription,

                                 child: GridTileBar(
                                   subtitle: Text(
                                       headline.description != null ? headline.description:""),
                                   backgroundColor: Colors.black54,
                                   title: Container(

                                     child: Text(
                                       headline.title != null ? headline.title:"",
                                       maxLines: 4,
                                       style: TextStyle(
                                           fontWeight: FontWeight.bold,
                                           fontSize: 16.0,
                                           color: Colors.white
                                       ),),
                                   ),
                                 ),
                               ),
                             ),
                           ),

                           Visibility(
                             visible: _showDescription,

                             child: Container(
                               margin: EdgeInsets.all(0.0),

                               child: Wrap(
                                 children: <Widget>[

                                   ClipRRect(
                                     clipBehavior: Clip.hardEdge,
                                     borderRadius: BorderRadius.circular(20.0),

                                     child: BackdropFilter(
                                       filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),

                                       child: Container(
                                         height: MediaQuery.of(context).size.height,
                                         width: MediaQuery.of(context).size.width,
                                         color: Colors.white.withOpacity(0.3),

                                         child: Padding(
                                           padding: const EdgeInsets.all(16.0),

                                           child: detailedNewsWidget(headline),
                                         ),
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           )
                         ],
                       ),
                     ),
                   ),
                 ),
             );
  }

  Widget pageViewNews(BuildContext context, Future<List<Headlines>> headlines){
    return FutureBuilder<List<Headlines>>(
        future: _headlines,
        builder: (context,snapshot){

          if (!snapshot.hasData){
            return new Container(
              child: new Center(
                child: new CircularProgressIndicator(),
              ),
            );
          }

          return PageView.builder(
              controller: _pageController,
              pageSnapping: false,
              itemCount: snapshot.data.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, position){

                Headlines headline = snapshot.data[position];

                if (position == _currentPage.floor()){

                  return Transform(
                      transform: Matrix4.identity()..rotateX(_currentPage - position),
                      child: buildAnimatedNewsContainer(headline, context, _currentPage - position));

                }else if(position == _currentPage.floor()+1){

                  return Transform(
                      transform: Matrix4.identity()..rotateY(_currentPage - position),
                      child: buildAnimatedNewsContainer(headline, context, _currentPage - position));

                }else {

                  return buildAnimatedNewsContainer(headline, context, _currentPage - position);

                }
              });
        });
  }


  //This function return the Widget which shows the details of the news in Page View
  Widget detailedNewsWidget(Headlines headline) {

    var date = DateTime.parse(headline.publishedAt);
    var dateStr = formatDate(date, [dd,' ', M, ' ', yyyy]);//'\n', HH, ':', nn,

    return Container(
      alignment: Alignment.center,

      child: Column(
        children: <Widget>[

          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right:2.0),
                  child: Icon(
                    Icons.calendar_today,
                    size: 15.0,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14.0
                  ),
                ),
              ],
            ),
          ),

          Padding(padding: EdgeInsets.all(2.0)),

          Text(headline.title != null ? headline.title:'',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 24.0
            ),
          ),

          Padding(padding: EdgeInsets.all(5.0)),

          Text(headline.description != null ? headline.description:'',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18.0
            ),
          ),

          Padding(padding: EdgeInsets.all(5.0)),

          Text(headline.content != null ? headline.content:'',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18.0
            ),
          ),

          Padding(padding: EdgeInsets.all(10.0)),

          RichText(
            text: TextSpan(
              text: 'Click here for source',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 12.0
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if(headline.url != null) {
                    launch(headline.url);
                  }
                },
            ),
          ),
        ],
      ),
    );
  }

  // This function return grid view of the headlines using CustomScrollView - slivers
  Widget gridViewNews(BuildContext context, Future<List<Headlines>> headlines){
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

          return CustomScrollView(
            primary: false,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid.count(
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    children: newsCardItem(snapshot.data, context)
                ),)
            ],
          );
        });
  }

  // This function returns the list of all the news cards for the grid view
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

// enum is created for the Popup menu item list
enum PopupMenuList{
  PageView,
  GridView
}

/*

              These were various methods tried to build the popup menu
               ~ Using RadioListTile ~
              return List<PopupMenuEntry<PopupMenuList>>.generate(
                PopupMenuList.values.length,
                  (int index){
                  return PopupMenuItem(
                    value: PopupMenuList.values[index],
                    child: AnimatedBuilder(
                        animation: _selectedMenuItem,
                        builder: (BuildContext context, Widget child){
                          return RadioListTile<PopupMenuList>(
                              title: child,
                              value: PopupMenuList.values[index],
                              groupValue: _selectedMenuItem.value,
                              onChanged: (PopupMenuList menuList){
                                _selectedMenuItem.value = menuList;
                              });
                        }),
                  );
                  }
              );
              ~ Normal Popup menu ~
              return PopupMenuList.options.map((String option){
                return PopupMenuItem<String>(
                  value: option,
                  child: Container(
                    color: Colors.black,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle
                    ),
                    child: Text(option,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black
                    ),
                    ),
                  ),
                );
              }).toList();
              */