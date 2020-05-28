{-# OPTIONS_GHC -Wall -Werror #-}

module Urbit.Uruk.Dash.Exp
  ( SingJet(..)
  , DataJet(..)
  , Ur(..)
  , ExpTree(..)
  , tree
  , unTree
  , Val, Exp
  )
where

import ClassyPrelude

import Data.Tree        (Tree(Node))
import Numeric.Natural  (Natural)
import Urbit.Moon.Arity ()
import Urbit.Pos        (Pos)

import qualified Data.Char  as C
import qualified Urbit.Atom as Atom


-- Numbers ---------------------------------------------------------------------

type Nat = Natural


-- Combinator Trees ------------------------------------------------------------

infixl 5 :&;

data SingJet
  = SEQ
  | FIX
  | IFF
  | PAK
  | ZER
  | EQL
  | LTH
  | ADD
  | INC
  | DEC
  | FEC
  | MUL
  | DIV
  | MOD
  | SUB
  | FUB
  | NOT
  | XOR
  | BEX
  | LSH
  | DED
  | UNI
  | YES
  | NAH
  | LEF
  | RIT
  | CAS
  | CON
  | CAR
  | CDR
  | TRACE
  | LCON
  | LNIL
  | GULF
  | TURN
  | SNAG
  | WELD
 deriving (Eq, Ord, Read, Show, Enum, Bounded, Generic)
 deriving anyclass NFData

data DataJet
  = Sn !Pos
  | Bn !Pos
  | Cn !Pos
  | In !Pos
  | NAT !Nat
 deriving (Eq, Ord, Generic)
 deriving anyclass NFData

data ExpTree n
  = N n
  | ExpTree n :& ExpTree n
 deriving (Eq, Ord, Generic)
 deriving anyclass NFData

data Ur
  = S
  | K
  | E
  | W
  | DataJet DataJet
  | SingJet SingJet
 deriving (Eq, Ord, Generic)
 deriving anyclass NFData

type Exp = ExpTree Ur
type Val = Exp


-- Instances -------------------------------------------------------------------

instance Show DataJet where
  show = \case
    Sn  n                            -> 'S' : show n
    In  n                            -> 'I' : show n
    Bn  n                            -> 'B' : show n
    Cn  n                            -> 'C' : show n
    NAT n | n < 2048                 -> show n
    NAT (Atom.atomUtf8 -> Right txt)
        | all isValidChar txt        -> "'" <> unpack txt <> "'"
    NAT n                            -> show n
   where
    isValidChar :: Char -> Bool
    isValidChar c = or [C.isPrint c, c == '\n']

instance Show Ur where
  show = \case
    S          -> "S"
    K          -> "K"
    E          -> "E"
    W          -> "W"
    DataJet dj -> show dj
    SingJet sj -> show sj

tree :: ExpTree a -> Tree a
tree = go [] where
  go a = \case
    N n    -> Node n a
    x :& y -> go (tree y : a) x

unTree :: Tree a -> ExpTree a
unTree (Node n xs) = foldl' (:&) (N n) (unTree <$> xs)

showTree :: Show a => Tree a -> String
showTree (Node n []) = show n
showTree (Node n xs) =
  '(' : intercalate " " (show n : fmap showTree xs) <> ")"

instance Show a => Show (ExpTree a) where
  show = showTree . tree
