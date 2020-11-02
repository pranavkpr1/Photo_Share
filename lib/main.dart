import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as ImageLib;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share/share.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import  "package:jagnik/appimage.dart";
import 'package:photofilters/filters/filters.dart';
import 'package:photofilters/filters/preset_filters.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progress_indicators/progress_indicators.dart';

Function() _refreshCallback;
const Color buttonColor=const Color(0xFFF37E37);
const Color accentColor=const Color(0xFFF27718);
const Color highlightColor=const Color(0xFFF5AB2E);//const Color(0xFFF2673B)
//const Color appBarColor2=const Color(0xFFF2673B);
final _random = new Random();
bool asyncButtonCall=false;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevDarshan Photo Share',
      theme: ThemeData(
        buttonTheme: ButtonThemeData(
            buttonColor:  buttonColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            textTheme: ButtonTextTheme.primary),
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  double _initialSliderHeight = 80;
  double _sliderHeight = 80;
  TabController tabController;
  TextStyle selectedTextstyle;
  String imageSource = "internet";
  GlobalKey previewContainer = new GlobalKey();
  double editBoxSize = 200.0;
  double x = 10.0;
  double y = 100.0;
  Directory cache;

  BoxDecoration editBoxDecorator = BoxDecoration(
      border: Border.all(color: highlightColor, width: 2.0),
      borderRadius: BorderRadius.all(Radius.circular(5.0)));

  String textToShare;
  final textController = TextEditingController();
  String previewImage;
  double fontSize = 30.0;
  String selectedFont = "Lato";
  Color selectedFontColor=Colors.white;
  TextAlign textAlign = TextAlign.start;
  bool showProgressOnGenerate= false;
  String filterApplied = "default";
  Widget zoom;
  Widget oldzoom;
  String oldImageName;

  List backgrounds = [
    "https://images.unsplash.com/photo-1472552944129-b035e9ea3744",
    "https://images.unsplash.com/photo-1577283617116-cad711fc556d",
    "https://images.unsplash.com/photo-1577261041320-fc4ec1e6b2a2",
    "https://images.unsplash.com/photo-1577218545339-2506e153c843",
    "https://images.unsplash.com/photo-1577269330970-d4f24a498e2f",
    "https://images.unsplash.com/photo-1577318530987-f2f4b903ad37",
    "https://images.unsplash.com/photo-1577234231282-d5017c6ac8b4",
    "https://images.unsplash.com/photo-1577154881361-c957822c3a0c",
  ];

  List quotes = [
   "Hare Krishna",
    "Jai Bholenath",
    "Happy Diwali",
    "Happy Navratri",
    "Jai Siya Ram",
    "I love DevDarshan",
    "Om Sai Ram",
    "Good Morning",
    "Namaste",
    "Om Namah Shivaya"
  ];

  String backgroundImage =
      "https://images.unsplash.com/photo-1577261041320-fc4ec1e6b2a2";

  void initState() {
    tabController = new TabController(length: 3, vsync: this);
    selectedTextstyle =
        TextStyle(color: Colors.white, fontSize: 30, fontFamily: "Lato");

    textToShare = quotes[_random.nextInt(quotes.length)];
    textController.text = textToShare;
    _loadAImagesFromDownload();
    _refreshCallback=_refresh;
    asyncButtonCall=false;
    oldImageName="";
    super.initState();

  }
   void dispose(){

     if(cache!=null && cache.existsSync() )
     cache.deleteSync(recursive: true);

    super.dispose();
   }

   void _refresh() {
     setState(() {});
   }

  Future<List<String>> _loadAImagesFromDownload() async {
    try {
      final directory = await getExternalStorageDirectory();
      var images = await rootBundle.loadString(directory.path + '/images.json');
      var responseJSON = json.decode(images);
      List<String> img = List();
      for (var _i = 0; _i < responseJSON["images"].length; _i++) {
        img.add(responseJSON["images"][_i]);
      }
      setState(() {
        backgrounds = img;
        backgroundImage = img[0];
      });
      return img;
    } catch (err) {
      return null;
    }
  }

  List layouts = [
    {"text": "Lato"},
    {"text": "PoiretOne"},
    {"text": "Monoton"},
    {"text": "BungeeInline"},
    {"text": "ConcertOne"},
    {"text": "FrederickatheGreat"},
    {"text": "Martel"},
    {"text": "Vidaloka"}
  ];

  List fontsizes = [
    {"size": 30.0},
    {"size": 40.0},
    {"size": 50.0}
  ];

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height;
    double _maxHeightBottomSheet = _height - _initialSliderHeight - 20;
    double _middleHeightBottomSheet = _height / 2 - _initialSliderHeight;
    var _layouts = layouts.map<Widget>((book) => _fontView(book)).toList();

   //    DevDarshan font sizes for text
    var _fontSizes = fontsizes.map<Widget>((font) {
      return Container(
          child: GestureDetector(
              onTap: () {
                setState(() {
                  fontSize = font["size"];
                  selectedTextstyle = TextStyle(
                      fontSize: font["size"],
                      fontFamily: selectedFont,
                      color: selectedFontColor);
                });
              },
              child: Container(
                color: buttonColor,
                alignment: Alignment.center,
                child: Text(
                  "A",
                  style: TextStyle(
                      fontSize: font["size"] - 20, color: Colors.white),
                ),
              )));
    }).toList();

    //DevDarshan textAlign
    var _textAlignments = ["left", "center", "right"].map<Widget>((align) {
      return Container(
          child: GestureDetector(
        onTap: () {
          setState(() {
            textAlign = align == "left"
                ? TextAlign.left
                : align == "center" ? TextAlign.center : TextAlign.right;
          });
        },
        child: Container(
            color: buttonColor,
            child: Icon(
              align == "left"
                  ? Icons.format_align_left
                  : align == "center"
                      ? Icons.format_align_center
                      : Icons.format_align_right,
              color: Colors.white,
              size: 20,
            )),
      ));
    }).toList();

    //DevDarshan first menu of font size and text alignments
    var menusOnFont = _fontSizes..addAll(_textAlignments);

    //max width for text box
    editBoxSize = _width - 10;


    var _backgrounds = [_pickfromGallery()]..addAll(
        backgrounds.map<Widget>((image) => _makeBackground(image)).toList());

    return Scaffold(
        body: ModalProgressHUD(
        inAsyncCall: asyncButtonCall,
        progressIndicator: Center(
        child: Container(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
        Center(
        child: HeartbeatProgressIndicator(
        child: FaIcon(FontAwesomeIcons.om, size: 10, color:Colors.white))),
    SizedBox(height: 8),
    Text('Please wait...', style: TextStyle(color:Colors.white)),
    ]))),
    child:
        Stack(
      children: <Widget>[

        buildBackground(context, _width, _height, backgroundImage, imageSource),
        _screenShotButton(context),
        //_previewDownloadedImage(),
        _appBottomSheetMenus(
            context,
            _width,
            _height,
            _middleHeightBottomSheet,
            _maxHeightBottomSheet,
            _layouts,
            _backgrounds,
            _fontSizes,
            menusOnFont),

      ],
    )));
  }



