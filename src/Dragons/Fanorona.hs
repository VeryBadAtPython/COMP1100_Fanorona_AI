{-# OPTIONS_GHC -Wno-orphans #-}

{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Dragons.Fanorona
Description : Fanorona-specific things students don't need to see
Copyright   : (c) 2022 The Australian National University
License     : AllRightsReserved

This module collects functions and instances for Fanorona-specific data
structures (so they don't belong in the generic game framework), but
are also implementation details that students don't need to concern
themselves with.
-}
module Dragons.Fanorona where

import AI
import Fanorona
import qualified Data.Text as T
import Data.Aeson
import Dragons.Game

toAITable :: [(String, AIFunc)] -> [(String, GenericAIFunc GameState Move)]
toAITable = (fmap . fmap) toGenericAIFunc
  where
    toGenericAIFunc :: AIFunc -> GenericAIFunc GameState Move
    toGenericAIFunc aiFunc st = case aiFunc of
      NoLookahead f -> [f st]
      WithLookahead f -> map (f st) [1..]

rules1100 :: Int -> Int -> GameRules GameState Move
rules1100 h w = GameRules
  { gameInitialState = initialState (w `div` 2, h `div` 2)
  , gameGetTurn = turn
  , gameApplyMove = applyMove COMP1100
  }

rules1130 :: Int -> Int -> GameRules GameState Move
rules1130 h w = GameRules
  { gameInitialState = initialState (w `div` 2, h `div` 2)
  , gameGetTurn = turn
  , gameApplyMove = applyMove COMP1130
  }

-- How to turn move types to and from JSON. Best practice is
-- to define instances next to either the data type or the
-- typeclass. These are "orphan" instances, and normally poor
-- practice, but we don't want to have too much mysterious code in
-- files that students need to read.

instance FromJSON Move where
  parseJSON (String s) = case T.unpack s of
    "pass" -> pure Pass
    _ -> error "parseJSON Move: Non-Pass JSON string."
  parseJSON val = (withObject "move" $ \o -> Move
    <$> o .: "moveType"
    <*> o .: "from"
    <*> o .: "to") val

instance FromJSON MoveType where
  parseJSON (String s) = case T.unpack s of
    "paika" -> pure Paika
    "withdrawal" -> pure Withdrawal
    "approach" -> pure Approach
    _ -> error "parseJSON MoveType: not a MoveType." 
  parseJSON _ = error "parseJSON MoveType: not a MoveType."

instance FromJSON Location where
  parseJSON = withObject "location" $ \o -> Location
    <$> o .: "x"
    <*> o .: "y"

instance ToJSON Move where
  toJSON (Move moveType from to) = object
    [ "pass" .= False
    , "moveType" .= moveType
    , "from" .= from
    , "to" .= to
    ]
  toJSON Pass = String "pass"

instance ToJSON MoveType where
  toJSON Paika = String "paika"
  toJSON Withdrawal = String "withdrawal"
  toJSON Approach = String "approach"
  
instance ToJSON Location where
  toJSON (Location x y) = object
    [ "x" .= x, "y" .= y ]

instance ToJSON Captor where 
  toJSON c = case c of 
    None -> object []
    Captor loc capt -> object
       [ "loc" .= loc, "captured" .= capt ]

instance ToJSON GameState where
  toJSON (State t c bnd brd h) = object
    [ "turn" .= t
    , "captured" .= c
    , "bounds" .= bnd
    , "board" .= jsonBoard brd
    , "history" .= map jsonBoard h
    ]
    where
      jsonBoard :: Board -> Value
      jsonBoard = String . (foldMap . foldMap) (\case
        Piece Player1 -> "1"
        Piece Player2 -> "2"
        Empty -> " ")
