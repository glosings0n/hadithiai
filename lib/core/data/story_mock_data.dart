import 'package:hadithi_ai/core/core.dart';

class StoryMockData {
  static List<StoryModel> getDailyStories() {
    final List<StoryModel> allStories = [];

    final List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final List<int> daysInMonths = [
      31,
      29,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    // Data banks for generating unique titles and descriptions.
    final List<String> heroes = [
      "The Lion",
      "Anansi the Spider",
      "The Turtle",
      "The Hare",
      "The Sage",
      "The Queen",
      "The Warrior",
      "The Elephant",
      "The Crocodile",
      "The Little Bird",
      "The Baobab",
      "The Hunter",
    ];
    final List<String> actions = [
      "and the Secret of the",
      "against the Spirit of the",
      "in Search of the",
      "at the Gate of the",
      "and the Curse of the",
      "under the Shadow of the",
      "and the Song of the",
    ];
    final List<String> objects = [
      "Sun",
      "Congo River",
      "Golden Mask",
      "Eastern Wind",
      "Desert",
      "Great Spirit",
      "Hidden Village",
      "Magic Drum",
      "Lost Kingdom",
    ];
    final List<String> regions = [
      "West Africa",
      "Central Africa",
      "East Africa",
      "Southern Africa",
      "North Africa",
      "Congo Basin",
      "Sahel",
      "Great Rift",
    ];

    int globalIndex = 0;

    for (int m = 0; m < 12; m++) {
      for (int d = 1; d <= daysInMonths[m]; d++) {
        // Cyclic + combinatory selection to keep generated stories diverse.
        String hero = heroes[globalIndex % heroes.length];
        String action = actions[globalIndex % actions.length];
        String object = objects[globalIndex % objects.length];
        String region = regions[globalIndex % regions.length];

        String title = "$hero $action $object";
        String summary =
            "In this legend from $region, $hero must face destiny to save the $object. A journey filled with wisdom and courage, passed down through generations.";

        allStories.add(
          StoryModel(
            id: 'daily_${months[m]}_$d',
            title: title,
            content: '',
            summary: summary,
            day: d,
            month: months[m],
            region: region,
          ),
        );
        globalIndex++;
      }
    }
    return allStories;
  }
}
