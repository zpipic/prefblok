enum PlayerPosition{
  left,
  center,
  right,
  right2;

  static PlayerPosition getRelativePosition(int playerPosition, int otherPosition, int n){
    if (playerPosition == otherPosition) return PlayerPosition.center;

    int left = ((playerPosition - 1) % n + n) % n;
    int right = (playerPosition + 1) % n;
    int right2 = (playerPosition + 2) % n;

    if (otherPosition == left) {
      return PlayerPosition.left;
    } else if (otherPosition == right) {
      return PlayerPosition.right;
    } else if(otherPosition == right2) {
      return PlayerPosition.right2;
    }

    return PlayerPosition.center;
  }
}