import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:radiosai/bloc/radio_schedule/time_zone_bloc.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/media/media.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';

class ScheduleData extends StatefulWidget {
  const ScheduleData({
    Key key,
    this.radioStreamIndex,
    this.timeZone,
    this.timeZoneBloc,
  }) : super(key: key);

  final int radioStreamIndex;
  final String timeZone;
  final TimeZoneBloc timeZoneBloc;

  @override
  _ScheduleData createState() => _ScheduleData();
}

class _ScheduleData extends State<ScheduleData> {
  /// variable to show the loading screen
  bool _isLoading = true;

  final DateTime now = DateTime.now();

  /// date for the radio sai schedule
  DateTime selectedDate;

  // below are used to hide/show the selection widget
  ScrollController _scrollController;
  bool _showDropDown = true;
  bool _isScrollingDown = false;

  // used for the initial build
  int oldStreamId = 0;
  final List<int> firstStreamMap = [1, 3, 2, 1, 6, 5];

  /// contains the base url of the radio sai schedule page
  final String baseUrl = 'https://radiosai.org/program/Index.php';

  /// the url with all the parameters (a unique url)
  String finalUrl = '';

  /// radio stream id
  ///
  /// associated with [selectedStream]
  String streamId = '';

  /// selected radio stream
  ///
  /// associated with [streamId]
  String selectedStream = '';

  /// selected time zone id
  String zoneId = '';

  /// table head data retrieved from net
  ///
  /// doesn't use this as of now
  ///
  /// return data from tableHead
  /// [0] Sl. No. [1] Loacl Time [2] GMT Time
  /// [3] Programe List [4] Duration(min)
  List<String> _finalTableHead = [];

  /// final table body data retrieved from the net
  ///
  /// can be [['null']] or [['timeout']] or data.
  /// Each have their own display widgets
  ///
  /// return data from table body
  /// [0] Sl. No. [1] Loacl Time [2] GMT Time
  /// [3] Programe List [4] Duration(min)
  ///
  /// data of [3] will be:
  /// category\<split\>content\<split\>[fids] ;
  /// fids is empty if it is a live session;
  /// content might also contain "- NEW"
  List<List<String>> _finalTableData = [
    ['null']
  ];

  /// local time for the selected timezone
  String _finalLocalTime = '';

