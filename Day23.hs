{-# LANGUAGE TupleSections #-}

module Day23 where

-- Question source: https://adventofcode.com/2021/day/23

import           Control.Monad
import           Data.Array (Array)
import qualified Data.Array as A
import           Data.Bifunctor
import           Data.Map (Map)
import qualified Data.Map as M
import           Data.Maybe
import qualified Data.Set as S
import qualified Data.Text as T
import qualified Gadgets.Array as A
import qualified Gadgets.Map as M
import           Utilities

type Game = -- Maps of amphipods in room/hallway & sorted depth for each room.
  (Map String (Int, Int), Map String Int, Map (Int, Int) String, Array Int Int)

config :: Map Char (Int, Int)
config = M.fromAscList $ zip "ABCD" $ iterate (bimap (* 10) (+ 2)) (1, 2)

roomX, cost :: [Char] -> Int
roomX = snd . fromJust . flip M.lookup config . head
cost  = fst . fromJust . flip M.lookup config . head

isSorted :: Int -> Game -> Bool
isSorted depth (_, _, bs, _) = let headEq p c = fmap head (bs M.!? p) == Just c
                               in  and [headEq (2, i) 'A' | i <- [1..depth]]
                                && and [headEq (4, i) 'B' | i <- [1..depth]]
                                && and [headEq (6, i) 'C' | i <- [1..depth]]
                                && and [headEq (8, i) 'D' | i <- [1..depth]]

-- Basically brute-forcing through possible moves (with certain optimisations).
runGame :: Int -> Game -> Int
runGame d = run 0 . (0 ,)
  where
    run i m@(c, game)
      | isSorted d game = c
      | otherwise       = minimum $ maxBound : map (run (i + 1)) (moves m)
    toIx           = subtract 1 . (`div` 2)
    (doors, doorS) = ([2, 4..8], S.fromList doors)
    moves m@(c, (rs, hs, bs, arr))
      | not $ null h2r = [head h2r]
      | not $ null r2r = [head r2r]
      | length hs == 7 = []
      | otherwise      = r2h
      where
        h2r      = concatMap (\(str, x) -> goRoom c str x (x, 0)) (M.assocs hs)
        r2r      = concatMap (\(str, p@(x, y)) ->
                              goRoom (c + y * cost str) str x p) topRs
        r2h      = concatMap (uncurry go) topRs
        topRs    = catMaybes [getRow x | x <- doors, arr A.! toIx x < 0]
        getRow x = msum $ map (\y -> fmap (, (x, y)) $ bs M.!? (x, y)) [1..d]
        go str p@(x, y)
          = concat [goHori (c + y * cost str) str x p i | i <- [-1, 1]]
        goRoom c str x p@(x', y') -- From hallway to room
          | ry < 0     = []
          | cantGoRoom = []
          | y' == d'   = [(c', (rs', hs', bs', arr A.// [r', (toIx x', d')]))]
          | otherwise  = [(c', (rs', hs', bs', arr A.// [r']))]
            where
              d'         = d + fromMaybe 0 (arr A.!? toIx x') + 1
              r@(rx, ry) = (roomX str, arr A.! toIx rx)
              cantGoRoom = any ((`M.member` bs) . (, 0))
                               [min rx (x + 1)..max rx (x - 1)]
              c'         = c + cost str * (ry + abs (x - rx))
              (rs', hs') = (M.insert str r rs, M.delete str hs)
              (bs', r')  = (M.insert r str $ M.delete p bs, (toIx rx, ry - 1))
        goHori c str x p@(x', y') dir -- From room to hallway
          | dir * (x - 5) > 5  = []
          | M.member (x, 0) bs = []
          | S.member x doorS   = next
          | y' == d'           = (c, (rs', hs', bs', arr A.// [r'])) : next
          | otherwise          = (c, (rs', hs', bs', arr)) : next
          where
            (c', d')   = (c + cost str, d + arr A.! toIx x' + 1)
            next       = goHori c' str (x + dir) p dir
            (rs', hs') = (M.delete str rs, M.insert str x hs)
            (bs', r')  = (M.insert (x, 0) str $ M.delete p bs, (toIx x', d'))

day23Part1 :: Game -> Int
day23Part1 = runGame 2

day23Part2 :: Game -> Int
day23Part2 = runGame 4

main :: IO ()
main = do
  _ : _ : rawLines <- fmap T.unpack . T.lines <$> readInput "day23"
  let rawGame = parseRaw rawLines
  print $ day23Part1 $ toGame 2 rawGame
  print $ day23Part2 $ toGame 4 $ addMd rawGame
  where
    parseRaw     = fst . foldr (uncurry ((. zip [-1..]) . flip . foldr . go))
      (M.empty, M.fromList $ zip "ABCD" $ repeat 1) . zip [1..]
    go i (j, ch) raw@(rs, counts)
      | ch `elem` "# " = raw
      | otherwise      = ( M.insert (ch : show (counts M.! ch)) (j, i) rs
                         , M.adjust succ ch counts )
    addMd        = let f = zip ["D3", "D4", "C3", "B4", "B3", "A4", "A3", "C4"] 
                   in  M.union (M.fromList $ f (liftM2 (,) [2, 4..8] [2, 3]))
                     . M.map (\p@(x, y) -> if y == 1 then p else (x, 4))
    toGame d raw = (raw, M.empty, raw', arr)
      where
        raw'     = M.swapkv raw
        run ch x = length $ takeWhile ((ch ==) . head . (raw' M.!))
                                      (map (x, ) [d, d - 1..1])
        arr      = A.fromList $ zipWith (((-) (- 1) .) . run) "ABCD" [2, 4..8]
