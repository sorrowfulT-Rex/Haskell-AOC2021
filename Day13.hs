{-# LANGUAGE OverloadedStrings #-}

module Day13 where

-- Question source: https://adventofcode.com/2021/day/13

import           Control.Monad
import           Data.Bifunctor
import           Data.List
import           Data.Set (Set)
import qualified Data.Set as S
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Tuple
import           Utilities

origami :: Set (Int, Int) -> (Text, Int) -> Set (Int, Int)
origami pts (d, n) = S.map go pts
  where
    go pt@(x, y)
      | (d == "x" && x < n) || (d == "y" && y < n) = pt
      | otherwise                                  = mapfs ((2 * n) -) pt
    mapfs = if d == "x" then first else second

day13Part1 :: [(Int, Int)] -> (Text, Int) -> Int
day13Part1 = (length .) . origami . S.fromList

day13Part2 :: [(Int, Int)] -> [(Text, Int)] -> IO ()
day13Part2 pts ops = do
  let result = sortOn swap $ S.toList $ foldl origami (S.fromList pts) ops
  forM_ (zipWith minus ((-1, 0) : result) result) $ \(x, lineFeed) -> do
    when lineFeed $ putStrLn ""
    putStr $ replicate (fromIntegral x - 1) ' ' ++ "\x2588"
  putStrLn ""
  where
    minus (x, y) (x', y')
      | y == y'   = (x' - x, False)
      | otherwise = (x' + 1, True)

main :: IO ()
main = do
  [pts', ops'] <- T.splitOn "\n\n" <$> readInput "day13"
  let (pts, ops) = (ptParser <$> T.lines pts', opParser <$> T.lines ops')
  print $ day13Part1 pts (head ops)
  day13Part2 pts ops
  where
    ptParser = listToPair . map readInt . T.splitOn ","
    opParser = second readInt . listToPair . T.splitOn "=" . last . T.words
