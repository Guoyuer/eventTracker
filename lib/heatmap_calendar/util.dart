import 'package:flutter/material.dart';
// import 'package:date_util/date_util.dart';

///将时间段拆成一年一年的
int getYearLength(int year) {
  final bool isLeapYear = (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
  if (isLeapYear) return 366;
  return 365;
}

List<DateTimeRange> split2year(DateTimeRange rawRange) {
  List<DateTimeRange> yearRanges = [];
  DateTime i = rawRange.start;
  DateTime end = rawRange.end;

  int daysInYear = getYearLength(i.year); //第一年
  DateTime lastDay = DateTime(i.year).add(Duration(days: daysInYear - 1));
  while (i.compareTo(end) < 0) {
    if (i == lastDay) {
      break;
    }
    i = i.add(Duration(days: 1));
  } //如果第一个年没有完，则i = end；完了则i == 该年的最后一天;

  yearRanges.add(DateTimeRange(start: rawRange.start, end: i));
  i = i.add(Duration(days: 1));
  //i：下一年的第一天

  while (end.difference(i) >= Duration(days: getYearLength(i.year) - 1)) {
    //中间的完整年
    yearRanges.add(DateTimeRange(start: i, end: i.add(Duration(days: getYearLength(i.year) - 1))));
    i = i.add(Duration(days: getYearLength(i.year)));
  }

  if (i.compareTo(end) <= 0) {
    yearRanges.add(DateTimeRange(start: i, end: end));
  }
  return yearRanges;
}

///将一年内时间段拆成一月一月的
List<DateTimeRange> split2month(DateTimeRange rawRange) {
  List<DateTimeRange> monthRanges = [];
  DateTime i = rawRange.start;
  DateTime end = rawRange.end;

  int daysInMonth = DateUtils.getDaysInMonth(i.month, i.year); //第一个月
  DateTime lastDay = DateTime(i.year, i.month).add(Duration(days: daysInMonth - 1));
  while (i.compareTo(end) < 0) {
    if (i == lastDay) {
      break;
    }
    i = i.add(Duration(days: 1));
  } //如果第一个月没有完，则i = end；完了则i == 该月的最后一天;

  monthRanges.add(DateTimeRange(start: rawRange.start, end: i)); //第一个月
  i = i.add(Duration(days: 1));
  //i：下个月的第一天

  while (end.difference(i) >= Duration(days: DateUtils.getDaysInMonth(i.month, i.year) - 1)) {
    //中间的完整月
    monthRanges.add(DateTimeRange(start: i, end: i.add(Duration(days: DateUtils.getDaysInMonth(i.month, i.year) - 1))));
    i = i.add(Duration(days: DateUtils.getDaysInMonth(i.month, i.year)));
  }

  if (i.difference(end) <= Duration(days: 0)) {
    monthRanges.add(DateTimeRange(start: i, end: end)); //最后一周
  }
  return monthRanges;
}

///将一个月内的时间段拆成一周一周的
List<DateTimeRange> split2weeks(DateTimeRange rawRange) {
  List<DateTimeRange> weekdayRanges = [];
  DateTime i = rawRange.start;
  DateTime end = rawRange.end;

  while (i.compareTo(end) < 0) {
    if (i.weekday == DateTime.saturday) {
      break;
    }
    i = i.add(Duration(days: 1));
  } //如果没有包括Saturday，则i = end；包括了则i == saturday;

  weekdayRanges.add(DateTimeRange(start: rawRange.start, end: i)); //第一个周
  i = i.add(Duration(days: 1));
  //i：sunday

  while (end.difference(i) >= Duration(days: 6)) {
    //中间的完整周
    weekdayRanges.add(DateTimeRange(start: i, end: i.add(Duration(days: 6))));
    i = i.add(Duration(days: 7));
  }
  if (i.compareTo(end) <= 0) {
    weekdayRanges.add(DateTimeRange(start: i, end: end)); //最后一周
  }
  return weekdayRanges;
}

///去掉时分秒
DateTime getDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
