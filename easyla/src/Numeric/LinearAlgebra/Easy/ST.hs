{-|
Module      : Numeric.LinearAlgebra.Easy.ST
Description : Easy linear algebra: build vectors and matrices in ST monad
Copyright   : (C) Richard Cook, 2016
Licence     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable
-}

{-# LANGUAGE Rank2Types #-}

module Numeric.LinearAlgebra.Easy.ST
    ( STMatrix
    , newMatrix
    , runSTMatrix
    , withSTMatrix
    , writeMatrix
    ) where

import           Control.Monad.ST
import qualified Numeric.LinearAlgebra.Devel as LAD
import           Numeric.LinearAlgebra.Easy.Types

type STMatrix s = LAD.STMatrix s R

newMatrix :: R -> Int -> Int -> ST s (STMatrix s)
newMatrix = LAD.newMatrix

runSTMatrix :: (forall s . ST s (STMatrix s)) -> Matrix
runSTMatrix = LAD.runSTMatrix

-- |Wraps building a matrix of doubles in ST monad
--
-- >>> :{
-- withSTMatrix 9 3 3 $ \m' -> do
--     writeMatrix m' 0 0 10.0
--     writeMatrix m' 1 1 20.0
--     writeMatrix m' 2 2 30.0
-- :}
-- (3><3)
--  [ 10.0,  9.0,  9.0
--  ,  9.0, 20.0,  9.0
--  ,  9.0,  9.0, 30.0 ]
--
withSTMatrix :: R -> Int -> Int -> (forall s . STMatrix s -> ST s ()) -> Matrix
withSTMatrix value m n f = runSTMatrix $ do
    x <- newMatrix value m n
    f x
    return x

writeMatrix :: STMatrix s -> Int -> Int -> R -> ST s ()
writeMatrix = LAD.writeMatrix
