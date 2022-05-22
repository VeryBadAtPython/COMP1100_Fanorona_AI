{-|
Module      : AITests
Description : Tests for your AI functions
Copyright   : (c) 2020 Your Name Here
License     : AllRightsReserved
-}
module AITests where

import           AI
import           Fanorona
import           Testing

aiTests :: Test
aiTests = TestGroup "AI"
  (
  diffPiecesTests
  ++purgeTests
  ++findDepthTests
  ++getValTest
  ++heuristicValTest
  )

-- | ==================================================== | --
-- | ================ Greedy tests       ================ | --
-- | ==================================================== | --

-- Test of pairPieces (checks length)
pairPiecesTest :: [Test]
pairPiecesTest =
  [
    Test "myC"
      (assertEqual (length (pairPieces moves kids)) (length moves))
  ]
  where
    moves = legalMoves kids
    kids  = initialState (2,4)


-- Test of diffPieces
diffPiecesTests :: [Test]
diffPiecesTests =
  [
    Test "diffPieces initial State"
      (assertEqual (diffPieces (Just (initialState (2,4)))) (Just 0 :: Maybe Int)),
    Test "diffPieces nothing"
      (assertEqual (diffPieces Nothing) (Nothing :: Maybe Int))
  ]


-- | ==================================================== | --
-- | ================ Minimax tests      ================ | --
-- | ==================================================== | --

-- Comprehensive test list of purge
purgeTests :: [Test]
purgeTests =
  [
    Test "Empty purge list"
      (assertEqual (purge [] ) ( [] :: [Int] )),
    Test "All Nothings in purge list"
      (assertEqual (purge [Nothing, Nothing]) ([] :: [Int])),
    Test "All Justs in purge list"
      (assertEqual (purge [Just 1, Just 2, Just 3]) ([1,2,3] :: [Int])),
    Test "A mix in purge list"
      (assertEqual (purge [Just 1, Nothing, Just 3]) ([1,3] :: [Int]))
  ]




-- Comprehensive test list of findDepth
findDepthTests :: [Test]
findDepthTests =
  [
    Test "findDepth test 1"
      (assertEqual (findDepth 'c' "schoonerc") ( 1 :: Int )),
    Test "findDepth test 2"
      (assertEqual (findDepth (3::Int) [0,1,2,3,4,5,6,7]) ( 3 :: Int ))
  ]




-- Comprehensive test list of getVal
getValTest :: [Test]
getValTest =
  [
    Test "getVal"
      (assertEqual (getVal (Node (initialState (2,4)) 3 [] )) ( 3 :: Val ))
  ]




-- Test of heuristicVal
heuristicValTest :: [Test]
heuristicValTest =
  [
    Test "heuristicVal"
      (assertEqual (heuristicVal (initialState (2,4))) ( 0 :: Val ))
  ]