  @override
  void initState() {
    _isLoading = true;
    selectedDate = now;
    selectedStream = 'Asia Stream';
    oldStreamId = widget.radioStreamIndex;

    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
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

    Color backgroundColor = Theme.of(context).backgroundColor;

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    // handle the screen for the initial build
    _handleFirstBuild();

    // handle stream name display
    _handleStreamName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor:
            MaterialStateColor.resolveWith((Set<MaterialState> states) {
          return states.contains(MaterialState.scrolledUnder)
              ? ((isDarkTheme)
                  ? Colors.grey[700]
                  : Theme.of(context).colorScheme.secondary)
              : Theme.of(context).primaryColor;
        }),
        actions: <Widget>[
          IconButton(
            icon: Icon((Platform.isAndroid)
                ? Icons.date_range_outlined
                : CupertinoIcons.calendar),
            tooltip: 'Select date',
            splashRadius: 24,
            onPressed: () => (Platform.isAndroid)
                ? _selectDate(context)
                : _selectDateIOS(context),
          )
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        child: Column(
          children: [
            if (!isSmallerScreen)
              AnimatedContainer(
                height: _showDropDown ? height * 0.19 : 0,
                duration: _showDropDown
                    ? const Duration(microseconds: 200)
                    : const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        height: _showDropDown ? height * 0.045 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Date: ${DateFormat('MMMM dd, yyyy').format(selectedDate)}',
                            style: TextStyle(
                              fontSize: 19,
                              color: Theme.of(context).secondaryHeaderColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        height: _showDropDown ? height * 0.035 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: const [
                              Flexible(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    'Select Zone',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    'Select Stream',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        height: _showDropDown ? height * 0.08 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          children: [
                            Flexible(
                              child: Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: _timeZoneDropDown(isDarkTheme),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: _streamDropDown(isDarkTheme),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  if (_isLoading == false &&
                      _finalTableData[0][0] != 'null' &&
                      _finalTableData[0][0] != 'timeout')
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: Scrollbar(
                        radius: const Radius.circular(8),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          child: ConstrainedBox(
                            // have minimum height to reload even when 1 item is present
                            constraints: BoxConstraints(
                                minHeight: (isSmallerScreen || !_showDropDown)
                                    ? MediaQuery.of(context).size.height * 0.9
                                    : MediaQuery.of(context).size.height *
                                        0.75),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(18)),
                                ),
                                elevation: 1,
                                color: isDarkTheme
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    primary: false,
                                    padding: const EdgeInsets.only(
                                        top: 2, bottom: 2),
                                    itemCount: _finalTableData.length,
                                    itemBuilder: (context, index) {
                                      List<String> rowData =
                                          _finalTableData[index];
                                      String localTime =
                                          '${rowData[1]} $_finalLocalTime';
                                      String gmtTime = '${rowData[2]} GMT';
                                      String duration = '${rowData[4]} min';
                                      List<String> mainRowData =
                                          rowData[3].split('<split>');
                                      String category = mainRowData[0];
                                      String programe = mainRowData[1];
                                      String fids = mainRowData[2].substring(
                                          1, mainRowData[2].length - 1);
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4, right: 4),
                                            child: Card(
                                              elevation: 0,
                                              color: isDarkTheme
                                                  ? Colors.grey[800]
                                                  : Colors.grey[200],
                                              child: InkWell(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4, bottom: 4),
                                                  child: Center(
                                                    child: ListTile(
                                                      title: Text(
                                                        category,
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .secondaryHeaderColor,
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
                                                            localTime,
                                                            style: TextStyle(
                                                              color: isDarkTheme
                                                                  ? Colors
                                                                      .grey[300]
                                                                  : Colors.grey[
                                                                      700],
                                                            ),
                                                          ),
                                                          Text(
                                                            duration,
                                                            style: TextStyle(
                                                              color: isDarkTheme
                                                                  ? Colors
                                                                      .grey[300]
                                                                  : Colors.grey[
                                                                      700],
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
                                                  if (fids != '') {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                Media(
                                                                    fids:
                                                                        fids)));
                                                  } else {
                                                    _showSnackBar(
                                                        context,
                                                        'No media found!',
                                                        const Duration(
                                                            seconds: 1));
                                                  }
                                                },
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                          if (index !=
                                              _finalTableData.length - 1)
                                            const Divider(
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
                    ),
                  // show when no data is retrieved
                  if (_finalTableData[0][0] == 'null' && _isLoading == false)
                    NoData(
                      backgroundColor: backgroundColor,
                      text:
                          'No Data Available,\ncheck your internet or try again',
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _updateURL(selectedDate);
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
                          _updateURL(selectedDate);
                        });
                      },
                    ),
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
          ],
        ),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  /// sets the [finalUrl]
  ///
  /// takes in [date] as input
  ///
  /// continues the process by retrieving the data
  _updateURL(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    var data = <String, dynamic>{};
    data['streamId'] = streamId;
    data['zoneId'] = zoneId;
    data['currentDate'] = formattedDate;
    data['dchange'] = '1';

    // unique url for putting data into cache and getting it
    String url =
        '$baseUrl?streamId=${data['streamId']}&zoneId=${data['zoneId']}&currentDate=${data['currentDate']}';
    finalUrl = url;
    _getData(data);
  }

  /// retrieve the data from finalUrl
  ///
  /// continues the process by sending it to parse
  /// if the data is retrieved
  _getData(Map<String, dynamic> formData) async {
    String tempResponse = '';
    // checks if the file exists in cache
    var fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
    if (fileInfo == null) {
      // get data from online if not present in cache
      http.Response response;
      try {
        response = await http
            .post(Uri.parse(baseUrl), body: formData)
            .timeout(const Duration(seconds: 40));
      } on SocketException catch (_) {
        setState(() {
          // if there is no internet
          _finalTableData = [
            ['null']
          ];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      } on TimeoutException catch (_) {
        setState(() {
          // if timeout
          _finalTableData = [
            ['timeout']
          ];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      }
      tempResponse = response.body;

      // put data into cache after getting from internet
      List<int> list = tempResponse.codeUnits;
      Uint8List fileBytes = Uint8List.fromList(list);
      DefaultCacheManager().putFile(finalUrl, fileBytes);
    } else {
      // get data from file if present in cache
      tempResponse = fileInfo.file.readAsStringSync();
    }
    _parseData(tempResponse);
  }

  /// parses the data retrieved from url.
  /// sets the final data to display
  _parseData(String response) {
    var document = parse(response);
    var table = document.getElementById('sch');
    // parsing table heads
    List<String> tableHead = [];
    for (int i = 1; i < 6; i++) {
      tableHead.add(table.getElementsByTagName('th')[i].text);
      var stringLength = tableHead[i - 1].length;
      tableHead[i - 1] = tableHead[i - 1].substring(4, stringLength - 3);
      tableHead[i - 1] = tableHead[i - 1].replaceAll('\n', ' ');
      tableHead[i - 1] = tableHead[i - 1].replaceAll('\t', '');
      tableHead[i - 1] = tableHead[i - 1].trim();
    }
    // return data from tableHead
    // [0] Sl. No. [1] Loacl Time [2] GMT Time
    // [3] Programe List [4] Duration(min)

    // getting the local time
    String localTime = tableHead[1].substring(4);
    localTime = localTime.replaceAll('(', '');
    localTime = localTime.replaceAll(')', '');
    localTime = localTime.trim();

    // parsing table data
    List<List<String>> tableData = [];
    int dataLength = table.getElementsByTagName('tr').length - 1;
    if (dataLength == 0) {
      tableData = [
        ['null']
      ];
      setState(() {
        // set the data
        _finalTableHead = tableHead;
        _finalTableData = tableData;
        _finalLocalTime = localTime;

        // loading is done
        _isLoading = false;
      });
      return;
    }
    for (int i = 1; i <= dataLength; i++) {
      List<String> tempList = [];
      var rowData =
          table.getElementsByTagName('tr')[i].getElementsByTagName('td');
      for (int j = 1; j < 6; j++) {
        if (j != 4) {
          tempList.add(rowData[j].text);
          var stringLength = tempList[j - 1].length;
          tempList[j - 1] = tempList[j - 1].substring(4, stringLength - 3);
          tempList[j - 1] = tempList[j - 1].replaceAll('\n', ' ');
          tempList[j - 1] = tempList[j - 1].replaceAll('\t', '');
          tempList[j - 1] = tempList[j - 1].trim();
        } else {
          // if j is 4, parse it differently

          String tempText = rowData[j].text;
          var stringLength = tempText.length;
          tempText = tempText.substring(4, stringLength - 3);
          tempText = tempText.replaceAll('\n', ' ');
          tempText = tempText.replaceAll('\t', '');
          tempText = tempText.trim();
          tempText = tempText.replaceFirst(' ', '<split>');

          // remove click here tags
          int clickHere = tempText.indexOf('- Click here');
          if (clickHere > 0) {
            int clickHereEnd = tempText.indexOf('-', clickHere + 2);
            tempText = tempText.substring(0, clickHere) +
                tempText.substring(clickHereEnd);
          }
          // TODO: get pdf scripts for discourse stream (click here tags)

          String fids = '';
          if (rowData[j].getElementsByTagName('input').isNotEmpty) {
            fids =
                rowData[j].getElementsByTagName('input')[0].attributes['value'];
          }
          tempText += '<split>[$fids]';

          tempList.add(tempText);
        }
        // data of [3] will be
        // type<split>content<split>[fids]
        // fids is empty if it is a live session
        // content might also contain "- NEW"
      }
      tableData.add(tempList);
    }
    // return data from table data
    // [0] Sl. No. [1] Loacl Time [2] GMT Time
    // [3] Programe List [4] Duration(min)

    if (tableData == null || tableData.isEmpty) {
      tableData = [
        ['null']
      ];
    }

    setState(() {
      // set the data
      _finalTableHead = tableHead;
      _finalTableData = tableData;
      _finalLocalTime = localTime;

      // loading is done
      _isLoading = false;
    });
  }

  /// select the date and update the url
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      // Schedule started on 8th Nov 2019
      firstDate: DateTime(2019, 11, 8),
      initialDate: selectedDate,
      // Schedule is available for 1 day after current date
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _isLoading = true;
        selectedDate = picked;
        _updateURL(selectedDate);
      });
    }
  }

  /// select the date and update the url for iOS
  void _selectDateIOS(BuildContext context) {
    DateTime _picked;
    showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
              color: Theme.of(context).backgroundColor,
              height: 170,
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: selectedDate,
                      // Schedule started on 8th Nov 2019
                      minimumDate: DateTime(2019, 11, 8),
                      // Schedule is available for 1 day after current date
                      maximumDate: now.add(const Duration(days: 1)),
                      onDateTimeChanged: (picked) {
                        _picked = picked;
                      },
                    ),
                  ),
                  SizedBox(
                    height: 70,
                    child: CupertinoButton(
                      child: const Text('OK'),
                      onPressed: () {
                        if (_picked != null && _picked != selectedDate) {
                          setState(() {
                            _isLoading = true;
                            selectedDate = _picked;
                            _updateURL(selectedDate);
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

  /// refresh the data
  Future<void> _refresh() async {
    await DefaultCacheManager().removeFile(finalUrl);
    setState(() {
      _isLoading = true;
      _updateURL(selectedDate);
    });
  }

  /// handle the initial build data display
  ///
  /// used for getting the radio stream which is being
  /// selected in radio player
  void _handleFirstBuild() {
    if (widget.radioStreamIndex == oldStreamId) {
      return;
    }
    oldStreamId = widget.radioStreamIndex;
    streamId = '${firstStreamMap[widget.radioStreamIndex]}';
    zoneId = '${MyConstants.of(context).timeZones[widget.timeZone]}';
    _updateURL(selectedDate);
  }

  /// handle stream name to show in dropdown
  void _handleStreamName() {
    if (streamId == '') return;
    int index = firstStreamMap.indexOf(int.parse(streamId));
    selectedStream = MyConstants.of(context).radioStream.keys.toList()[index];
  }

  /// scroll listener to show/hide the selecting widget
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

  /// widget - dropdown for selecting radio stream
  Widget _streamDropDown(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedStream,
        items: MyConstants.of(context).scheduleStream.keys.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
        iconSize: 20,
        isExpanded: true,
        onChanged: (value) {
          if (value != selectedStream) {
            setState(() {
              _isLoading = true;
              streamId = '${MyConstants.of(context).scheduleStream[value]}';
              _updateURL(selectedDate);
            });
          }
        },
      ),
    );
  }

  /// widget - dropdown for selecting time zone
  ///
  /// updates the data in shared prefs
  Widget _timeZoneDropDown(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: widget.timeZone,
        items: MyConstants.of(context).timeZones.keys.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
        iconSize: 20,
        isExpanded: true,
        onChanged: (value) {
          if (value != widget.timeZone) {
            setState(() {
              _isLoading = true;
              widget.timeZoneBloc.changeTimeZone.add(value);
              zoneId = '${MyConstants.of(context).timeZones[value]}';
              _updateURL(selectedDate);
            });
          }
        },
      ),
    );
  }

  /// show snack bar for the current context
  ///
  /// pass current [context],
  /// [text] to display and
  /// [duration] for how much time to display
  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  /// Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            // 5 shimmer context
            for (int i = 0; i < 5; i++) _shimmerContent(),
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
}
