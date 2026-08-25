// See https://aka.ms/new-console-template for more information

using TrustVector.Core;

Console.WriteLine("Welcome to TrustVector!");

var game = new Game();

while (true)
{
    game.NextCycle();
    RenderGame(game);
    await Task.Delay(500);
}

static void RenderGame(Game game)
{
    var map = game.Map.ToList();

    // Render the visible game window (reversed so asteroids appear to move down the screen).
    for (var i = map.Count - 1; i >= 0; i--)
    {
        var row = map[i];
        if (i == 0)
        {
            // Render the player on the first row.
            RenderRow(row, game.PlayerIx);
        }
        else
        {
            RenderRow(row);
        }
    }
}

static void RenderRow(CellType[] next, int? playerIx = null)
{
    Console.WriteLine(string.Join(" ", next.Select((c, ix) => RenderCell(c, ix, playerIx))));
}

static string RenderCell(CellType arg, int ix, int? playerIx = null) => arg switch
{
    CellType.Empty when ix != playerIx => " ",
    CellType.Asteroid when ix != playerIx => "O",
    CellType.ValidPath when ix != playerIx => ".",
    _ when ix == playerIx => "^",
    _ => throw new ArgumentOutOfRangeException(nameof(arg), arg, null)
};