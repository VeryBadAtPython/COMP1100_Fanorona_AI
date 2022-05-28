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
  [
  pairPiecesTest,
  diffPiecesTests,
  purgeTests,
  findDepthTests,
  getValTest,
  heuristicValTest
  ]




-- | ==================================================== | --
-- | ================ Greedy tests       ================ | --
-- | ==================================================== | --

-- | Test of pairPieces (checks lengths)
pairPiecesTest :: Test
pairPiecesTest =
  TestGroup "pairPieces" [
    Test "lengths equal of pairPieces and legal moves on initial state"
      (assertEqual (length (pairPieces moves kids)) (length moves))
  ]
  where
    moves = legalMoves kids
    kids  = initialState (2,4)


-- |\\ ==== diffPieces Tests ==== //| --
-- (1) initialState -> Just 0
-- (2) Nothing -> Nothing
diffPiecesTests :: Test
diffPiecesTests =
  TestGroup "diffPieces" [
    Test "initial State"
      (assertEqual (diffPieces (Just (initialState (2,4)))) (Just 0 :: Maybe Int)),
    Test "nothing"
      (assertEqual (diffPieces Nothing) (Nothing :: Maybe Int))
  ]




-- | ==================================================== | --
-- | ================ Minimax tests      ================ | --
-- | ==================================================== | --


-- |\\ ========== purge Tests =========== //| --
-- | Comprehensive test list of purge
-- (1) Empty list
-- (2) All nothings
-- (3) All justs
-- (4) Mix of nothings and justs
purgeTests :: Test
purgeTests =
  TestGroup "purge" [
    Test "Empty purge list"
      (assertEqual (purge [] ) ( [] :: [Int] )),
    Test "All Nothings in purge list"
      (assertEqual (purge [Nothing, Nothing]) ([] :: [Int])),
    Test "All Justs in purge list"
      (assertEqual (purge [Just 1, Just 2, Just 3]) ([1,2,3] :: [Int])),
    Test "A mix in purge list"
      (assertEqual (purge [Just 1, Nothing, Just 3]) ([1,3] :: [Int]))
  ]




-- |\\ ========== findDepth Tests ========== //| --
-- | Comprehensive test list of findDepth
-- (1) string with two of desired element
-- (2) list with one of desired integer
findDepthTests :: Test
findDepthTests =
  TestGroup "findDepth" [
    Test "findDepth test 1"
      (assertEqual (findDepth 'c' "schoonerc") ( 1 :: Int )),
    Test "findDepth test 2"
      (assertEqual (findDepth (3::Int) [0,1,2,3,4,5,6,7]) ( 3 :: Int ))
  ]




-- |\\ ============ getVal Tests ============ //| --
-- | Comprehensive test list of getVal
-- Only one possible case
getValTest :: Test
getValTest = Test "getVal"
      (assertEqual (getVal (Node (initialState (2,4)) 3 [] )) ( 3 :: Val ))
  



-- |\\ ========== heuristicVal Tests ========== //| --
heuristicValTest :: Test
heuristicValTest = Test "heuristicVal"
      (assertEqual (heuristicVal (initialState (2,4))) ( 0 :: Val ))
  
