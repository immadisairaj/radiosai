import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:radiosai/screens/media/media.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Search extends StatefulWidget {
  Search({
    Key key,
  }) : super(key: key);

  @override
  _Search createState() => _Search();
}

class _Search extends State<Search> {
  /// webview controller for hidden web view
  WebViewController _webViewController;

  /// variable to show the loading screen
  bool _isLoading = false;

  /// variable to show the hidden web view
  bool _isGettingData = false;

  /// form data to send to web view after updating url
  Map<String, String> globalFormData;

  /// contains the base url of the radio sai search page
  final String baseUrl = 'https://radiosai.org/program/SearchProgramme.php';

  /// the url with all the parameters (a unique url)
  String finalUrl = '';

  /// list of categories supported for search
  final List<String> categoriesList = const [
    'Any',
    'Bhajan',
    'Concert',
    'Discourse',
    'Instrumental',
    'Song',
    'Special',
  ];

  /// the search key
  ///
  /// required for loading data
  String description = '';

  /// current selected category
  String category = 'Any'; // from categoriesList
  // String language = '';

  final DateTime now = DateTime.now();

  /// date for the search (played on)
  ///
  /// set this null to unselect date
  DateTime selectedDate;

  /// selected date string to display in the selection widget
  ///
  /// associated with [selectedDate]
  String selectedDateString = '';

  /// current page to display
  int currentPage = 1;

  /// files to display per page.
  /// value is 100
  ///
  /// max 3 digits allowed
  final int filesPerPage = 100; // max 3 digits
  /// last page exists / total no. of pages
  int lastPage = 0;

  /// set true if changing page -
  /// have to load for 3rd time also
  /// for page change
  ///
  /// set false if searching new
  bool _isChangingPage = false;

  /// table head data retrieved from net
  ///
  /// doesn't use this as of now
  ///
  /// return data from tableHead
  /// [0] Sl.No. [1] Category
  /// [2] First Broad Cast [3] Programme Description
  /// [4] Language [5] Duration(min)
  /// [6] Download-fids
  List<String> _finalTableHead = [];

  /// final table body data retrieved from the net
  ///
  /// can be [['start']] or [['wrong']] or
  /// [['null']] or [['timeout']] or data.
  /// Each have their own display widgets
  ///
  /// return data from table body
  /// [0] Sl.No. [1] Category
  /// [2] First Broad Cast [3] Programme Description
  /// [4] Language [5] Duration(min)
  /// [6] Download-fids
  List<List<String>> _finalTableData = [
    ['start']
  ];

  /// form key used to validate search key
  final _formKey = GlobalKey<FormState>();

  /// used to change the text in date field
  TextEditingController _dateController = new TextEditingController();

  // below are used to hide/show the form widget
  ScrollController _scrollController;
  bool _showDropDown = true;
  bool _isScrollingDown = false;

  /// used to know if the web page is loading first time
  bool _isFirstLoading = true;

  /// used to know if the web page is loading second time
  bool _isSecondLoading = false;

  /// focus node attached to TextFormField of Search
  FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    selectedDate = null;

    super.initState();

