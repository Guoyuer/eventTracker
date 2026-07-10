List<double> combineAdjacentHourSlots(List<double> hourlyValues) {
  return [
    for (var index = 0; index < 12; index++)
      hourlyValues[index * 2] + hourlyValues[index * 2 + 1],
  ];
}
