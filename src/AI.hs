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
      ("AB1", WithLookahead (alphaBetaOne COMP1100)),
      ("AB2", WithLookahead (alphaBetaTwo COMP1100)),
      ("default", WithLookahead (miniMaxOne COMP1100)),
      ("MM2", WithLookahead (miniMaxTwo COMP1100)),
      ("greedy", NoLookahead (greedy COMP1100)),
      ("content", NoLookahead (firstCaptureMove COMP1100)),
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
Needs to go down tree until case of moves depth = n-1
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

miniMaxOne :: Course -> GameState -> Int -> Move
miniMaxOne COMP1100 state depth = getMove (pruneMinMax depth (gameTree state))
miniMaxOne COMP1130 _ _         = error "Not in COMP1130"


getMove :: EvalTree -> Move
getMove (Node state val children) = nthElem 
  where
    nthElem  = moveList !! nth
    moveList = legalMoves state
    nth      = findDepth val (map getVal children)


findDepth :: Val -> [Val] -> Int
findDepth n vals = case vals of
  []   -> error "value not in children"
  x:xs
    | x /= n    -> 1 + findDepth n xs
    | otherwise -> 0


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
-- then propagating values up
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

getVal :: EvalTree -> Val
getVal (Node _ val _) = val



heuristicVal :: GameState -> Val
heuristicVal state = subtracti (countPieces state)
  where
    subtracti (p1,p2) = p1-p2




-- | ==================================================== | --
-- | ================ Minimax diff heuristic ================ | --
-- | ==================================================== | --
{-Uses a slightly modified heuristic-}


miniMaxTwo :: Course -> GameState -> Int -> Move
miniMaxTwo COMP1100 state depth = 
  getMove (pruneMinMaxTwo depth (gameTree state))
miniMaxTwo COMP1130 _ _         = error "Not in COMP1130"

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

heuristicRefined :: GameState -> Val
heuristicRefined state = case count of
  (0,_) -> -1000
  (_,0) -> 1000
  _     -> subtracti count
  where
    count             = countPieces state
    subtracti (p1,p2) = p1-p2




-- | ==================================================== | --
-- | ============== Minimax w/alpha-beta ================ | --
-- | ==================================================== | --

-- New type for the pruned tree to store alpha and beta values                
data ABTree = ABNode GameState Alpha Val Beta [EvalTree]
              | ABLeaf GameState Val

alphaBetaOne :: Course -> GameState -> Int -> Move
alphaBetaOne COMP1100 state depth = getMoveAB (pruneAB depth (gameTree state))
alphaBetaOne COMP1130 _ _         = error "Not in COMP1130"

getMoveAB :: ABTree -> Move
getMoveAB (ABNode state _ val _ children) = nthElem 
  where
    nthElem  = moveList !! nth
    moveList = legalMoves state
    nth      = findDepth val (map getVal children)
getMoveAB (ABLeaf _ _) = error "tree head is a leaf"

type Alpha = Int
type Beta  = Int

-- |// Initial bounds on the a/b values \\| --
maxB :: Val
maxB = 10000
minB :: Val
minB = -10000

-- Cuts the tree at off at an integer depth adding in leaf nodes
-- then propagating values up

pruneAB :: Depth -> GameTree -> ABTree
pruneAB = undefined
{-
pruneAB 0 (GTree x _)      = ABLeaf x val
  where val = (heuristicVal x)

pruneAB 0 (GTree x _)      = ABLeaf x ABLeaf x val
  where val = (heuristicVal x)

pruneAB n (GTree x kinder) = case x of
   State (Turn Player1) _ _ _ _ -> ABNode x maxi maxi maxB children
   State (Turn Player2) _ _ _ _ -> ABNode x val mini val children
   State (GameOver _) _ _ _ _   -> ABNode x val val val []
  where
    children  = (map (pruneMinMax (n-1)) kinder)
    maxi       = maximum kidValues
    mini       = minimum kidValues
    kidValues = map getVal children
    val = (heuristicVal x)
  -}











-- | ==================================================== | --
-- | =========== Minimax w/ alpha beta failed  ========== | --
-- | ==================================================== | --



-- A polymorphic tree structure
data NodeValTree e v = ValNode v [(e,NodeValTree e v)]

-- Tree with values only in leaves which keeps track of 
-- the moves as well as 
type FanGameTree = NodeValTree Move GameState

-- The minimax tree
data MMABTree = MMAB Player [(Move, MMABTree)]
                | Terminus Val

