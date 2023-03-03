import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/scaffold_helper.dart';
import 'package:radiosai/screens/media/media.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// If using [initialSearch], it is recommended to use [initialSearchTItle] also
class Search extends StatefulWidget {
  const Search({
    super.key,
    this.initialSearch,
    this.initialSearchTitle,
  });

  final String? initialSearch;
  final String? initialSearchTitle;

  @override
  State<Search> createState() => _Search();
}

class _Search extends State<Search> {
  /// webview controller for hidden web view
  late WebViewController _webViewController;

  /// variable to show the loading screen
  bool _isLoading = false;

  /// variable to show the hidden web view
  bool _isGettingData = false;

  /// form data to send to web view after updating url
  late Map<String, String?> globalFormData;

  /// contains the base url of the radio sai search page
  final String baseUrl =
      'https://schedule.sssmediacentre.org/program/SearchProgramme.php';

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
  String? category = 'Any'; // from categoriesList
  // String language = '';

  final DateTime now = DateTime.now();

  /// date for the search (played on)
  ///
  /// set this null to unselect date
  DateTime? selectedDate;

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

  // /// table head data retrieved from net
  // ///
  // /// doesn't use this as of now
  // ///
  // /// return data from tableHead
  // /// [0] Sl.No. [1] Category
  // /// [2] First Broad Cast [3] Programme Description
  // /// [4] Language [5] Duration(min)
  // /// [6] Download-fids
  // List<String> _finalTableHead = [];

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
  List<List<String?>> _finalTableData = [
    ['start']
  ];

  /// form key used to validate search key
  final _formKey = GlobalKey<FormState>();

  /// used to change the text in date field
  final TextEditingController _dateController = TextEditingController();

  // below are used to hide/show the form widget
  ScrollController? _scrollController;
  bool _showDropDown = true;
  bool _isScrollingDown = false;

  /// used to know if the web page is loading first time
  bool _isFirstLoading = true;

  /// used to know if the web page is loading second time
  bool _isSecondLoading = false;

  /// focus node attached to TextFormField of Search
  final FocusNode _textFocusNode = FocusNode();

  /// text controller to add text for initial value
  TextEditingController? _textController;
  bool _textControllerClear = false;

  @override
  void initState() {
    selectedDate = null;

    super.initState();

    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);

    if (Platform.isAndroid) WebView.platform = AndroidWebView();