//DevDarshan start and make Background
  Widget buildBackground(BuildContext context, _width, _height, backgroundImage, imageSource) {
    return  RepaintBoundary(
      key: previewContainer,
      child: Container(
        width: _width,
        height: _height,
        child: Stack(
          children: <Widget>[
            imageSource == "internet"
                ? CachedNetworkImage(
              placeholder: (context, url) =>
                  Center(child: CircularProgressIndicator()),
              imageUrl:
              backgroundImage + "?w=" + _width.toInt().toString(),
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      //colorFilter: ColorFilter.matrix(filterMatrix),
                    )),
              ),
              errorWidget: (context,url,error) =>
                  Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/default.jpeg"),
                            //colorFilter: ColorFilter.matrix(filterMatrix),
                            fit: BoxFit.cover)),
                  ),
            ) : Container(
                 width: _width,
                  height: _height,
                  color: Colors.black87,
                  //child: ColorFiltered(
                    //colorFilter: ColorFilter.matrix(filterMatrix) ,
                    child: zoom == null ? Container(): zoom,
                  //)
               ),
            lyricsText(_width, _height, context),

          ],
        ),
      ),
    );

  }



  //bottom menu for filters and font size
  Widget _appBottomSheetMenus(
      BuildContext context,
      _width,
      _height,
      _middleHeightBottomSheet,
      _maxHeightBottomSheet,
      _layouts,
      _backgrounds,
      _fontSizes,
      menusOnFont) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: _width,
        decoration: BoxDecoration(shape: BoxShape.rectangle, boxShadow: [
          BoxShadow(
              spreadRadius: 100.0,
              offset: Offset(0, 60),
              color: Color.fromARGB(150, 0, 0, 0),
              blurRadius: 100.0)
        ]),
        child: Column(
          children: <Widget>[
            _bottomSheetScrollButton(context, _width, _height,
                _middleHeightBottomSheet, _maxHeightBottomSheet),
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0)),
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.fastLinearToSlowEaseIn,
                width: _width,
                height: _sliderHeight,
                color: Colors.transparent,
                child: Container(
                  child: Column(
                    children: <Widget>[
                      new TabBar(controller: tabController, tabs: [
                        new Tab(icon: const Icon(Icons.filter_vintage, color:Colors.white)),
                        new Tab(icon: const Icon(Icons.font_download, color:Colors.white)),
                        new Tab(icon: const Icon(Icons.image, color:Colors.white))
                      ]),
                      Expanded(
                          child: SizedBox(
                              child: new TabBarView(
                                  controller: tabController,
                                  children: [
                            _filterList(),
                              _textList(menusOnFont,_layouts),
                            CustomScrollView(
                              primary: false,
                              slivers: <Widget>[
                                SliverPadding(
                                  padding: const EdgeInsets.all(20),
                                  sliver: SliverGrid.count(
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      crossAxisCount: 3,
                                      children: _backgrounds),
                                ),
                              ],
                            )
                          ])))
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  //DevDarshan button for scrolling up and down the font and filter menu
  Widget _bottomSheetScrollButton(BuildContext context, _width, _height,
      _middleHeightBottomSheet, _maxHeightBottomSheet) {
    return
      GestureDetector(
          onTap: () {
            setState(() {
              _sliderHeight = _sliderHeight == _initialSliderHeight
                  ? _middleHeightBottomSheet
                  : _sliderHeight == _maxHeightBottomSheet
                  ? _initialSliderHeight
                  : _maxHeightBottomSheet;
            });
          },
          onVerticalDragUpdate: (drag) {
            setState(() {
              _sliderHeight = drag.globalPosition.dy < _height - 30
                  ? _height - drag.globalPosition.dy
                  : _initialSliderHeight;
            });
          },
          onVerticalDragEnd: (drag) {
            setState(() {
              _sliderHeight = _sliderHeight > _height / 2
                  ? _maxHeightBottomSheet
                  : _sliderHeight > _height / 3
                  ? _middleHeightBottomSheet
                  : _initialSliderHeight;
            });
          },
        child:
      Container(
        width: _width,
        alignment: Alignment.center,
          child: Container(
              width: 140,
              height: 40,
              color: Colors.transparent,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child:

                  RotatedBox(
                    quarterTurns: _sliderHeight == _maxHeightBottomSheet ? 3 : 1,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Icon(
                        Icons.first_page,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ))),
      )
    );
  }


  //DevDarshan show the filters in UI
  Widget _filterList() {
    return
      Container(
          child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Divider(height: 5),
                  Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      margin: EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      height: 30,
                      child: ListView.builder(
                          itemCount: presetFiltersList.length,
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            return Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap:()  {
                              setState(() {
                                asyncButtonCall = true;
                              });
                                //_refreshCallback();

                                applyFilter(presetFiltersList[index], backgroundImage);


                                  },

                                child:Center(
                                  //padding: const EdgeInsets.only(left:5.0),
                                  child:Text(presetFiltersList[index].name+"   ", style: TextStyle(
                                    color: Colors.white,
                                  ),),
                                )),
                              ],
                            );
                          }

                      )

                  )
                ],
              )
          )
      );

  }


  //DevDarshan apply filter on the image
  void applyFilter(Filter filter, String src) async {

    ImageLib.Image image;

    // get image bytes based on the file location in gallery or on internet
    if(imageSource=="gallery")
      image =ImageLib.decodeImage(await File(src).readAsBytes());
    else {
      http.Response response = await http.get(src);
      image=ImageLib.decodeImage(response.bodyBytes);
    }

    //apply filter on bytes of image
    var pixels = image.getBytes();
    filter.apply(pixels, image.width, image.height);
    ImageLib.Image outputImage = ImageLib.Image.fromBytes(image.width, image.height, pixels);

    //temporary storage for saving the filtered image

    if(cache==null)
     cache = await getTemporaryDirectory();

    var _file = cache.path;
    String now = DateTime.now().toString();
    now = now.split(new RegExp(r"(:|-)")).join("_");
    now = now.split(" ").join("_");
    now = now.split(".").join("_");
    String _filename = '$_file/q-$now.png';
    File imgFile = new File(_filename);

    //save the filtered image in temporary storage
    await imgFile.writeAsBytes(ImageLib.encodeNamedImage(outputImage, _filename));

    //change the path for background image after the filter
    if (imgFile != null && imgFile.lengthSync()!=0){

      setState(() {
        zoom = null;
      });
      setState(() {
        imageSource = "gallery";
        backgroundImage = imgFile.path;
        zoom = new ZoomableImage(
          image:FileImage(File(backgroundImage)),
          placeholder: Center(child: CircularProgressIndicator(),),
          imageName: _filename,
          oldImageName:oldImageName
        );
        oldzoom = zoom;
        oldImageName=_filename;


      });
      asyncButtonCall=false;
      _refreshCallback();
    }
    else {
      if (oldzoom != null)
        setState(() {
          zoom = oldzoom;

        });
      asyncButtonCall=false;
      _refreshCallback();
    }
  }

  Widget _textList(menusOnFont,_layouts){

    final List<String> colorList=["FFFFFF","808080", "000000","F68C24","F5AB2E","F2673B", "FF0000", "800000", "FFFF00", "808000","00FF00", "008000", "00FFFF", "008080", "0000FF", "000080", "FF00FF", "800080"];

    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverToBoxAdapter(child:
        SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Divider(height: 2),
                Container(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    margin: EdgeInsets.symmetric(
                      vertical: 5,
                    ),
                    height: 20,
                    child: ListView.builder(
                        itemCount: colorList.length,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap:()  {
                                  setState(() {
                                    selectedFontColor=hexToColor(colorList[index]);
                                    selectedTextstyle = TextStyle(
                                        fontSize: fontSize,
                                        fontFamily: selectedFont,
                                        color: hexToColor(colorList[index]));
                                  });

                                },
                                child:Container(
                                  width:15,
                                  height:18,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hexToColor(colorList[index]),
                                    shape: BoxShape.circle,


                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      2,
                                    ),

                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                    )

                )
              ],
            )
        )),
        SliverPadding(
          padding:
          const EdgeInsets.fromLTRB(10, 10, 20, 0),
          sliver: SliverGrid.count(
              crossAxisSpacing: 20,
              mainAxisSpacing: 10,
              crossAxisCount: 6,
              children: menusOnFont),
        ),
    SliverToBoxAdapter(child:SizedBox(height:5)),
        SliverToBoxAdapter(child:
         SingleChildScrollView(
                child: Column(
                children: <Widget>[
                Divider(height: 2),
                Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                margin: EdgeInsets.symmetric(
                vertical: 5,
                ),
                height: 65,
                child: ListView.builder(
                itemCount: _layouts.length,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  return Row(
                  children:<Widget>[
                    _layouts[index],
                    SizedBox(width:8)
                      ]);
                }
               ))])))
      ],
    );
  }

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(0, 6), radix: 16) + 0xFF000000);
  }
 //DevDarshan Play with the text
  Widget lyricsText(_width, _height, context) {
    return Positioned(
      top: y,
      left: x,
      child: GestureDetector(
          onPanUpdate: (tap) {
            setState(() {
              if ((x + editBoxSize + tap.delta.dx - 100) < _width)
                x += tap.delta.dx;
              if ((y + tap.delta.dy) < _height) y += tap.delta.dy;
            });
          },
          onTap: () {
            showEditBox(context);
            ;
          },
          child: Container(
            width: editBoxSize,
            padding: EdgeInsets.all(10.0),
            child: Text(
              textToShare,
              style: selectedTextstyle,
              textAlign: textAlign,
            ),
          )),
    );
  }

  //DevDarshan change fontStyle
  Widget _fontView(fontStyle) {
    var font;
    switch (fontStyle["text"]) {
      case "lato":
        font = TextStyle(color: Colors.white, fontSize: 30, fontFamily: "Lato");
        break;
      case "poiretOne":
        font = TextStyle(
            color: Colors.white, fontSize: 30, fontFamily: "PoiretOne");
        break;
      case "monotone":
        font =
            TextStyle(color: Colors.white, fontSize: 30, fontFamily: "Monoton");
        break;
      case "BungeeInline":
        font = TextStyle(
            color: Colors.white, fontSize: 30, fontFamily: "BungeeInline");
        break;
      case "FrederickatheGreat":
        font = TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: "FrederickatheGreat");
        break;
      case "ConcertOne":
        font = TextStyle(
            color: Colors.white, fontSize: 30, fontFamily: "ConcertOne");
        break;
      case "Martel":
        font =
            TextStyle(color: Colors.white, fontSize: 30, fontFamily: "Martel");
        break;
      case "Vidaloka":
        font = TextStyle(
            color: Colors.white, fontSize: 30, fontFamily: "Vidaloka");
        break;
      default:
        font = TextStyle(color: Colors.white, fontSize: 30, fontFamily: "Lato");
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFont = fontStyle["text"];
          selectedTextstyle = TextStyle(
              color: selectedFontColor,
              fontSize: fontSize,
              fontFamily: fontStyle["text"]);
        });
      },
      child: selectedFont == fontStyle["text"]
          ? Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: highlightColor, width: 3)),
        child: Text(
          "Aa",
          style: font,
        ),
      )
          : Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Colors.grey, width: 0)),
        child: Text(
          "Aa",
          style: font,
        ),
      ),
    );
  }

  // DevDarshan On Click Text and Change Text
  showEditBox(BuildContext context) {
    return showDialog(
        context: context,
        child: new AlertDialog(
          backgroundColor: Color.fromARGB(240, 200, 200, 200),
          title: new Text("Edit Text"),
          content: Container(
              height: 150,
              child: ListView(
                children: <Widget>[
                  new TextField(
                    minLines: 3,
                    controller: textController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    autofocus: true,
                    decoration: InputDecoration(hintText: textToShare),
                    onChanged: (newVal) {
                      setState(() {
                        textToShare = newVal;
                      });
                    },
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      RaisedButton(
                        child: Text('Done',style:TextStyle(color:Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  )
                ],
              )),
        ));
  }


  //DevDarshan pick from gallery icon in the third tab of predefined photos & existing photos
  Widget _pickfromGallery() {
    return GestureDetector(
      onTap: () {
        setState(() {
          zoom = null;
        });
        getImageFromGallery();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.rectangle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.camera,
              size: 50,
              color: Colors.white,
            ),
            Text(
              "Gallery",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  // DevDarshan pick images from the gallery & also pinch to zoom functionality
  Future getImageFromGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image != null)
      setState(() {
        imageSource = "gallery";
        backgroundImage = image.path;
          zoom = ZoomableImage(
          image:FileImage(File(backgroundImage)),
          placeholder: Center(child: CircularProgressIndicator(),),
          imageName: backgroundImage,
          oldImageName: oldImageName
        );
        oldzoom = zoom;
        oldImageName=backgroundImage;
      });
    else
      if(oldzoom != null)
      setState(() {
        zoom = oldzoom;
      });
  }

  // DevDarshan make bacground of already created images for sharing
  Widget _makeBackground(image) {
    return GestureDetector(
      onTap: () {
        setState(() {
          imageSource = "internet";
          backgroundImage = image;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          shape: BoxShape.rectangle,
        ),
        child: CachedNetworkImage(
          placeholder: (context, url) => CircularProgressIndicator(),
          imageUrl: image + "?w=120",
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
                image:
                DecorationImage(image: imageProvider, fit: BoxFit.cover)),
          ),
          errorWidget: (context, url, error) =>Container(
            child: Icon(Icons.error,color: Colors.white70,),
          ),
        ),
      ),
    );
  }

  Widget _screenShotButton(BuildContext context) {
    return Positioned(
      top: 30,
      right: 20,
      child: RaisedButton(
        disabledColor: buttonColor,
        child: Text(
          'Share',
          style: TextStyle(fontSize: 12, color:Colors.white),
        ),
        onPressed: () {
          if(!showProgressOnGenerate){
            FocusScope.of(context).requestFocus(FocusNode());
            asyncButtonCall =true;
            _refreshCallback();
            takeScreenShot(context);


          }
        },
      ),
    );
  }

  takeScreenShot(BuildContext context) async {
    setState(() {
      showProgressOnGenerate = true;
    });
    RenderRepaintBoundary boundary =
    previewContainer.currentContext.findRenderObject();
    double pixelRatio =
        MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;

    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    final directory = await getExternalStorageDirectory();
    var _file = directory.path;
    String now = DateTime.now().toString();
    now = now.split(new RegExp(r"(:|-)")).join("_");
    now = now.split(" ").join("_");
    now = now.split(".").join("_");
    String _filename = '$_file/q-$now.png';
    File imgFile = new File(_filename);
    imgFile.writeAsBytesSync(pngBytes);

    setState(() {
      previewImage =_filename;
      showProgressOnGenerate =false;
    });

    share();
  }

  void share() {
    asyncButtonCall =false;
    _refreshCallback();
    Share.shareFiles([previewImage == null ? null : previewImage], text: 'Download DevDarshan');

  }
}
