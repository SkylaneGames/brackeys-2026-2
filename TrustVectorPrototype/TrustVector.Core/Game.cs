namespace TrustVector.Core;

public class Game
{
    private readonly Player _player;
    private readonly AsteroidField _asteroidField = new();
    private readonly List<NavigationSystem> _navigationSystems;

    public Game()
    {
        _player = new Player(AsteroidField.StartIx);
        _navigationSystems =
        [
            new NavigationSystem(BehaviourState.Truthful, _asteroidField),
            new NavigationSystem(BehaviourState.Deceitful, _asteroidField),
        ];

        _player.ActiveNavSystem = _navigationSystems[0];
    }

    public void NextCycle()
    {
        _asteroidField.GenerateNext();
        _player.Move();
    }

    public IEnumerable<CellType[]> Map => _asteroidField.GetWindowState();
    public int PlayerIx => _player.Position;
}