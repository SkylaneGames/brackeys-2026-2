1. Create the concept of an AI + Scene (i.e. a box).
2. The AI owns an array of next N free tiles/squares/coordinates
3. When the next rows are generated, pop one from step 2 to be the happy path.
4. Modify player.gd so that when you "move" instead of calling move and slide there, you're changing the next X
coordinates to be from AI A which is from step 2. It will then play out those moves.