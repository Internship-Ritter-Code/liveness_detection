enum Horizontal { left, right, standBy }

enum Vertical {
  top,
  bottom,
  standBy,
}

class Liveness {
  Horizontal? horizontal;
  Vertical? vertical;
  bool? smile;

  Liveness({
    this.horizontal,
    this.smile,
    this.vertical,
  });
}
