{-|
Module      : AI
Description : AIs for Fanorona
Copyright   : (c) 2022 ANU and Jacob Bos
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
ais = [ 
      ("default", WithLookahead (miniMaxTwo COMP1100)),
      ("MM1", WithLookahead (miniMaxOne COMP1100)),
      ("GRDY", NoLookahead (greedy COMP1100)),
      ("FCM", NoLookahead (firstCaptureMove COMP1100)),
      ("FLM", NoLookahead (firstLegalMove COMP1100))
      ]



-- | ==================================================== | --
-- | ================ First legal move   ================ | --
-- | ==================================================== | --
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
  - Traverses the list and pairs each one with the difference in pieces
    between players it results in then picks the optimal one
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

-- A function that maps diffPieces to a pair with the states
pairPieces :: [Move] -> GameState -> [(Move,Maybe Int)]
pairPieces moves state = map pairing moves
  where pairing = ( \x -> ( x, (diffPieces (applyMove myC x state)) ) )

-- Function that returns the best move and its resulting best...
-- ...score as a maybe type
-- If AI is Player1 use evaluator (\x y -> x<y)
-- If AI is Player2 use evaluator (\x y -> x>y)
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


-- The greedy AI
-- Uses an initial accumulator of the head of legalMoves and its value
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
  - Takes a state and generates a GameTree of states
    by recursion using legalMoves
  - Then traverses the GameTree evaluating and pruning at a certain depth
    then the best possible value is propagated up the tree according
    to the minimax rules
  - Then takes the best value, now stored in the head node
    and then work's out its depth in the legalMoves list,
    then gets move at that depth in legalMoves
-}


type Depth  = Int   -- Enhances readability keeps track of depth
type Val    = Int   -- The heuristic value from heuristicVal
type Choice = Move  -- To keep track of the move choice at depth==1

-- Tree of possible gamestates
data GameTree = GTree GameState [GameTree]

-- Evaluation tree that the GameTree is pruned to           
data EvalTree = Node GameState Val [EvalTree]



-- |\\ ============ AI Main Function ============ //| --
miniMaxOne :: Course -> GameState -> Int -> Move
miniMaxOne COMP1100 state depth = getMove (pruneMinMax depth (gameTree state))
miniMaxOne COMP1130 _ _         = error "Not in COMP1130"



-- |\\ ============== Move retriever ============== //| --
-- Gets the best move based off the EvalTree
-- Finds where elem in head node is in list of child nodes
-- Gets corresponding move in legalMoves
getMove :: EvalTree -> Move
getMove (Node state val children) = nthElem 
  where
    nthElem  = moveList !! nth
    moveList = legalMoves state
    nth      = findDepth val (map getVal children)

-- Finds the depth of the best move in the legalMoves list
-- Allows getMove to pull it out
findDepth :: Eq c => c -> [c] -> Int
findDepth n vals = case vals of
  []   -> error "value not in children"
  x:xs
    | x /= n    -> 1 + findDepth n xs
    | otherwise -> 0




-- |\\ ============ GameTree Generator ============ //| --
-- Generates the GameTree by recursing down from states with legalMoves
-- Each node keeps track of the evolution in the states
gameTree :: GameState -> GameTree
gameTree state = GTree state (map gameTree children)
  where
    children    = purge maybeStates
    maybeStates = map (\x -> applyMove myC x state) moves
    moves       = legalMoves state

-- purge removes Nothings values from the mapping of applyMove
purge :: [Maybe c] -> [c]
purge list = case list of
  [] -> []
  x:xs -> case x of
    (Just y) -> y:(purge xs)
    _        -> purge xs




-- |\\ ============ Pruner / Minimax ============ //| --
-- Cuts the tree at off at an integer depth adding in leaf nodes
-- then propagates values up from the base according to miniMax
pruneMinMax :: Depth -> GameTree -> EvalTree
pruneMinMax 0 (GTree x _)      = Node x (heuristicVal x) []
pruneMinMax n (GTree x kinder) = case x of
  State (Turn Player1) _ _ _ _ -> Node x maxi children
  State (Turn Player2) _ _ _ _ -> Node x mini children
  State (GameOver _) _ _ _ _   -> Node x (heuristicVal x) []
  where
    children  = (map (pruneMinMax (n-1)) kinder)
    maxi       = maximum kidValues
    mini       = minimum kidValues
    kidValues = map getVal children

-- Helper to get value in node
getVal :: EvalTree -> Val
getVal (Node _ val _) = val




-- |\\ ================ Heuristic ================ //| --
-- calculates the difference in pieces.
heuristicVal :: GameState -> Val
heuristicVal state = subtracti (countPieces state)
  where
    subtracti (p1,p2) = p1-p2




-- | ==================================================== | --
-- | ============== Minimax diff heuristic ============== | --
-- | ==================================================== | --
{-Uses a slightly modified heuristic to above
  was found to be beneficial-}


miniMaxTwo :: Course -> GameState -> Int -> Move
miniMaxTwo COMP1100 state depth = 
  getMove (pruneMinMaxTwo depth (gameTree state))
miniMaxTwo COMP1130 _ _         = error "Not in COMP1130"

-- Same as pruneMinMax but with heuristicRefined
pruneMinMaxTwo :: Depth -> GameTree -> EvalTree
pruneMinMaxTwo 0 (GTree x _)      = Node x (heuristicRefined x) []
pruneMinMaxTwo n (GTree x kinder) = case x of
   State (Turn Player1) _ _ _ _ -> Node x maxi children
   State (Turn Player2) _ _ _ _ -> Node x mini children
   State (GameOver _) _ _ _ _   -> Node x (heuristicRefined x) []
  where
    children  = (map (pruneMinMaxTwo (n-1)) kinder)
    maxi       = maximum kidValues
    mini       = minimum kidValues
    kidValues = map getVal children

-- |\\ New Heuristic //| --
-- Returns the difference in pieces unless the one of players loses.
-- If Player1 loses as they are maximizing player node is assigned -1000
-- If Player2 loses as they are minimizing player node is assigned 1000
heuristicRefined :: GameState -> Val
heuristicRefined state = case count of
  (0,_) -> -1000
  (_,0) -> 1000
  _     -> subtracti count
  where
    count             = countPieces state
    subtracti (p1,p2) = p1-p2













