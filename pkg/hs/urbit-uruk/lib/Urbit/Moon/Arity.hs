{-# OPTIONS_GHC -Wall -Werror #-}

module Urbit.Moon.Arity
  ( Arity(..)
  , appArity
  , arityPos
  , arityInt
  )
where

import ClassyPrelude
import Urbit.Pos


--------------------------------------------------------------------------------

data Arity
  = AriEss       --  S
  | AriKay       --  K
  | AriJay !Pos  --  Jⁿ
  | AriHdr !Pos  --  Jⁿt
  | AriDub       --  W
  | AriOth !Pos  --  Anything else
 deriving (Show)

appArity :: Arity -> Arity -> Maybe Arity
appArity (AriOth 1) _          = Nothing
appArity AriDub     _          = Just $ AriOth 6
appArity (AriOth n) _          = Just $ AriOth $ pred n
appArity (AriJay n) (AriJay 1) = Just $ AriJay $ succ n
appArity (AriJay n) _          = Just $ AriHdr n
appArity (AriHdr n) _          = Just $ AriOth n
appArity AriEss     _          = Just $ AriOth 2
appArity AriKay     _          = Just $ AriOth 2

arityPos :: Arity -> Pos
arityPos = \case
  AriEss   -> 3
  AriKay   -> 3
  AriJay p -> p+2
  AriHdr p -> p+1
  AriDub   -> 7
  AriOth p -> p

arityInt :: Arity -> Int
arityInt = fromIntegral . arityPos
