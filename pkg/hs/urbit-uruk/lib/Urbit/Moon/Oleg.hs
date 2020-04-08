{-# OPTIONS_GHC -Werror #-}

module Urbit.Moon.Oleg (oleg) where

import Prelude ()
import ClassyPrelude hiding (try)

import Control.Arrow          ((>>>))
import Data.Void              (Void, absurd)
import Numeric.Natural        (Natural)
import System.IO.Unsafe       (unsafePerformIO)
import Urbit.Pos              (Pos)
import Urbit.Uruk.Class       (Uruk(..))
import Urbit.Uruk.Refr.Jetted (Ur, UrPoly((:@), Fast))

import qualified Bound.Scope            as Bound
import qualified Bound.Var              as Bound
import qualified Urbit.Moon.Bracket     as B
import qualified Urbit.Uruk.Fast.Types  as F
import qualified Urbit.Uruk.Refr.Jetted as Ur


-- Types -----------------------------------------------------------------------

type Nat = Natural

data Deb p = Zero | Succ (Deb p) | DPrim p | Abs (Deb p) | App (Deb p) (Deb p)
  deriving (Eq, Show)

infixl 5 :#

data Com p = Com p :# Com p | P p | I | K | S | Sn Pos | C | Cn Pos | B | Bn Pos

instance Show p => Show (Com p) where
  show = \case
    S      -> "s"
    I      -> "i"
    C      -> "c"
    K      -> "k"
    B      -> "b"
    P  p   -> "[" <> show p <> "]"
    Sn i   -> "s" <> show i
    Bn i   -> "b" <> show i
    Cn i   -> "c" <> show i
    x :# y -> "(" <> intercalate " " (show <$> foldApp x [y]) <> ")"
   where
    foldApp (x :# y) acc = foldApp x (y : acc)
    foldApp x        acc = x : acc


-- Exp <-> Deb -----------------------------------------------------------------

expDeb :: forall p f . B.Exp p () Void -> Deb p
expDeb = go absurd
 where
  go :: (a -> Deb p) -> B.Exp p () a -> Deb p
  go f = \case
    B.Pri p  -> DPrim p
    B.Var v  -> f v
    x B.:@ y -> go f x `App` go f y
    B.Lam () b ->
      Abs $ go (Bound.unvar (const Zero) (Succ . f)) $ Bound.fromScope b

_debExp :: forall p f . Show p => Deb p -> B.Exp p () Void
_debExp = go (error . ("bad-deb: free variable: " <>) . show)
 where
  go :: (Nat -> a) -> Deb p -> B.Exp p () a
  go f = \case
    Zero     -> B.Var $ f $ debRef Zero
    Succ  d  -> B.Var $ f $ debRef $ Succ d
    DPrim p  -> B.Pri p
    App x y  -> go f x B.:@ go f y
    Abs b    -> B.Lam () $ Bound.toScope $ go (wrap f) b

  wrap f 0 = Bound.B ()
  wrap f n = Bound.F $ f $ pred n

  debRef :: Deb p -> Nat
  debRef Zero     = 0
  debRef (Succ d) = succ (debRef d)
  debRef rf       = error ("bad-deb: Invalid ref" <> show rf)


-- Oleg's Algorithm ------------------------------------------------------------

{-
    Compile lambda calculus to combinators.
-}
ski :: Deb p -> (Nat, Com p)
ski deb = case deb of
  DPrim p                        -> (0,       P p)
  Zero                           -> (1,       I)
  Succ d    | x@(n, _) <- ski d  -> (n + 1,   f (0, K) x)
  App d1 d2 | x@(a, _) <- ski d1
            , y@(b, _) <- ski d2 -> (max a b, f x y)
  Abs d | (n, e) <- ski d -> case n of
                               0 -> (0,       K :# e)
                               _ -> (n - 1,   e)
  where
  f (a, x) (b, y) = case (a, b) of
    (0, 0)             ->         x :# y
    (0, n)             -> bn n :# x :# y
    (n, 0)             -> cn n :# x :# y
    (n, m) | n == m    -> sn n :# x :# y
           | n < m     ->              bn (m-n) :# (sn n :# x) :# y
           | otherwise -> cn (n-m) :# (bn (n-m) :#  sn m :# x) :# y

  bn = Bn . o
  sn = Sn . o
  cn = Cn . o

  o ∷ Nat → Pos
  o 0 = error "Urbit.Moon.Oleg.ski: Bad bulk combinator param: 0"
  o n = fromIntegral n


-- Convert to Uruk -------------------------------------------------------------

comToUruk :: Uruk p => Com p -> p
comToUruk = \case
  P p         -> p
  K           -> uKay
  S           -> uEss
  Sn 1        -> uEss
  Sn n        -> uSen n
  I           -> uEye 1
  B           -> uBee 1
  Bn n        -> uBee n
  C           -> uSea 1
  Cn n        -> uSea n
  x :# y      -> unsafePerformIO (uApp (comToUruk x) (comToUruk y))

-- Entry Point -----------------------------------------------------------------

oleg :: Uruk p => B.Exp p () Void -> p
oleg = comToUruk . snd . ski . expDeb

instance IsString (B.Exp p () String)
 where
  fromString = B.Var

l :: Eq a => a -> B.Exp p () a -> B.Exp p () a
l nm = B.Lam () . Bound.abstract1 nm

try :: B.Exp p () String -> Deb p
try = expDeb . resolve
 where
  resolve :: B.Exp p () String -> (B.Exp p () Void)
  resolve = fromRight . traverse (Left . ("unbound variable: " <>))

  fromRight :: Either String b -> b
  fromRight (Left err) = error err
  fromRight (Right vl) = vl