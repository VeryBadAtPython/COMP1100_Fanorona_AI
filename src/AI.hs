{-|
Module      : AI
Description : AIs for Fanorona
Copyright   : (c) 2022 ANU and Your Name Here
License     : AllRightsReserved
-}
module AI where

import           Fanorona

-- | Type of AI functions you can choose to write.
data AIFunc
  = NoLookahead (GameState -> Move)
    -- ^ Simple AIs that do not need lookahead.
  | WithLookahead (GameState -> Int -> Move)
    -- ^ AIs that want to look ahead. The assignment framework will
    -- call the function over and over with increasing integer
    -- arguments @1, 2, 3, ...@ until your AI's time limit is up. 

-- | The table of all AIs that your assignment provides. The AI named
-- "default" in this table is the one your tutor will dedicate most of
-- his or her attention to marking.

ais :: [(String, AIFunc)]
ais = [("default", NoLookahead (firstCaptureMove COMP1100)),
      ("provided", NoLookahead (firstLegalMove COMP1100))
      ]

-- | A very simple AI, which passes whenever it can, and if not,
-- picks the first move returned by the 'legalMoves' function.
-- By default, this function is called on COMP1100 rules, and so
-- will never pass.
-- AIs can rely on the 'legalMoves' list being
-- non-empty; if there were no legal moves, the framework would have
-- ended the game.
firstLegalMove :: Course -> GameState -> Move
firstLegalMove course state = case applyMove course Pass state of
  Nothing -> head (legalMoves state)
  _ -> Pass


-- | ==================================================== | --
-- | ================ First capture move ================ | --
-- | ==================================================== | --
{-
  - Picks the first of the list of capturing moves...
    ...otherwise just does the first legal move
  - Needs to check if the captures list is empty:
  - Then choose the first of it as a maybe type:
  - if nothing just call firstLegalMove
-}

firstCaptureMove :: Course -> GameState -> Move
firstCaptureMove course state = case applyMove course Pass state of
  Nothing -> case captureHead (captures state) of
    Just move -> move
    _         -> head (legalMoves state)
  _ -> Pass
  where
    captureHead :: [Move] -> Maybe Move
    captureHead moves = case moves of
      x:_ -> Just x
      _    -> Nothing

-- | ==================================================== | --
-- | ================ Greedy             ================ | --
-- | ==================================================== | --
{-
  - Needs the list of legalMoves
  - Should traverse this list and pick the one which takes the most pieces.
  - Such a traverse would return the head of the list if none are capturing
    moves.
  - Perhaps traverse the list and pair each one with the countPieces of other
    player each remaining state which can then be sorted through to get the one
    with the least remaining pieces
  - Need a function that applies each move to game state to then apply 
    countPieces to.
-}

-- Shortcut to enter my course if needed
myC :: Course
myC = COMP1100

-- Count the opponent's number of pieces state resulting from a move
-- Inputs a Maybe state and the opposing player
oppPieces :: Maybe GameState -> Player -> Maybe Int
oppPieces state player = case state of
  Just c -> case (countPieces c) of
    (p1,p2) -> if (player == Player1) then Just p1 else Just p2
    _       -> Nothing
  _      -> Nothing




  -- | ================ Turn Checker ================ | --
-- | A function that decides what to do based pon who's turn it is:
{-
whosTurn :: GameState -> Player
whosTurn (State turn _ _ _ _) = case turn of
  Player 1 -> undefined
  Player 2 -> undefined
-}
