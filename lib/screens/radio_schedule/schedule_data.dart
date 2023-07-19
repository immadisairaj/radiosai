import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/radio_schedule/schedule_entity.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';

class ScheduleData extends StatefulWidget {
  const ScheduleData({
    super.key,
    this.radioStreamIndex,
  });

  final int? radioStreamIndex;

  @override
  State<ScheduleData> createState() => _ScheduleData();
}

class _ScheduleData extends State<ScheduleData> {
  /// variable to show the loading screen
  bool _isLoading = true;

  final DateTime now = DateTime.now();

  /// date for the radio sai schedule
  DateTime? selectedDate;

  // below are used to hide/show the selection widget
  ScrollController? _scrollController;
  bool _showDropDown = true;
  bool _isScrollingDown = false;

  // used for the initial build
  int? oldStreamId = 0;
  final List<int> firstStreamMap = [1, 1, 6, 5];

  /// contains the base url of the radio sai schedule page
  final String baseUrl = 'https://schedule.sssmediacentre.org/program/';

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

  // TODO: handle timeout separately

  /// final date retrieved from the internet
  late List<ScheduleEntity> _finalData;

  @override
  void initState() {
    _isLoading = true;
    selectedDate = now;
    selectedStream = 'Prasanthi Stream';
    oldStreamId = widget.radioStreamIndex;
    _finalData = [];

    super.initState();

    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController!.removeListener(_scrollListener);
    _scrollController!.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    // handle the screen for the initial build
    _handleFirstBuild();

    // handle stream name display
    _handleStreamName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            if (!isSmallerScreen)
              AnimatedContainer(
                height: _showDropDown
                    ? (isBigScreen ? height * 0.16 : height * 0.2)
                    : 0,
                duration: _showDropDown
                    ? const Duration(microseconds: 200)
                    : const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedContainer(
                        height: _showDropDown
                            ? (isBigScreen ? height * 0.045 : height * 0.06)
                            : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FittedBox(
                            fit: BoxFit.fitHeight,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                'Date: ${DateFormat('MMMM dd, yyyy').format(selectedDate!)}',
                                style: TextStyle(
                                  fontSize: 19,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        height: _showDropDown
                            ? (isBigScreen ? height * 0.085 : height * 0.095)
                            : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8, left: 8, right: 8),
                          child: Row(
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.fitHeight,
                                  child: Text(
                                    'Select Stream:',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: _streamDropDown(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    maxHeight: height,
                  ),
                  child: Stack(
                    children: [
                      if (_finalData.isNotEmpty)
                        RefreshIndicator(
                          onRefresh: _refresh,
                          child: Scrollbar(
                            radius: const Radius.circular(8),
                            controller: _scrollController,
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
                                        bottom: (MediaQuery.of(context)
                                                    .viewPadding
                                                    .bottom >
                                                0)
                                            ? MediaQuery.of(context)
                                                .viewPadding
                                                .bottom
                                            : 20),
                                    child: Card(
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                      elevation: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      child: _scheduleItems(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // show when no data is retrieved
                      if (_finalData.isEmpty)
                        NoData(
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
                          text:
                              'No Data Available,\ncheck your internet or try again',
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _updateURL(selectedDate!);
                            });
                          },
                        ),
                      // show when no data is retrieved and timeout
                      // TODO: handle timeout case properly; commenting till then
                      // if (_finalData.isEmpty)
                      //   NoData(
                      //     backgroundColor:
                      //         Theme.of(context).colorScheme.background,
                      //     text:
                      //         'No Data Available,\nURL timeout, try again after some time',
                      //     onPressed: () {
                      //       setState(() {
                      //         _isLoading = true;
                      //         _updateURL(selectedDate!);
                      //       });
                      //     },
                      //   ),
                    ],
                  ),
                ),
                // Shown second child it is loading
                secondChild: Center(
                  child: _showLoading(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  /// widget for schedule items (contains the list)
  ///
  /// showed after getting data
  Widget _scheduleItems() {
    return ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        itemCount: _finalData.length,
        itemBuilder: (context, index) {
          ScheduleEntity rowData = _finalData[index];
          bool is24HoursFormat = MediaQuery.of(context).alwaysUse24HourFormat;
          // TODO: add 'vvv' in date format later and remove timeZoneName
          String localTime =
              '${DateFormat(is24HoursFormat ? 'HH:mm' : 'hh:mm a').format(rowData.dateTime)} ${rowData.dateTime.timeZoneName}';
          // String gmtTime = '${rowData[2]} GMT';
          String duration = '${rowData.durationMin} min';
          String category = rowData.category;
          String programe = rowData.content;
          // String fids = mainRowData[2].substring(1, mainRowData[2].length - 1);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () {
                      // TODO: implement this later
                      // if (fids != '') {
                      //   Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //           builder: (context) => Media(fids: fids)));
                      // } else {
                      //   getIt<ScaffoldHelper>().showSnackBar(
                      //       'No media found!', const Duration(seconds: 1));
                      // }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
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
                                localTime,
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
              if (index != _finalData.length - 1)
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
  /// takes in [date] as input
  ///
  /// continues the process by retrieving the data
  _updateURL(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String previousFormattedDate =
        DateFormat('yyyy-MM-dd').format(date.subtract(const Duration(days: 1)));
    String nextFormattedDate =
        DateFormat('yyyy-MM-dd').format(date.add(const Duration(days: 1)));

    // unique url for putting data into cache and getting it
    String url = '$baseUrl/data/$streamId-$formattedDate.txt';
    finalUrl = url;
    String previousUrl = '$baseUrl/data/$streamId-$previousFormattedDate.txt';
    String nextUrl = '$baseUrl/data/$streamId-$nextFormattedDate.txt';
    _getData(previousUrl, nextUrl, date);
  }

  /// retrieve the data from finalUrl
  ///
  /// continues the process by sending it to parse
  /// if the data is retrieved
  ///
  /// send previous date url, next date url and current date
  _getData(String previousUrl, String nextUrl, DateTime date) async {
    String tempResponse = '';
    // checks if the file exists in cache
    FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
    if (fileInfo == null) {
      // get data from online if not present in cache
      http.Response previousResponse;
      http.Response response;
      http.Response nextResponse;
      try {
        previousResponse = await http
            .get(Uri.parse(previousUrl))
            .timeout(const Duration(seconds: 40));
        response = await http
            .get(Uri.parse(finalUrl))
            .timeout(const Duration(seconds: 40));
        nextResponse = await http
            .get(Uri.parse(nextUrl))
            .timeout(const Duration(seconds: 40));
      } on SocketException catch (_) {
        setState(() {
          // if there is no internet
          _finalData = [];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      } on TimeoutException catch (_) {
        setState(() {
          // if timeout
          // TODO: handle timeout case
          _finalData = [];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      }
      tempResponse = '[';
      bool firstFlag = false;
      if (previousResponse.statusCode == 200) {
        tempResponse += previousResponse.body
            .substring(1, previousResponse.body.length - 1);
        firstFlag = true;
      }
      bool secondFlag = false;
      if (response.statusCode == 200) {
        tempResponse += firstFlag ? ',' : '';
        tempResponse += response.body.substring(1, response.body.length - 1);
        secondFlag = true;
      }
      if (nextResponse.statusCode == 200) {
        tempResponse += secondFlag ? ',' : '';
        tempResponse +=
            nextResponse.body.substring(1, nextResponse.body.length - 1);
      }
      tempResponse += ']';

      // put data into cache after getting from internet
      List<int> list = tempResponse.codeUnits;
      Uint8List fileBytes = Uint8List.fromList(list);
      DefaultCacheManager().putFile(finalUrl, fileBytes);
    } else {
      // get data from file if present in cache
      tempResponse = fileInfo.file.readAsStringSync();
    }
    _parseData(tempResponse, date);
  }

  /// parses the data retrieved from url.
  /// sets the final data to display
  ///
  /// need date (selected date) to be passed
  _parseData(String response, DateTime date) {
    final data = jsonDecode(response);
    List<ScheduleEntity> finalData = [];
    for (var row in data) {
      // get date time and convert it to local

      DateTime dateTime =
          DateFormat('yyyy-MM-dd hh:mm').parse(row[1], true).toLocal();
      int difference = DateTime(dateTime.year, dateTime.month, dateTime.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      // add data only if it's today after converting
      if (difference != 0) continue;

      // parse content
      var content = row[3];
      int clickHere = content.indexOf('- <a');
      if (clickHere > 0) {
        content = content.substring(0, clickHere);
      }

      // add it to final data
      finalData.add(ScheduleEntity(
        dateTime: dateTime,
        category: row[2],
        content: content,
        durationMin: int.parse(row[4]),
        relatedLink: row[5],
        newFlag: row[6] == '1',
        firstBroadcastOn: row[7],
      ));
    }

    // var document = parse(response);
    // var table = document.getElementById('sch')!;
    // // parsing table heads
    // List<String> tableHead = [];
    // for (int i = 1; i < 6; i++) {
    //   tableHead.add(table.getElementsByTagName('th')[i].text);
    //   var stringLength = tableHead[i - 1].length;
    //   tableHead[i - 1] = tableHead[i - 1].substring(4, stringLength - 3);
    //   tableHead[i - 1] = tableHead[i - 1].replaceAll('\n', ' ');
    //   tableHead[i - 1] = tableHead[i - 1].replaceAll('\t', '');
    //   tableHead[i - 1] = tableHead[i - 1].trim();
    // }
    // // return data from tableHead
    // // [0] Sl. No. [1] Loacl Time [2] GMT Time
    // // [3] Programe List [4] Duration(min)

    // // getting the local time
    // String localTime = tableHead[1].substring(4);
    // localTime = localTime.replaceAll('(', '');
    // localTime = localTime.replaceAll(')', '');
    // localTime = localTime.trim();

    // // parsing table data
    // List<List<String>> tableData = [];
    // int dataLength = table.getElementsByTagName('tr').length - 1;
    // if (dataLength == 0) {
    //   tableData = [
    //     ['null']
    //   ];
    //   setState(() {
    //     // set the data
    //     // _finalTableHead = tableHead;
    //     _finalTableData = tableData;
    //     _finalLocalTime = localTime;

    //     // loading is done
    //     _isLoading = false;
    //   });
    //   return;
    // }
    // for (int i = 1; i <= dataLength; i++) {
    //   List<String> tempList = [];
    //   var rowData =
    //       table.getElementsByTagName('tr')[i].getElementsByTagName('td');
    //   for (int j = 1; j < 6; j++) {
    //     if (j != 4) {
    //       tempList.add(rowData[j].text);
    //       var stringLength = tempList[j - 1].length;
    //       tempList[j - 1] = tempList[j - 1].substring(4, stringLength - 3);
    //       tempList[j - 1] = tempList[j - 1].replaceAll('\n', ' ');
    //       tempList[j - 1] = tempList[j - 1].replaceAll('\t', '');
    //       tempList[j - 1] = tempList[j - 1].trim();
    //     } else {
    //       // if j is 4, parse it differently

    //       String tempText = rowData[j].text;
    //       var stringLength = tempText.length;
    //       tempText = tempText.substring(4, stringLength - 3);
    //       tempText = tempText.replaceAll('\n', ' ');
    //       tempText = tempText.replaceAll('\t', '');
    //       tempText = tempText.trim();
    //       tempText = tempText.replaceFirst(' ', '<split>');

    //       // remove click here tags
    //       int clickHere = tempText.indexOf('- Click here');
    //       if (clickHere > 0) {
    //         int clickHereEnd = tempText.indexOf('-', clickHere + 2);
    //         tempText = tempText.substring(0, clickHere) +
    //             tempText.substring(clickHereEnd);
    //       }
    //       // TODO: get pdf scripts for discourse stream (click here tags)

    //       String? fids = '';
    //       if (rowData[j].getElementsByTagName('input').isNotEmpty) {
    //         fids =
    //             rowData[j].getElementsByTagName('input')[0].attributes['value'];
    //       }
    //       tempText += '<split>[$fids]';

    //       tempList.add(tempText);
    //     }
    //     // data of [3] will be
    //     // type<split>content<split>[fids]
    //     // fids is empty if it is a live session
    //     // content might also contain "- NEW"
    //   }
    //   tableData.add(tempList);
    // }
    // // return data from table data
    // // [0] Sl. No. [1] Loacl Time [2] GMT Time
    // // [3] Programe List [4] Duration(min)

    // if (tableData.isEmpty) {
    //   tableData = [
    //     ['null']
    //   ];
    // }

    if (mounted) {
      setState(() {
        // set the data
        _finalData = finalData;

        // loading is done
        _isLoading = false;
      });
    }
  }

  /// select the date and update the url
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Schedule started on 8th Nov 2019 - but,
      // data available from 19th Mar, 2023
      firstDate: DateTime(2023, 03, 19),
      initialDate: selectedDate!,
      // Schedule is available for 1 day after current date
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _isLoading = true;
        selectedDate = picked;
        _updateURL(selectedDate!);
      });
    }
  }

  /// select the date and update the url for iOS
  void _selectDateIOS(BuildContext context) {
    DateTime? picked;
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
                      initialDateTime: selectedDate,
                      // Schedule started on 8th Nov 2019
                      // data available from 19th Mar, 2023
                      minimumDate: DateTime(2023, 03, 19),
                      // Schedule is available for 1 day after current date
                      maximumDate: now.add(const Duration(days: 1)),
                      onDateTimeChanged: (pickedDateTime) {
                        picked = pickedDateTime;
                      },
                    ),
                  ),
                  SizedBox(
                    height: 70,
                    child: CupertinoButton(
                      child: const Text('OK'),
                      onPressed: () {
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            _isLoading = true;
                            selectedDate = picked;
                            _updateURL(selectedDate!);
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
      _updateURL(selectedDate!);
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
    streamId = '${firstStreamMap[widget.radioStreamIndex!]}';
    _updateURL(selectedDate!);
  }

  /// handle stream name to show in dropdown
  void _handleStreamName() {
    if (streamId == '') return;
    int index = firstStreamMap.indexOf(int.parse(streamId));
    selectedStream =
        MyConstants.of(context)!.radioStreamHttps.keys.toList()[index];
  }

  /// scroll listener to show/hide the selecting widget
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

  /// widget - dropdown for selecting radio stream
  Widget _streamDropDown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedStream,
        items: MyConstants.of(context)!.scheduleStream.keys.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: (value == selectedStream)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
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
              streamId = '${MyConstants.of(context)!.scheduleStream[value!]}';
              _updateURL(selectedDate!);
            });
          }
        },
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