alphaBetaTwo :: Course -> GameState -> Int -> Move
alphaBetaTwo COMP1100 state depth = gMove (getMAB state depth)
alphaBetaTwo COMP1130 _ _         = error "Not in COMP1130"

getMAB :: GameState -> Int -> (Val, Maybe Move)
getMAB state d = case state of 
  State (Turn Player1) _ _ _ _ -> maximize' (genMMABTree d (fanGameTree state))
  State (Turn Player2) _ _ _ _ -> minimize' (genMMABTree d (fanGameTree state))
  State (GameOver _) _ _ _ _   -> error "given a gameover"

gMove :: (Val, Maybe Move) -> Move
gMove (_, Just c)  = c
gMove (_, Nothing) = error "no move - failure of gMove"


-- |// Compute full tree \\| --
fanGameTree :: GameState -> FanGameTree
fanGameTree state = case (turnFinder state) of
  GameOver _ -> ValNode state []
  Turn _     -> ValNode state succr
    where
      succr   = map (fmap fanGameTree) states
      states = moveListToS (legalMoves state) state

-- helper that just grabs the turn from a state for the case statement
turnFinder :: GameState -> Turn
turnFinder (State t _ _ _ _) = t

-- recurses through a list of legalMoves and...
-- ...then pairs it with the resulting gamestate
moveListToS :: [Move] -> GameState -> [(Move,GameState)]
moveListToS l state = case l of
  [] -> []
  x:xs -> case (applyMove myC x state) of
    Just s  -> (x,s):(moveListToS xs state)
    Nothing -> moveListToS xs state

-- |// Prune tree and attach values to leaves \\| --
genMMABTree :: Depth -> FanGameTree -> MMABTree
genMMABTree d tree = case (d, tree) of
  (_,ValNode s [])  -> Terminus (heuristicVal s)
  (0,ValNode s _)  -> Terminus (heuristicVal s)
  (_,ValNode s ys) -> MMAB (getPlayer s) (map (fmap (genMMABTree (d-1))) ys)




getPlayer :: GameState -> Player
getPlayer (State (Turn Player1) _ _ _ _) = Player1
getPlayer (State (Turn Player2) _ _ _ _) = Player2
getPlayer (State (GameOver _) _ _ _ _)   = error "gameover fed to getPlayer"


minOrMax :: Player -> 
  (Val -> Val -> MMABTree -> Maybe (Val, Move) -> (Val, Maybe Move))
minOrMax Player1 = maxiTree
minOrMax Player2 = miniTree


-- |// Higher order function for max and min \\| --

-- Function called for player 1

maximize' :: MMABTree -> (Val, Maybe Move)
maximize' tree = maxiTree minB maxB tree Nothing

maxiTree :: Val -> Val -> MMABTree -> Maybe (Val, Move) -> (Val, Maybe Move)
--gets value at terminus
maxiTree _ _ (Terminus val) _    = (val, Nothing)

--error in tree pruning
maxiTree _ _ (MMAB _ []) Nothing = error "error in the function maxiTree"

--base case of recursion through a 
maxiTree _ _ (MMAB _ []) (Just (val, move)) = (val, Just move)

--recurses through list of children
maxiTree a b (MMAB player ((move,children):ys)) acc =
  if val > b
  then (val, Just move)
  else maxiTree newa b (MMAB player ys) newAcc
  where 
    (val,_) = (minOrMax player) a b children Nothing
    newa    = max a val
    newAcc  = case acc of
      Nothing -> Just (val,move)
      Just (accVal,_) -> if val>accVal 
                        then Just (val,move)
                        else acc



-- Function called for player 2

minimize' :: MMABTree -> (Val, Maybe Move)
minimize' tree = miniTree minB maxB tree Nothing


miniTree :: Val -> Val -> MMABTree -> Maybe (Val, Move) -> (Val, Maybe Move)
--gets value at terminus
miniTree _ _ (Terminus val) _    = (val, Nothing)

--error in tree pruning
miniTree _ _ (MMAB _ []) Nothing    = error "error in the function maxiTree"

--base case of recursion through a 
miniTree _ _ (MMAB _ []) (Just (val, move)) = (val, Just move)

--recurses through children applying a/b rules
miniTree a b (MMAB player ((move,children):ys)) acc =
  if val <=a
  then (val, Just move)
  else miniTree a newb (MMAB player ys) newAcc
  where 
    (val,_) = (minOrMax player) a b children Nothing
    newb    = min b val
    newAcc  = case acc of
      Nothing -> Just (val,move)
      Just (accVal,_) -> if val<accVal 
                        then Just (val,move)
                        else acc