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
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';

class ScheduleData extends StatefulWidget {
  ScheduleData({
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
  bool _isLoading = true;

  final DateTime now = DateTime.now();
  DateTime selectedDate;

  ScrollController _scrollController;
  bool _showDropDown = true;
  bool _isScrollingDown = false;

  // used for the first build
  int oldStreamId = 0;
  final List<int> firstStreamMap = [1, 3, 2, 1, 6, 5];

  String baseUrl = 'https://radiosai.org/program/Index.php';
  String finalUrl = '';
  String streamId = '';
  String selectedStream = '';
  String zoneId = '';

  List<String> _finalTableHead = [];
  List<List<String>> _finalTableData = [
    ['null']
  ];
  String _finalLocalTime = '';

  @override
  void initState() {
    _isLoading = true;
    selectedDate = now;
    selectedStream = 'Asia Stream';
    oldStreamId = widget.radioStreamIndex;
    super.initState();
    _scrollController = new ScrollController();
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

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    _handleFirstBuild();

    _handleStreamName();

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.date_range_outlined),
            tooltip: 'Select date',
            splashRadius: 24,
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        child: Column(
          children: [
            AnimatedContainer(
              height: _showDropDown ? null : 0,
              duration: Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Date: ${DateFormat('MMMM dd, yyyy').format(selectedDate)}',
                        style: TextStyle(
                          fontSize: 19,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
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
                    Row(
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_isLoading == false || _finalTableData[0][0] != 'null')
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            padding: EdgeInsets.only(bottom: 10),
                            itemCount: _finalTableData.length,
                            itemBuilder: (context, index) {
                              List<String> rowData = _finalTableData[index];
                              String localTime =
                                  '${rowData[1]} $_finalLocalTime';
                              String gmtTime = '${rowData[2]} GMT';
                              String duration = '${rowData[4]} min';
                              List<String> mainRowData =
                                  rowData[3].split('<split>');
                              String tag = mainRowData[0];
                              String programe = mainRowData[1];
                              String fids = mainRowData[2]
                                  .substring(1, mainRowData[2].length - 1);
                              return Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Card(
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
                                            tag,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context).accentColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(programe),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                localTime,
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
                                    onTap: () {},
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              );
                            }),
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
    );
  }

  _updateURL(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    var data = new Map<String, dynamic>();
    data['streamId'] = streamId;
    data['zoneId'] = zoneId;
    data['currentDate'] = formattedDate;
    data['dchange'] = '1';

    // unique url for putting data into cache and getting it
    String url = '$baseUrl?streamId=${data['streamId']}' +
        '&zoneId=${data['zoneId']}' +
        '&currentDate=${data['currentDate']}';
    finalUrl = url;
    _getData(data);
  }

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
          if (rowData[j].getElementsByTagName('input').length != 0)
            fids =
                rowData[j].getElementsByTagName('input')[0].attributes['value'];
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

    if (tableData == [])
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
  }

  // select the date and update the url
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      // Schedule started on 8th Nov 2019
      firstDate: DateTime(2019, 11, 8),
      initialDate: selectedDate,
      // Schedule is available for 1 day after current date
      lastDate: now.add(Duration(days: 1)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _isLoading = true;
        selectedDate = picked;
        _updateURL(selectedDate);
      });
    }
  }

  // for refreshing the data
  Future<void> _refresh() async {
    await DefaultCacheManager().removeFile(finalUrl);
    setState(() {
      _isLoading = true;
      _updateURL(selectedDate);
    });
  }

  // handle the first build data
  void _handleFirstBuild() {
    if (widget.radioStreamIndex == oldStreamId) {
      return;
    }
    oldStreamId = widget.radioStreamIndex;
    streamId = '${firstStreamMap[widget.radioStreamIndex]}';
    zoneId = '${MyConstants.of(context).timeZones[widget.timeZone]}';
    _updateURL(selectedDate);
  }

  // handle stream name to show in dropdown
  void _handleStreamName() {
    if (streamId == '') return;
    int index = firstStreamMap.indexOf(int.parse(streamId));
    selectedStream = MyConstants.of(context).radioStreamName[index];
  }

  void _scrollListener() {
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

  Widget _streamDropDown(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down_circle_outlined),
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

  Widget _timeZoneDropDown(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down_circle_outlined),
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

  // Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            // 5 shimmer boxes
            for (int i = 0; i < 6; i++) _shimmerContent(),
          ],
        ),
      ),
    );
  }

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
}