    if (widget.initialSearch == null) {
      _textController = TextEditingController();
      // focus the search if the search field is empty
      _textFocusNode.requestFocus();
    } else {
      // initialize the search with the initialSearch
      _textController = TextEditingController(text: widget.initialSearch);
      // calls the submit method after the widget is build
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textController!.addListener(_textControllerListener);
    });
  }

  @override
  void dispose() {
    _scrollController!.removeListener(_scrollListener);
    _scrollController!.dispose();

    _textController!.removeListener(_textControllerListener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialSearch == null
            ? 'Search'
            : ((widget.initialSearchTitle != null)
                ? widget.initialSearchTitle!
                : widget.initialSearch!)),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            if (!isSmallerScreen)
              Padding(
                padding: EdgeInsets.only(top: _showDropDown ? 5 : 0),
                child: AnimatedContainer(
                  height: _showDropDown ? height * 0.2 : 0,
                  duration: _showDropDown
                      ? const Duration(milliseconds: 200)
                      : const Duration(milliseconds: 300),
                  child: _searchForm(),
                ),
              ),
            Expanded(
              child: AnimatedCrossFade(
                crossFadeState: _isLoading
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(seconds: 1),
                firstChild: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_finalTableData[0][0] != 'null' &&
                          _finalTableData[0][0] != 'timeout' &&
                          _finalTableData[0][0] != 'wrong' &&
                          _finalTableData[0][0] != 'start')
                        RefreshIndicator(
                          onRefresh: _refresh,
                          child: Scrollbar(
                            controller: _scrollController,
                            radius: const Radius.circular(8),
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        bottom: MediaQuery.of(context)
                                                .viewPadding
                                                .bottom +
                                            20 +
                                            ((lastPage > 1)
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.08
                                                : 0)),
                                    child: Card(
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                      elevation: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      child: _searchItems(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // show the below when wrong string is typed
                      if (_finalTableData[0][0] == 'wrong')
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child:
                                Text('No Data Available for the search values'),
                          ),
                        ),
                      // show the below when at start
                      if (_finalTableData[0][0] == 'start')
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Start by entering value in Search'),
                          ),
                        ),
                      // show when no data is retrieved
                      if (_finalTableData[0][0] == 'null')
                        NoData(
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
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
                      if (_finalTableData[0][0] == 'timeout')
                        NoData(
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
                          text:
                              'No Data Available,\nURL timeout, try again after some time',
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _updateURL();
                            });
                          },
                        ),
                      // Pagination when there are more than one page
                      _pagination(),
                    ],
                  ),
                ),
                // Shown second child it is loading
                secondChild: Stack(
                  children: [
                    // Shown but hidden when loading the data
                    if (_isGettingData) _hiddenWebView(),
                    Container(
                      color: Theme.of(context).colorScheme.background,
                      child: Center(
                        child: _showLoading(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  /// widget for search items (contains the list)
  ///
  /// showed after getting data
  Widget _searchItems() {
    return ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        itemCount: _finalTableData.length,
        itemBuilder: (context, index) {
          List<String?> rowData = _finalTableData[index];

          String category = rowData[1]!;
          String programe = rowData[3]!;
          String language = rowData[4]!;
          String duration = '${rowData[5]} min';
          String? fids = rowData[6];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () {
                      if (fids != '') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Media(fids: fids)));
                      } else {
                        getIt<ScaffoldHelper>().showSnackBar(
                            'No media found!', const Duration(seconds: 1));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Center(
                        child: ListTile(
                          title: Text(
                            category,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(programe),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                language,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              Text(
                                duration,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (index != _finalTableData.length - 1)
                const Divider(
                  height: 2,
                  thickness: 1.5,
                ),
            ],
          );
        });
  }

  /// sets the [finalUrl]
  ///
  /// continues the process by retrieving the data
  _updateURL() async {
    String formattedDate;
    if (selectedDate == null) {
      formattedDate = '';
    } else {
      formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate!);
    }

    String? categoryPass = category;
    if (categoryPass == 'Any') {
      categoryPass = '';
    }

    var data = <String, String?>{};
    data['form'] = 'search';
    data['description_s'] = description;
    data['filesperpage_s'] = '$filesPerPage';
    data['category_s'] = categoryPass;
    // data['language_s'] = language;
    data['pdate_s'] = formattedDate;
    data['page'] = '$currentPage';

    // unique url for putting data into cache and getting it
    String url = '$baseUrl?form=${data['form']}'
        '&filesperpage_s=${data['filesperpage_s']}'
        '&description_s=${data['description_s']}'
        '&category_s=${data['category_s']}'
        // '&language_s=${data['language_s']}'
        '&pdate_s=${data['pdate_s']}'
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
  _getData(Map<String, String?> formData) async {
    String tempResponse = '';
    // checks if the file exists in cache
    FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
    if (fileInfo == null) {
      bool hasInternet =
          Provider.of<InternetConnectionStatus>(context, listen: false) ==
              InternetConnectionStatus.connected;
      // search works only if there is an internet
      if (hasInternet) {
        // get the data into cache from webview_flutter
        setState(() {
          globalFormData = formData;
          _isGettingData = true;
        });
      } else {
        setState(() {
          // show that no internet is there
          _finalTableData[0][0] = 'null';
          _isLoading = false;
        });
      }
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
      if (paging.isNotEmpty) {
        var pages = paging[0].getElementsByTagName('a');

        lastPage = (pages.isEmpty) ? 1 : pages.length;
        // set changing page to true.
        // assumes that user can change page
        // after data is loaded
        _isChangingPage = true;
      }
    }

    var table = document.getElementById('sea')!;
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
    List<List<String?>> tableData = [];
    int dataLength = table.getElementsByTagName('tr').length;
    if (dataLength == 0) {
      tableData = [
        ['null']
      ];
      setState(() {
        // set the data
        // _finalTableHead = tableHead;
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
        // _finalTableHead = tableHead;
        _finalTableData = tableData;

        // loading is done
        _isLoading = false;
      });
      return;
    }
    for (int i = 1; i < dataLength; i++) {
      List<String?> tempList = [];
      var rowData =
          table.getElementsByTagName('tr')[i].getElementsByTagName('td');
      // do not add if there are any suggestions
      if (rowData.length == 1) continue;

      for (int j = 1; j < 8; j++) {
        if (j != 4 && j != 7) {
          tempList.add(rowData[j].text);
          var stringLength = tempList[j - 1]!.length;
          tempList[j - 1] = tempList[j - 1]!.substring(4, stringLength - 3);
          tempList[j - 1] = tempList[j - 1]!.replaceAll('\n', ' ');
          tempList[j - 1] = tempList[j - 1]!.replaceAll('\t', '');
          tempList[j - 1] = tempList[j - 1]!.trim();
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
            if (clickHereEnd > 0) {
              tempText = tempText.substring(0, clickHere) +
                  tempText.substring(clickHereEnd);
            }
          }
          // TODO: get pdf scripts for discourse stream (click here tags)

          tempList.add(tempText);
        }
        // data of [3] will be
        // content
        // content might also contain "- NEW"? (not sure)
        else {
          // if j is 7, parse it differently

          String? fids = '';
          if (rowData[j].getElementsByTagName('input').isNotEmpty) {
            fids =
                rowData[j].getElementsByTagName('input')[0].attributes['value'];
          }
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

    if (tableData.isEmpty) {
      tableData = [
        ['wrong']
      ];
    }

    setState(() {
      // set the data
      // _finalTableHead = tableHead;
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

  /// listener for text controller.
  /// used to add or remove clear button in search text field
  void _textControllerListener() {
    setState(() {
      _textControllerClear = _textController!.text != '';
    });
  }

  /// submits the form if it is valid.
  /// else, shows the error
  ///
  /// if valid, loads and shows the data
  void _submit() {
    if (_formKey.currentState!.validate()) {
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
    if (_scrollController!.offset > sensitivity ||
        _scrollController!.offset < -sensitivity) {
      if (_scrollController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!_isScrollingDown) {
          _isScrollingDown = true;
          _showDropDown = false;
          setState(() {});
        }
      }
      if (_scrollController!.position.userScrollDirection ==
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
  Widget _searchForm() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            AnimatedContainer(
              height: _showDropDown ? height * 0.09 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: TextFormField(
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (value) {
                      _submit();
                    },
                    focusNode: _textFocusNode,
                    autofocus: false,
                    maxLines: 1,
                    expands: false,
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Search \'Manasa Bhajare\'',
                      contentPadding:
                          const EdgeInsets.only(left: 20, right: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      suffixIcon: (_textControllerClear)
                          ? IconButton(
                              onPressed: _textController!.clear,
                              icon: const Icon(Icons.clear_outlined),
                              splashRadius: 24,
                            )
                          : null,
                    ),
                    validator: (value) {
                      final validCharacters = RegExp(r'^[a-zA-Z0-9 ]+$');
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text to search';
                      } else if (!validCharacters.hasMatch(value)) {
                        return 'Only Alphanumeric/Spaces allowed';
                      }
                      description = value;
                      return null;
                    },
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              height: _showDropDown ? height * 0.11 : 0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            height: _showDropDown ? height * 0.05 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: _categoryDropDown(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            height: _showDropDown ? height * 0.05 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
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
                                    width: (selectedDateString != '')
                                        ? width * 0.3
                                        : width * 0.4,
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
                                            hintStyle: const TextStyle(
                                              fontSize: 18,
                                            ),
                                            suffixIcon:
                                                (selectedDateString == '')
                                                    ? Icon(
                                                        (Platform.isAndroid)
                                                            ? Icons
                                                                .date_range_outlined
                                                            : CupertinoIcons
                                                                .calendar,
                                                        size: 20,
                                                      )
                                                    : null,
                                            contentPadding:
                                                const EdgeInsets.all(0),
                                            border: const OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onTap: () {
                                            // Below lines stop keyboard from appearing
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());

                                            // Show Date Picker
                                            (Platform.isAndroid)
                                                ? _selectDate(context)
                                                : _selectDateIOS(context);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selectedDateString != '')
                                    IconButton(
                                      icon: const Icon(
                                          CupertinoIcons.clear_circled),
                                      splashRadius: 24,
                                      iconSize: 20,
                                      onPressed: _clearDate,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Icon((Platform.isAndroid)
                          ? Icons.search_outlined
                          : CupertinoIcons.search),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// widget - dropdown for selecting category
  Widget _categoryDropDown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: category,
        items: categoriesList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: (value == category)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }).toList(),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
        iconSize: 20,
        isDense: true,
        onChanged: (value) {
          if (value != category) {
            setState(() {
              category = value;

              // if the category is changed and text is present, then search
              if (_textControllerClear) _submit();
            });
          }
        },
      ),
    );
  }

  /// select the played on date
  Future<void> _selectDate(BuildContext context) async {
    selectedDate ??= now;
    final DateTime? picked = await showDatePicker(
      context: context,
      // Schedule started on 8th Nov 2019
      firstDate: DateTime(2019, 11, 8),
      initialDate: selectedDate!,
      // Schedule is available for 1 day after current date
      lastDate: now,
    );
    if (picked != null) {
      selectedDate = picked;
      selectedDateString = DateFormat('MMM dd, yyyy').format(selectedDate!);
      _dateController.text = selectedDateString;

      setState(() {
        // if the category is changed and text is present, then search
        if (_textControllerClear) _submit();
      });
    }
  }

  /// select the played on date for iOS
  void _selectDateIOS(BuildContext context) {
    DateTime? picked;
    if (selectedDate == null) {
      picked = now;
    }
    showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
              color: Theme.of(context).colorScheme.background,
              height: 200,
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime:
                          (selectedDate == null) ? now : selectedDate,
                      // Schedule started on 8th Nov 2019
                      minimumDate: DateTime(2019, 11, 8),
                      // Schedule is available for 1 day after current date
                      maximumDate: now,
                      onDateTimeChanged: (picked) {
                        picked = picked;
                      },
                    ),
                  ),
                  SizedBox(
                    height: 70,
                    child: CupertinoButton(
                      child: const Text('OK'),
                      onPressed: () {
                        if (picked != null) {
                          selectedDate = picked;
                          selectedDateString =
                              DateFormat('MMM dd, yyyy').format(selectedDate!);
                          _dateController.text = selectedDateString;

                          setState(() {
                            // if the category is changed and text is present, then search
                            if (_textControllerClear) _submit();
                          });
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ],
              ),
            ));
  }

  /// clear the selected date
  _clearDate() {
    setState(() {
      selectedDate = null;
      selectedDateString = '';
      _dateController.text = selectedDateString;
    });
    // show the data after clearing the filter
    _submit();
  }

  /// widget - pagination
  ///
  /// shows the scroll of pages to navigate
  Widget _pagination() {
    if (lastPage <= 1) {
      return const SizedBox(
        height: 0,
        width: 0,
      );
    }

    // because we have 2 scroll bar's in the screen
    // and this scroll bar is always shown
    ScrollController scrollController = ScrollController();

    // check if it needs a bottom padding for bottom notch
    bool hasBottomNotch = MediaQuery.of(context).viewPadding.bottom > 0;

    return Positioned(
      bottom: hasBottomNotch ? 30 : 20,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.07,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: 50,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.background,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: Scrollbar(
            radius: const Radius.circular(8),
            thumbVisibility: true,
            controller: scrollController,
            child: ListView.builder(
              padding:
                  const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              itemCount: lastPage,
              itemBuilder: (context, index) {
                bool isSelectedPage = (currentPage == index + 1);
                return Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 50,
                    child: Card(
                      elevation: 0,
                      color: isSelectedPage
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: InkWell(
                        child: Center(
                          child: Text('${index + 1}'),
                        ),
                        onTap: () {
                          if (!isSelectedPage) {
                            setState(() {
                              currentPage = index + 1;
                              _isChangingPage = true;
                              _isSecondLoading = true;
                              _isLoading = true;
                              _updateURL();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer effect while loading the content
  Widget _showLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.secondaryContainer,
        highlightColor: Theme.of(context).colorScheme.onSecondaryContainer,
        enabled: true,
        child: Column(
          children: [
            // 3 shimmer context
            for (int i = 0; i < 2; i++) _shimmerContent(),
          ],
        ),
      ),
    );
  }

  /// individual shimmer content for loading shimmer
  Widget _shimmerContent() {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
                    margin: const EdgeInsets.only(bottom: 8),
                    width: width * 0.4,
                    height: 9,
                    color: Colors.white,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: width * 0.6,
                    height: 8,
                    color: Colors.white,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                    margin: const EdgeInsets.only(bottom: 10),
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
            await _webViewController.runJavascript(
                "document.forms[1].description_s.value=\"${globalFormData['description_s']}\";");
            await _webViewController.runJavascript(
                "document.forms[1].filesperpage_s.value=${globalFormData['filesperpage_s']};");
            await _webViewController.runJavascript(
                "document.forms[1].category_s.value=\"${globalFormData['category_s']}\";");
            // await _webViewController.runJavascript(
            //     "document.forms[1].language_s.value=\"${globalFormData['language_s']}\";");
            await _webViewController.runJavascript(
                "document.forms[1].pdate_s.value=\"${globalFormData['pdate_s']}\";");
            await _webViewController.runJavascript(
                "document.forms[1].page.value=${globalFormData['page']};");
            await _webViewController.runJavascript('javascript:check()');
            _isFirstLoading = false;
          } else if (_isSecondLoading) {
            await _webViewController
                .runJavascript('javascript:pager(${globalFormData['page']})');
            _isSecondLoading = false;
          } else {
            String tempResponse =
                await _webViewController.runJavascriptReturningResult(
                    'encodeURIComponent(document.documentElement.outerHTML)');
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
