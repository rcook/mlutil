{-# LANGUAGE RecordWildCards #-}

module MLUtil.Graphics.Flowchart
    ( ArrowLabel (..)
    , Class (..)
    , Label (..)
    , Tree (..)
    , flowchart
    ) where

import           MLUtil.Graphics.Imports

type DiagramWithSize = (Diagram, Size)
type Size = (Measure, Measure)

class ArrowLabel a where
    arrowLabel :: a -> Maybe String

-- TODO: Rename this to make it less specific to decision trees
newtype Class = C { unClass :: String } deriving (Eq, Ord, Show)

-- TODO: Rename this to make it less specific to decision trees
newtype Label = L { unLabel :: String } deriving (Eq, Show)

-- TODO: Not happy with the tuple since we don't use a for anything except ArrowLabel
data Tree a = Leaf Class | Node Label [(Tree a, a)] deriving Show

data FlowchartLayout = FlowchartLayout
    { boxInnerWidth :: Measure
    , boxInnerHeight :: Measure
    , boxFrameWidth :: Measure
    } deriving Show

defaultFlowchartLayout :: FlowchartLayout
defaultFlowchartLayout = FlowchartLayout
    { boxInnerWidth = 10
    , boxInnerHeight = 5
    , boxFrameWidth = 2
    }

flowchart :: ArrowLabel a => Tree a -> Diagram
flowchart = fst . (flowchartHelper defaultFlowchartLayout)

flowchartHelper :: ArrowLabel a => FlowchartLayout -> Tree a -> DiagramWithSize
flowchartHelper layout (Leaf s) = (leafBox layout (unClass s), (boxOuterWidth layout, boxOuterHeight layout))
flowchartHelper layout@FlowchartLayout{..} (Node nodeLabel childTreesWithArrowLabels) =
    let
        boxOuterWidth' = boxOuterWidth layout
        boxOuterHeight' = boxOuterHeight layout
        h = length childTreesWithArrowLabels `quot` 2
        arrowStart = p2 (0, -(boxInnerHeight / 2))
        childDiagramInfos = map (\(t, al) -> let (d, (w, h)) = flowchartHelper layout t in (al, d, w, h)) childTreesWithArrowLabels

        -- TODO: Consider collapsing these into a single fold
        width = foldr (\(_, _, w, _) acc -> acc + w) 0 childDiagramInfos
        maxHeight = foldr (\(_, _, _, h) acc -> if h > acc then h else acc) 0 childDiagramInfos
        (childDiagrams, _) = foldr
            (\(_, d, w, _) (ds, x) -> let d' = d # moveTo (p2 (x - w / 2, -boxOuterHeight')) in (d' : ds, x - w))
            ([], width / 2)
            childDiagramInfos
        (arrows, _) = foldr
            (\(_, d, w, _) (ds, x) -> let d = arrowBetween' (with & headLength .~ verySmall) arrowStart (p2 (x - w / 2, boxInnerHeight / 2 - boxOuterHeight')) in (d : ds, x - w))
            ([], width / 2)
            childDiagramInfos
        (arrowLabels, _) = foldr
            (\(pos, (al, _, w, _)) (ds, x) ->
                case arrowLabel al of
                    Nothing -> (ds, x - w)
                    Just s ->
                        let d = text s # moveTo (p2 (x - w / 2, -(boxOuterHeight' / 2)))
                        in (d : ds, x - w))
            ([], width / 2)
            (zip [-h ..] childDiagramInfos)

        height = maxHeight + boxOuterHeight'
    in
        (mconcat $
            nodeBox layout (unLabel nodeLabel) # moveTo (p2 (0, 0)) :
            childDiagrams ++
            arrows ++
            arrowLabels
            , (width, height))

boxOuterWidth :: FlowchartLayout -> Measure
boxOuterWidth FlowchartLayout{..} = boxFrameWidth + boxInnerWidth + boxFrameWidth

boxOuterHeight :: FlowchartLayout -> Measure
boxOuterHeight FlowchartLayout{..} = boxFrameWidth + boxInnerHeight + boxFrameWidth

leafBox :: FlowchartLayout -> String -> Diagram
leafBox FlowchartLayout{..} s = frame boxFrameWidth $ text s <> roundedRect boxInnerWidth boxInnerHeight 3

nodeBox :: FlowchartLayout -> String -> Diagram
nodeBox FlowchartLayout{..} s = frame boxFrameWidth $ text s <> rect boxInnerWidth boxInnerHeight