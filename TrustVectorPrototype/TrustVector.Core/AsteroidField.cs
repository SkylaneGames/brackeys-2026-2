namespace TrustVector.Core;

public class AsteroidField
{
    private const int Lanes = 10;
    private const int WindowSize = 10;
    public const int StartIx = Lanes / 2;
    private const double ChanceOfAsteroid = 0.5;

    private readonly Queue<Row> _slidingWindow = [];

    public void GenerateNext()
    {
        if (_slidingWindow.Count == 0)
        {
            _slidingWindow.Enqueue(GenerateInitialRow());
        }

        do
        {
            var nextHappyIx = GetNextHappyPathIx(_slidingWindow.Last().HappyPathIx);
            _slidingWindow.Enqueue(new Row
            {
                HappyPathIx = nextHappyIx,
                Cells = GenerateCells(nextHappyIx),
            });
        } while (_slidingWindow.Count < WindowSize);

        if (_slidingWindow.Count > WindowSize)
        {
            _slidingWindow.Dequeue();
        }
    }

    private static int GetNextHappyPathIx(int lastPositionIx)
    {
        // Pick a random lane, to the left, right or in-front of the current index
        var start = lastPositionIx == 0 ? 0 : -1;
        var end = lastPositionIx == Lanes - 1 ? 1 : 2;

        var nextPathIx = lastPositionIx + Random.Shared.Next(start, end);
        return nextPathIx;
    }

    private static Row GenerateInitialRow()
    {
        var cells = GenerateCells(StartIx);
        return new Row
        {
            HappyPathIx = StartIx,
            Cells = cells,
        };
    }

    private static List<bool> GenerateCells(int happyPathIx)
    {
        return
        [
            .. Enumerable
                .Range(0, Lanes)
                .Select(i => i != happyPathIx && Random.Shared.NextDouble() < ChanceOfAsteroid)
        ];
    }

    private class Row
    {
        public required int HappyPathIx { get; init; }
        public required List<bool> Cells { get; init; } = [];
    }

    public IEnumerable<CellType[]> GetWindowState()
    {
        return _slidingWindow.Select(r =>
            r.Cells
                .Select((c, ix) => ix == r.HappyPathIx ? CellType.ValidPath : c ? CellType.Asteroid : CellType.Empty)
                .ToArray());
    }

    public int GetNextSafePosition(int playerPos)
    {
        var nextRow = _slidingWindow.Peek();

        // Check if any of the cells within +/- 1 index are the safe path
        if (Math.Abs(playerPos - nextRow.HappyPathIx) <= 1)
        {
            return nextRow.HappyPathIx;
        }

        // Else check for an empty cell.
        // TODO: could improve it later to pathfind the next best possible path if no intended safe path is available.
        for (var ix = playerPos - 1; ix <= playerPos + 1; ix++)
        {
            if (ix >= 0 && ix < nextRow.Cells.Count && !nextRow.Cells[ix])
            {
                return ix;
            }
        }

        // Else pick a random one
        return GetNextRandomPosition(playerPos);
    }

    public int GetNearestAsteroid(int playerPos)
    {
        var nextRow = _slidingWindow.Peek();
        for (var ix = playerPos - 1; ix <= playerPos + 1; ix++)
        {
            if (ix >= 0 && ix < nextRow.Cells.Count && nextRow.Cells[ix])
            {
                return ix;
            }
        }

        // Else pick a random one
        return GetNextRandomPosition(playerPos);
    }

    public int GetNextRandomPosition(int playerPos)
    {
        var start = playerPos == 0 ? 0 : -1;
        var end = playerPos == Lanes - 1 ? 1 : 2;

        return playerPos + Random.Shared.Next(start, end);
    }
}