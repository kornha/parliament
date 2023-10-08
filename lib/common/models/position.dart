enum PoliticalPosition {
  RIGHT,
  LEFT,
  CENTER,
  EXTREME;

  static PoliticalPosition? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'right':
        return PoliticalPosition.RIGHT;
      case 'left':
        return PoliticalPosition.LEFT;
      case 'center':
        return PoliticalPosition.CENTER;
      case 'extreme':
        return PoliticalPosition.EXTREME;
      default:
        return null;
    }
  }
}
