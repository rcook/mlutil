module LAUtil.LabelledMatrix
  ( LabelId
  , LabelledMatrix (..)
  , readLabelledMatrix
  ) where

import           Control.Exception
import           Control.Monad
import           Control.Monad.ST
import           Data.List.Split
import qualified Data.Map as M
import qualified Data.Vector.Storable as VS
import qualified Data.Vector.Storable.Mutable as VSM
import qualified Data.Vector.Unboxed as VU
import qualified Data.Vector.Unboxed.Mutable as VUM
import           Numeric.LinearAlgebra
import           Numeric.LinearAlgebra.Devel

data CustomException = CustomException String deriving Show
instance Exception CustomException

type LabelId = Int

data LabelledMatrix = LabelledMatrix
  { _values :: Matrix R
  , _labelIds :: VU.Vector LabelId
  , _labels :: M.Map String LabelId
  } deriving Show

splitLine :: String -> [String]
splitLine = splitOneOf [' ', '\t']

forFoldM :: (Foldable t, Monad m) => b -> t a -> (b -> a -> m b) -> m b
forFoldM = flip . flip foldM

readLabelledMatrix :: FilePath -> IO LabelledMatrix
readLabelledMatrix path = do
    ls <- lines <$> readFile path
    let rowCount = length ls
    unless (rowCount > 0) (throwIO $ CustomException ("No rows in file " ++ path))

    let tokenCount = length $ splitLine (head ls)
        columnCount = tokenCount - 1

        (valuesV, labelIds, labels) = runST $ do
            mValues <- VSM.new (rowCount * columnCount)
            mLabelIds <- VUM.new rowCount

            labels' <- forFoldM M.empty (zip [0..] ls) $ \labels'' (r, l) -> do
                let allTokens = splitLine l
                    labelToken = last allTokens
                    valueTokens = init $ allTokens
                    (labels''', labelId) = case M.lookup labelToken labels'' of
                        Just labelId -> (labels'', labelId)
                        Nothing ->
                            let newLabelId = length labels''
                            in (M.insert labelToken newLabelId labels'', newLabelId)

                VUM.unsafeWrite mLabelIds r labelId

                forM_ (zip [0..] valueTokens) $ \(c, valueToken) ->
                    VSM.unsafeWrite mValues (r * columnCount + c) (read valueToken)

                return labels'''

            values' <- VS.unsafeFreeze mValues
            labelIds' <- VU.unsafeFreeze mLabelIds
            return (values', labelIds', labels')

        values = matrixFromVector RowMajor rowCount columnCount valuesV

    return $ LabelledMatrix values labelIds labels