    _scrollController = new ScrollController();
    _scrollController.addListener(_scrollListener);

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    _textFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        child: Column(
          children: [
            if (!isSmallerScreen)
              AnimatedContainer(
                height: _showDropDown ? null : 0,
                duration: Duration(milliseconds: 500),
                child: _searchForm(isDarkTheme),
              ),
            Expanded(
              child: Stack(
                children: [
                  if (_isLoading == false &&
                      _finalTableData[0][0] != 'null' &&
                      _finalTableData[0][0] != 'timeout' &&
                      _finalTableData[0][0] != 'wrong' &&
                      _finalTableData[0][0] != 'start')
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: Scrollbar(
                        radius: Radius.circular(8),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          child: ConstrainedBox(
                            // have minimum height to reload even when 1 item is present
                            constraints: BoxConstraints(
                                minHeight: (isSmallerScreen || !_showDropDown)
                                    ? MediaQuery.of(context).size.height * 0.9
                                    : MediaQuery.of(context).size.height * 0.7),
                            child: Card(
                              elevation: 0,
                              color: isDarkTheme
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: EdgeInsets.only(top: 2, bottom: 2),
                                  itemCount: _finalTableData.length,
                                  itemBuilder: (context, index) {
                                    List<String> rowData =
                                        _finalTableData[index];

                                    String category = rowData[1];
                                    String programe = rowData[3];
                                    String language = rowData[4];
                                    String duration = '${rowData[5]} min';
                                    String fids = rowData[6];
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: 2, right: 2),
                                          child: Card(
                                            elevation: 0,
                                            color: isDarkTheme
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            child: InkWell(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: 2, bottom: 2),
                                                child: Center(
                                                  child: ListTile(
                                                    title: Text(
                                                      category,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .accentColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(programe),
                                                    trailing: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Text(
                                                          language,
                                                          style: TextStyle(
                                                            color: isDarkTheme
                                                                ? Colors
                                                                    .grey[300]
                                                                : Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                        Text(
                                                          duration,
                                                          style: TextStyle(
                                                            color: isDarkTheme
                                                                ? Colors
                                                                    .grey[300]
                                                                : Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              focusColor: isDarkTheme
                                                  ? Colors.grey[700]
                                                  : Colors.grey[300],
                                              onTap: () {
                                                if (fids != '')
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Media(
                                                                  fids: fids)));
                                              },
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ),
                                        if (index != _finalTableData.length - 1)
                                          Divider(
                                            height: 2,
                                            thickness: 1.5,
                                          ),
                                      ],
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // show the below when wrong string is typed
                  if (_finalTableData[0][0] == 'wrong' && _isLoading == false)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No Data Available for the search values'),
                      ),
                    ),
                  // show the below when at start
                  if (_finalTableData[0][0] == 'start' && _isLoading == false)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Start by entering value in Search'),
                      ),
                    ),
                  // show when no data is retrieved
                  if (_finalTableData[0][0] == 'null' && _isLoading == false)
                    NoData(
                      backgroundColor: backgroundColor,
                      text:
                          'No Data Available,\ncheck your internet and try again',
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _updateURL();
                        });
                      },
                    ),
                  // show when no data is retrieved and timeout
                  if (_finalTableData[0][0] == 'timeout' && _isLoading == false)
                    NoData(
                      backgroundColor: backgroundColor,
                      text:
                          'No Data Available,\nURL timeout, try again after some time',
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _updateURL();
                        });
                      },
                    ),
                  // Shown but hidden when loading the data
                  if (_isGettingData) _hiddenWebView(),
                  // Shown when it is loading
                  if (_isLoading)
                    Container(
                      color: backgroundColor,
                      child: Center(
                        child: _showLoading(isDarkTheme),
                      ),
                    ),
                ],
              ),
            ),
            _pagination(),
          ],
        ),
      ),
      bottomNavigationBar: BottomMediaPlayer(),
    );
  }

  /// sets the [finalUrl]
  ///
  /// continues the process by retrieving the data
  _updateURL() async {
    String formattedDate;
    if (selectedDate == null) {
      formattedDate = '';
    } else {
      formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
    }

    String categoryPass = category;
    if (categoryPass == 'Any') {
      categoryPass = '';
    }

    var data = new Map<String, String>();
    data['form'] = 'search';
    data['description_s'] = description;
    data['filesperpage_s'] = '$filesPerPage';
    data['category_s'] = categoryPass;
    // data['language_s'] = language;
    data['pdate_s'] = formattedDate;
    data['page'] = '$currentPage';

    // unique url for putting data into cache and getting it
    String url = '$baseUrl?form=${data['form']}' +
        '&filesperpage_s=${data['filesperpage_s']}' +
        '&description_s=${data['description_s']}' +
        '&category_s=${data['category_s']}' +
        // '&language_s=${data['language_s']}' +
        '&pdate_s=${data['pdate_s']}' +
        '&page=${data['page']}';
    finalUrl = url;
    _getData(data);
  }

  /// retrieve the data from finalUrl
  ///
  /// if file is not in cache, enable to
  /// load data from web view
  ///
  /// else continues the process by sending it to parse
  /// if the data is retrieved
  _getData(Map<String, String> formData) async {
    String tempResponse = '';
    // checks if the file exists in cache
    var fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
    if (fileInfo == null) {
      // get the data into cache from webview_flutter
      setState(() {
        globalFormData = formData;
        _isGettingData = true;
      });
    } else {
      // get data from file if present in cache
      tempResponse = fileInfo.file.readAsStringSync();
    }
    if (tempResponse == '') return;
    _parseData(tempResponse);
  }

  /// parses the data retrieved from url.
  /// sets the final data to display
  _parseData(String response) {
    var document = parse(response);

    if (!_isChangingPage) {
      var paging = document.getElementsByTagName('p');
      if (paging != null && paging.length > 0) {
        var pages = paging[0].getElementsByTagName('a');

        lastPage = (pages.length == 0) ? 1 : pages.length;
        // set changing page to true.
        // assumes that user can change page
        // after data is loaded
        _isChangingPage = true;
      }
    }

    var table = document.getElementById('sea');
    // parsing table heads
    List<String> tableHead = [];
    for (int i = 1; i < 8; i++) {
      tableHead.add(table.getElementsByTagName('th')[i].text);
      var stringLength = tableHead[i - 1].length;
      tableHead[i - 1] = tableHead[i - 1].substring(4, stringLength - 3);
      tableHead[i - 1] = tableHead[i - 1].replaceAll('\n', ' ');
      tableHead[i - 1] = tableHead[i - 1].replaceAll('\t', '');
      tableHead[i - 1] = tableHead[i - 1].trim();
    }
    // return data from tableHead
    // [0] Sl.No. [1] Category
    // [2] First Broad Cast [3] Programme Description
    // [4] Language [5] Duration(min)
    // [6] Download-fids

    // parsing table data
    List<List<String>> tableData = [];
    int dataLength = table.getElementsByTagName('tr').length;
    if (dataLength == 0) {
      tableData = [
        ['null']
      ];
      setState(() {
        // set the data
        _finalTableHead = tableHead;
        _finalTableData = tableData;

        // loading is done
        _isLoading = false;
      });
      return;
    } else if (dataLength == 2 &&
        table.getElementsByTagName('td').length == 1) {
      tableData = [
        ['wrong']
      ];
      setState(() {
        // set the data
        _finalTableHead = tableHead;
        _finalTableData = tableData;

        // loading is done
        _isLoading = false;
      });
      return;
    }
    for (int i = 1; i < dataLength; i++) {
      List<String> tempList = [];
      var rowData =
          table.getElementsByTagName('tr')[i].getElementsByTagName('td');
      // do not add if there are any suggestions
      if (rowData.length == 1) continue;

      for (int j = 1; j < 8; j++) {
        if (j != 4 && j != 7) {
          tempList.add(rowData[j].text);
          var stringLength = tempList[j - 1].length;
          tempList[j - 1] = tempList[j - 1].substring(4, stringLength - 3);
          tempList[j - 1] = tempList[j - 1].replaceAll('\n', ' ');
          tempList[j - 1] = tempList[j - 1].replaceAll('\t', '');
          tempList[j - 1] = tempList[j - 1].trim();
        } else if (j == 4) {
          // if j is 4, parse it differently

          String tempText = rowData[j].text;
          var stringLength = tempText.length;
          tempText = tempText.substring(4, stringLength - 3);
          tempText = tempText.replaceAll('\n', ' ');
          tempText = tempText.replaceAll('\t', '');
          tempText = tempText.trim();

          // remove click here tags
          int clickHere = tempText.indexOf('- Click here');
          if (clickHere > 0) {
            int clickHereEnd = tempText.indexOf('-', clickHere + 2);
            tempText = tempText.substring(0, clickHere) +
                tempText.substring(clickHereEnd);
          }
          // TODO: get pdf scripts for discourse stream (click here tags)

          tempList.add(tempText);
        }
        // data of [3] will be
        // content
        // content might also contain "- NEW"? (not sure)
        else {
          // if j is 7, parse it differently

          String fids = '';
          if (rowData[j].getElementsByTagName('input').length != 0)
            fids =
                rowData[j].getElementsByTagName('input')[0].attributes['value'];

          tempList.add(fids);
        }
        // data of [6] will be fids
        // fids is empty if it is a live session
      }
      tableData.add(tempList);
    }
    // return data from table data
    // [0] Sl.No. [1] Category
    // [2] First Broad Cast [3] Programme Description
    // [4] Language [5] Duration(min)
    // [6] Download-fids

    if (tableData == null || tableData.isEmpty)
      tableData = [
        ['wrong']
      ];

    setState(() {
      // set the data
      _finalTableHead = tableHead;
      _finalTableData = tableData;

      // loading is done
      _isLoading = false;
    });
  }

  /// refresh the data
  Future<void> _refresh() async {
    await DefaultCacheManager().removeFile(finalUrl);
    setState(() {
      _isLoading = true;
      _updateURL();
    });
  }

  /// submits the form if it is valid.
  /// else, shows the error
  void _submit() {
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
        _isChangingPage = false;
        _isSecondLoading = false;
        _updateURL();
      });
    }
  }

  /// scroll listener to show/hide the form widget
  void _scrollListener() {
    int sensitivity = 8;
    if (_scrollController.offset > sensitivity ||
        _scrollController.offset < -sensitivity) {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!_isScrollingDown) {
          _isScrollingDown = true;
          _showDropDown = false;
          setState(() {});
        }
      }
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (_isScrollingDown) {
          _isScrollingDown = false;
          _showDropDown = true;
          setState(() {});
        }
      }
    }
  }

  /// widget to show and select the new search value
  Widget _searchForm(bool isDarkTheme) {
    return Form(
      key: _formKey,
      child: Container(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: TextFormField(
                    focusNode: _textFocusNode,
                    autofocus: false,
                    maxLines: 1,
                    expands: false,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      contentPadding: EdgeInsets.only(left: 20, right: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text to search';
                      }
                      description = value;
                      return null;
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Center(
                                  child: Text(
                                    'Category:',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: _categoryDropDown(isDarkTheme),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Center(
                                  child: Text(
                                    'Played on:',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: (selectedDateString != '') ? 110 : 140,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: TextField(
                                      autofocus: false,
                                      textAlign: TextAlign.center,
                                      controller: _dateController,
                                      decoration: InputDecoration(
                                        hintText: 'Select Date',
                                        hintStyle: TextStyle(
                                          fontSize: 18,
                                        ),
                                        suffixIcon: (selectedDateString == '')
                                            ? Icon(
                                                Icons.date_range_outlined,
                                                size: 20,
                                              )
                                            : null,
                                        contentPadding: EdgeInsets.all(0),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onTap: () {
                                        // Below lines stop keyboard from appearing
                                        FocusScope.of(context)
                                            .requestFocus(new FocusNode());

                                        // Show Date Picker
                                        _selectDate(context);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedDateString != '')
                                IconButton(
                                  icon: Icon(CupertinoIcons.clear_circled),
                                  splashRadius: 24,
                                  iconSize: 20,
                                  onPressed: _clearDate,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: ElevatedButton(
                      child: Icon(Icons.search_outlined),
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// widget - dropdown for selecting category
  Widget _categoryDropDown(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: category,
        items: categoriesList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down_circle_outlined),
        iconSize: 20,
        isDense: true,
        onChanged: (value) {
          if (value != category) {
            setState(() {
              category = value;
            });
          }
        },
      ),
    );
  }

  /// select the played on date
  Future<void> _selectDate(BuildContext context) async {
    if (selectedDate == null) selectedDate = now;
    final DateTime picked = await showDatePicker(
      context: context,
      // Schedule started on 8th Nov 2019
      firstDate: DateTime(2019, 11, 8),
      initialDate: selectedDate,
      // Schedule is available for 1 day after current date
      lastDate: now,
    );
    if (picked != null) {
      selectedDate = picked;
      selectedDateString = DateFormat('MMMM dd, yyyy').format(selectedDate);
      _dateController.text = selectedDateString;
    }
  }

  /// clear the selected date
  _clearDate() {
    setState(() {
      selectedDate = null;
      selectedDateString = '';
      _dateController.text = selectedDateString;
    });
  }

  /// widget - pagination
  ///
  /// shows the scroll of pages to navigate
  Widget _pagination() {
    if (lastPage <= 1) {
      return Container(
        height: 0,
        width: 0,
      );
    }

    // because we have 2 scroll bar's in the screen
    // and this scroll bar is always shown
    ScrollController scrollController = new ScrollController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.07,
      child: Material(
        color: Colors.transparent,
        child: Scrollbar(
          radius: Radius.circular(8),
          isAlwaysShown: true,
          controller: scrollController,
          child: ListView.builder(
            padding: EdgeInsets.all(0),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            itemCount: lastPage,
            itemBuilder: (context, index) {
              bool isSelectedPage = (currentPage == index + 1);
              return SizedBox(
                width: 50,
                child: Card(
                  elevation: 0,
                  color: isSelectedPage ? Theme.of(context).accentColor : null,
                  child: InkWell(
                    child: Center(
                      child: Text('${index + 1}'),
                    ),
                    onTap: () {
                      if (!isSelectedPage)
                        setState(() {
                          currentPage = index + 1;
                          _isChangingPage = true;
                          _isSecondLoading = true;
                          _isLoading = true;
                          _updateURL();
                        });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            // 3 shimmer context
            for (int i = 0; i < 3; i++) _shimmerContent(),
          ],
        ),
      ),
    );
  }

  /// individual shimmer content for loading shimmer
  Widget _shimmerContent() {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    width: width * 0.4,
                    height: 9,
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    width: width * 0.6,
                    height: 8,
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    width: width * 0.6,
                    height: 8,
                    color: Colors.white,
                  ),
                  Container(
                    width: width * 0.6,
                    height: 8,
                    color: Colors.white,
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    width: width * 0.2,
                    height: 8,
                    color: Colors.white,
                  ),
                  Container(
                    width: width * 0.2,
                    height: 8,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// widget - hidden web view.
  /// uses webview inside stack below loading screen
  ///
  /// while loading with [_isChangingPage] as false:
  ///
  /// first load: loads the page;
  /// second load: loads the table and gets data
  ///
  /// while loading with [_isChangingPage] as true:
  ///
  /// first load: loads the page;
  /// second load: loads the table;
  /// third load: changes the page and gets data
  Widget _hiddenWebView() {
    return Positioned.fill(
      child: WebView(
        initialUrl: baseUrl,
        gestureNavigationEnabled: true,
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (url) async {
          if (_isFirstLoading) {
            await _webViewController.evaluateJavascript(
                "document.forms[1].description_s.value=\"${globalFormData['description_s']}\";");
            await _webViewController.evaluateJavascript(
                "document.forms[1].filesperpage_s.value=${globalFormData['filesperpage_s']};");
            await _webViewController.evaluateJavascript(
                "document.forms[1].category_s.value=\"${globalFormData['category_s']}\";");
            // await _webViewController.evaluateJavascript(
            //     "document.forms[1].language_s.value=\"${globalFormData['language_s']}\";");
            await _webViewController.evaluateJavascript(
                "document.forms[1].pdate_s.value=\"${globalFormData['pdate_s']}\";");
            await _webViewController.evaluateJavascript(
                "document.forms[1].page.value=${globalFormData['page']};");
            await _webViewController.evaluateJavascript("javascript:check()");
            _isFirstLoading = false;
          } else if (_isSecondLoading) {
            await _webViewController.evaluateJavascript(
                'javascript:pager(${globalFormData['page']})');
            _isSecondLoading = false;
          } else {
            String tempResponse = await _webViewController.evaluateJavascript(
                "encodeURIComponent(document.documentElement.outerHTML)");
            tempResponse = Uri.decodeComponent(tempResponse);

            // put data into cache after getting from internet
            List<int> list = tempResponse.codeUnits;
            Uint8List fileBytes = Uint8List.fromList(list);
            DefaultCacheManager().putFile(finalUrl, fileBytes);
            setState(() {
              _isFirstLoading = true;
              _isSecondLoading = false;
              _isGettingData = false;
            });
            _parseData(tempResponse);
          }
        },
      ),
    );
  }
}
