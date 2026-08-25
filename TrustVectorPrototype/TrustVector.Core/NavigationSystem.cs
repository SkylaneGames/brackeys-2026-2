namespace TrustVector.Core;

public class NavigationSystem(BehaviourState initialBehaviour, AsteroidField asteroidField)
{
    public BehaviourState State { get; set; } = initialBehaviour;

    public int GetNextPosition(int playerPos)
    {
        return State switch
        {
            BehaviourState.Truthful => asteroidField.GetNextSafePosition(playerPos),
            BehaviourState.Deceitful => asteroidField.GetNearestAsteroid(playerPos),
            BehaviourState.Random => asteroidField.GetNextRandomPosition(playerPos),
            _ => throw new ArgumentOutOfRangeException(nameof(State), State, null),
        };
    }
}