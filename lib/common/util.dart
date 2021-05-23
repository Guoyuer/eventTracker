///去掉时分秒
DateTime getDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

int getSelected(List<bool> list) {
  for (int i = 0; i < list.length; i++) {
    if (list[i] == true) return i;
  }
  return -1;
}
