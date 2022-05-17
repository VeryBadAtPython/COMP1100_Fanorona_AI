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
ais = [("default", NoLookahead (greedy COMP1100)),
      ("contented", NoLookahead (firstCaptureMove COMP1100)),
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

-- Count the how many more pieces Player1 has then Player2
-- Inputs a Maybe state and returns a maybe int
diffPieces :: Maybe GameState -> Maybe Int
diffPieces state = case state of
  Just c -> case (countPieces c) of
    (p1,p2) ->  Just (p1 - p2)
  _      -> Nothing

-- Need a function that maps diffPieces to a pair with the states
pairPieces :: [Move] -> GameState -> [(Move,Maybe Int)]
pairPieces moves state = map pairing moves
  where pairing = ( \x -> ( x, (diffPieces (applyMove myC x state)) ) )

-- Function that returns the best move and its resulting best...
-- ...score as a maybe type
-- If AI is Player1 use evaluator (\x y -> x>=y)
-- If AI is Player2 use evaluator (\x y -> x<=y)
greedyHelp :: (Int -> Int -> Bool) -> [(Move,Maybe Int)] ->
   (Move,Maybe Int) -> (Move,Maybe Int)
greedyHelp evaluator moves acc = case (moves,acc) of
  ((a,b):xs, (_,d)) -> case (b,d) of
    (Just x, Just y)
      | evaluator x y -> greedyHelp evaluator xs (a,b)
      | otherwise     -> greedyHelp evaluator xs acc
    (Just _, Nothing) -> greedyHelp evaluator xs (a,b)
    _                 -> greedyHelp evaluator xs acc
  _                 -> acc


-- The final greedy heuristic
greedy :: Course -> GameState -> Move
greedy course state = case state of
  State (Turn Player1) _ _ _ _ ->
    case greedyHelp (\x y -> x<y) pairs initAcc of
      (k,_) -> k
  State (Turn Player2) _ _ _ _ ->
    case greedyHelp (\x y -> x>y) pairs initAcc of
      (k,_) -> k
  State (GameOver _) _ _ _ _ -> error "Game Over"
  where pairs   = (pairPieces (legalMoves state) state)
        initAcc = (\m n -> (m,n))
          (head (legalMoves state)) 
          (diffPieces (applyMove course (head (legalMoves state)) state))


-- | ==================================================== | --
-- | ================ Minimax            ================ | --
-- | ==================================================== | --
{-
Needs to go down tree until case depth = n-1
make the leaf nodes Leaf (result state) (move to get there) (heuristic value)
Find where its maxed of minned
-}


{-
Tree designed to store the initial move that led to the terminus leaf
The nodes along the way 
-}
type Depth  = Int   -- Enhances readability keeps track of depth
type Val    = Int   -- The heuristic value from heuristicVal
type Choice = Move  -- To keep track of the move choice at depth==1
                 
data GameTree = GTree GameState [GameTree]
                
data EvalTree = Node GameState Val [EvalTree]


{-
Tree designed to store the initial move that led to the terminus leaf
The nodes along the way 
-}
gameTree :: GameState -> GameTree
gameTree state = GTree state (map gameTree children)
  where
    children    = purge maybeStates
    maybeStates = map (\x -> applyMove myC x state) moves
    moves       = legalMoves state

-- purge removes Nothings values from the mapping of applyMove
purge :: [Maybe GameState] -> [GameState]
purge list = case list of
  [] -> []
  x:xs -> case x of
    (Just y) -> y:(purge xs)
    _        -> purge xs

-- Cuts the tree at off at an integer depth adding in leaf nodes
pruneDepth :: Depth -> GameTree -> GameTree
pruneDepth 0 (GTree x _)         = GTree x []
pruneDepth _ (GTree x [])        = GTree x []
pruneDepth n (GTree x children)  = GTree x (map (pruneDepth (n-1)) children)

-- Cuts the tree at off at an integer depth adding in leaf nodes
-- then (not) propagating values up
pruneMinMax :: Depth -> GameTree -> EvalTree
pruneMinMax 0 (GTree x _)      = Node x (heuristicVal x) []
pruneMinMax n (GTree x kinder) = case x of
   State (Turn Player1) _ _ _ _ -> Node x max children
   State (Turn Player2) _ _ _ _ -> Node x min children
   State (GameOver _) _ _ _ _   -> Node x (heuristicVal x) []
  where
    children  = (map (pruneMinMax (n-1)) kinder)
    max       = maximum kidValues
    min       = minimum kidValues
    kidValues = map getVal children

getVal :: EvalTree -> Val
getVal (Node _ val _) = val


heuristicVal :: GameState -> Val
heuristicVal state = subtract (countPieces state)
  where
    subtract (p1,p2) = p1-p2

-- | ==================================================== | --
-- | =============== Minimax w/ alpha beta ============== | --
-- | ==================================================== | --

