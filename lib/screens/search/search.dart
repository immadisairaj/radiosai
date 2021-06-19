import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:radiosai/screens/media/media.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Search extends StatefulWidget {
  Search({
    Key key,
  }) : super(key: key);

  @override
  _Search createState() => _Search();
}

class _Search extends State<Search> {
  WebViewController _webViewController;
  bool _isLoading = false;
  bool _isGettingData = false;
  Map<String, String> globalFormData;

  final String baseUrl = 'https://radiosai.org/program/SearchProgramme.php';

  String finalUrl = '';

  final List<String> categoriesList = const [
    'Any',
    'Bhajan',
    'Concert',
    'Discourse',
    'Instrumental',
    'Song',
    'Special',
  ];
  String description = '';
  String category = ''; // from categoriesList
  final DateTime now = DateTime.now();
  DateTime selectedDate;
  int page = 1;
  final int filesPerPage = 100; // max 3 digits
  int lastPage;

  List<String> _finalTableHead = [];
  List<List<String>> _finalTableData = [
    ['null']
  ];

  bool _isFirstLoading = true;

  @override
  void initState() {
    selectedDate = null;

    // TODO: below are just temporary
    description = 'sri ram jai ram';
    category = 'Any';
    _isLoading = true;
    _isFirstLoading = true;

    super.initState();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    _updateURL();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        // child: Expanded(
        child: Stack(
          children: [
            if (_isLoading == false || _finalTableData[0][0] != 'null')
              RefreshIndicator(
                onRefresh: () {
                  return;
                },
                // onRefresh: _refresh,
                child: Scrollbar(
                  radius: Radius.circular(8),
                  child: SingleChildScrollView(
                    // controller: _scrollController,
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    child: Card(
                      elevation: 0,
                      color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                      child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          padding: EdgeInsets.only(top: 2, bottom: 2),
                          itemCount: _finalTableData.length,
                          itemBuilder: (context, index) {
                            List<String> rowData = _finalTableData[index];

                            String category = rowData[1];
                            String programe = rowData[3];
                            String language = rowData[4];
                            String duration = '${rowData[5]} min';
                            String fids = rowData[6];
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 2, right: 2),
                                  child: Card(
                                    elevation: 0,
                                    color: isDarkTheme
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: InkWell(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(top: 2, bottom: 2),
                                        child: Center(
                                          child: ListTile(
                                            title: Text(
                                              category,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .accentColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(programe),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  language,
                                                  style: TextStyle(
                                                    color: isDarkTheme
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  duration,
                                                  style: TextStyle(
                                                    color: isDarkTheme
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      focusColor: isDarkTheme
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      onTap: () {
                                        if (fids != '')
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Media(fids: fids)));
                                      },
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
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
            // show when no data is retrieved
            if (_finalTableData[0][0] == 'null' && _isLoading == false)
              NoData(
                backgroundColor: backgroundColor,
                text: 'No Data Available,\ncheck your internet and try again',
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
            if (_isGettingData)
              Positioned.fill(
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
                      await _webViewController.evaluateJavascript(
                          "document.forms[1].pdate_s.value=\"${globalFormData['pdate_s']}\";");
                      await _webViewController.evaluateJavascript(
                          "document.forms[1].page.value=${globalFormData['page']};");
                      await _webViewController
                          .evaluateJavascript("javascript:check()");
                      _isFirstLoading = false;
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
                        _isGettingData = false;
                      });
                      _parseData(tempResponse);
                    }
                  },
                ),
              ),
            // Shown when it is loading
            if (_isLoading)
              Container(
                color: backgroundColor,
                child: Center(
                  // TODO: show loading
                  // child: _showLoading(isDarkTheme),
                  child: SingleChildScrollView(
                    child: Text('loading'),
                  ),
                ),
              ),
          ],
        ),
        // ),
      ),
    );
  }

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
    data['pdate_s'] = formattedDate;
    data['page'] = '$page';

    // unique url for putting data into cache and getting it
    String url = '$baseUrl?form=${data['form']}' +
        '&filesperpage_s=${data['filesperpage_s']}' +
        '&description_s=${data['description_s']}' +
        '&category_s=${data['category_s']}' +
        '&pdate_s=${data['pdate_s']}' +
        '&page=${data['page']}';
    finalUrl = url;
    _getData(data);
  }

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

  _parseData(String response) {
    var document = parse(response);
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
    } else if (dataLength == 1 &&
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

    if (tableData == [])
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
  }

  Future<void> waitTillGettingData() async {
    while (_isGettingData);
    return;
  }
}
