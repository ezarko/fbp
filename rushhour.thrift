/**
 * A road is recognized by its name and contains the length of the road from
 * intersection to intersection in the variable Distance, along with the max
 * speed that can be achieved on that road in addition to the current speed
 * seen on that road. Last, it contains the names of the two intersections
 * with which it connects.
 */
struct Road {
  1:string Name,
  2:double Distance,
  3:i32 MaxSpeed,
  4:i32 CurrentSpeed,
  5:string StartIntersection,
  6:string EndIntersection
}

/**
 * An intersection is a node on the map with a name as well as a list of
 * the roads with which it connects.
 */
struct Intersection {
  1:string Name,
  2:list<Road> ConnectedRoads
}

/**
 * Wrapper struct referencing the two intersections connecting a Road.
 */

struct IntersectionsForRoad {
  1:Intersection StartIntersection,
  2:Intersection EndIntersection
}

/**
 * Key: Road.Name
 * Value: The two intersections connecting the given Road in form of the
 * above struct.
 */

struct IntersectionsFromRoad {
  1:map<string, IntersectionsForRoad> Connections
}

/**
 * This is the main Map which contains a set of all intersections
 * (and thus roads) on the map.
 */
struct RoadMap {
  1:list<Intersection> Intersections
}

/**
 * This exception is thrown if a call to getRoadConditions is
 * is made before canMove() is verified, when takeRoad is called
 * with a speed greater than the CurrentSpeed or when takeRoad
 * is supplied with a road that is not present at current intersection.
 */
exception NoMoveMadeException {
  1:string message
}

/**
 * Thrown if any call to canMove() or takeRoad() is called after game is won.
 */
exception GameOverException {
}

/**
 * Thrown if any calls are made to any gameplay functions before registering
 * or joining the game.
 */
exception UnregisteredException {
}

/**
 * Thrown when a player attempts to register using an email that is
 * already registered in a particular game.
 */
exception DuplicateEmailException {
}

/**
 * The actual RushHour service which allows one to connect and interact with
 * our public server.
 */
service RushHour {

  /**
   * Registers a player in the game, returning true if it was a success, false
   * otherwise.
   */
  bool registerClient(1:string email, 2:string name)
    throws (1:DuplicateEmailException dee);

  /**
   * Returns true if player can make another call to getRoadConditions() and
   * takeRoad(), false otherwise.
   */
  bool canMove() throws (1: GameOverException goe, 2:UnregisteredException ue);

  /**
   * This function allows the user to specify which road they want to take next
   * along with the speed.
   */
  bool takeRoad(1:Road road, 2:double speed)
    throws (1:NoMoveMadeException nmme);

  /**
   * Can be called once after each move and returns a set of intersections
   * with updated road info (i.e. up-to-date CurrentSpeed). Can only be called
   * after a call to takeRoad() has been made (with the exception of the first
   * turn).
   */
  RoadMap getRoadConditions() throws (1:NoMoveMadeException nmme);


  /**
   * Returns the map<string, IntersectionForRoad> in the form of the
   * struct defined above, IntersectionFromRoad.
   */
  IntersectionsFromRoad getIntersectionsFromRoad();

  /**
   * Returns secret string for email submission if player is at final
   * intersection, a 'Nope!' otherwise.
   */
  string winGame() throws (1:UnregisteredException ue);

  /**
   * Returns the total time it's taken you to travel up until the time it's
   * called.
   */
  double getTime();

  /**
   * Returns the current intersection the player resides at.
   */
  Intersection getCurrentIntersection();

  /**
   * Return a string representation of the RushHour scoreboard sorted by
   * total time it took to reach the destination.
   */
  string getScoreBoard();
}
