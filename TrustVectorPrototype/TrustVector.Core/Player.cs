namespace TrustVector.Core;

public class Player(int startPos)
{
    public int Position { get; set; } = startPos;

    public NavigationSystem? ActiveNavSystem { get; set; }

    public void Move()
    {
        Position = ActiveNavSystem?.GetNextPosition(Position) ?? Position;
    }
}