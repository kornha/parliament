// /**
//  * canvas-astar.dart
//  * MIT licensed
//  *
//  * Created by Daniel Imms, http://www.growingwiththeweb.com
//  */

class Array2d<T> {
  late List<List<T>> array;
  T defaultValue;

  Array2d(int width, int height, {required this.defaultValue}) {
    array = [];
    this.width = width;
    this.height = height;
  }

  operator [](int x) => array[x];

  set width(int v) {
    while (array.length > v) array.removeLast();
    while (array.length < v) {
      List<T> newList = [];
      if (array.length > 0) {
        for (int y = 0; y < array.first.length; y++) newList.add(defaultValue);
      }
      array.add(newList);
    }
  }

  set height(int v) {
    while (array.first.length > v) {
      for (int x = 0; x < array.length; x++) array[x].removeLast();
    }
    while (array.first.length < v) {
      for (int x = 0; x < array.length; x++) array[x].add(defaultValue);
    }
  }
}
