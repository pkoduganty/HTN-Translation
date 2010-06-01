{-# LANGUAGE
    FlexibleContexts,
    FlexibleInstances,
    MultiParamTypeClasses,
    ScopedTypeVariables,
    TypeOperators,
    UndecidableInstances
  #-}
module Main where

import Data.Maybe
import System.Environment
import Text.ParserCombinators.Parsec

import HTNTranslation.Translation
import Planning.PDDL.PDDL3_0

class Functor f => AtomicFinder t f where
    --atomicFinder :: f [Expr (Atomic t)]-> [Expr (Atomic t)]
    atomicFinder :: f [t] -> [t]
instance (AtomicFinder t f, AtomicFinder t g) 
    => AtomicFinder t (f :+: g) where
    atomicFinder (Inl x) = atomicFinder x
    atomicFinder (Inr y) = atomicFinder y

--instance AtomicFinder t (Atomic t) where
--    atomicFinder (Atomic p tl) = [eAtomic p tl]
instance (:<:) (Atomic t) f => AtomicFinder (Expr f) (Atomic t) where
    atomicFinder (Atomic p tl) = [eAtomic p tl]
instance AtomicFinder t And where
    atomicFinder (And el) = concat el
instance AtomicFinder t Or where
    atomicFinder (Or el) = concat el
instance AtomicFinder t Not where
    atomicFinder (Not e) = e
instance AtomicFinder t Imply where
    atomicFinder (Imply e1 e2) = e1 ++ e2
instance AtomicFinder t (Exists v) where
    atomicFinder (Exists _ e) = e
instance AtomicFinder t (ForAll v) where
    atomicFinder (ForAll _ e) = e
instance AtomicFinder t Preference where
    atomicFinder (Preference _ e) = e


findAtomics :: AtomicFinder (Expr h) g => Expr g -> [Expr h]
findAtomics = foldExpr atomicFinder


class AtomicRenamer g f where
    atomicRenamer :: (String -> String) -> f (Expr g) -> Expr g
instance (AtomicRenamer h f, AtomicRenamer h g) 
    => AtomicRenamer h (f :+: g) where
    atomicRenamer t (Inl x) = atomicRenamer t x
    atomicRenamer t (Inr y) = atomicRenamer t y

instance (:<:) (Atomic t) f => AtomicRenamer f (Atomic t) where
    atomicRenamer t (Atomic p tl) = eAtomic (t p) tl
instance (:<:) And f => AtomicRenamer f And where
    atomicRenamer _ (And el) = eAnd el
instance (:<:) Or f => AtomicRenamer f Or where
    atomicRenamer _ (Or el) = eOr el
instance (:<:) Not f => AtomicRenamer f Not where
    atomicRenamer _ (Not e) = eNot e
instance (:<:) Imply f => AtomicRenamer f Imply where
    atomicRenamer _ (Imply e1 e2) = eImply e1 e2
instance (:<:) (Exists v) f => AtomicRenamer f (Exists v) where
    atomicRenamer _ (Exists vl e) = eExists vl e
instance (:<:) (ForAll v) f => AtomicRenamer f (ForAll v) where
    atomicRenamer _ (ForAll vl e) = eForAll vl e
instance (:<:) Preference f => AtomicRenamer f Preference where
    atomicRenamer _ (Preference n e) = ePreference n e


renameAtomics :: (Functor g, AtomicRenamer g g) => (String -> String) -> Expr g -> Expr g
renameAtomics h = foldExpr (atomicRenamer h)


class ConstFinder g f where
    constFinder :: f (Maybe (Expr g)) -> Maybe (Expr g)
instance (ConstFinder h f, ConstFinder h g) => ConstFinder h (f :+: g) where
    constFinder (Inl x) = constFinder x
    constFinder (Inr y) = constFinder y

instance (:<:) Const f => ConstFinder f Const where
    constFinder (Const c) = Just $ eConst c
instance ConstFinder f Var where
    constFinder _ = Nothing
instance ConstFinder f Function where
    constFinder _ = Nothing

findConst :: (Functor f, Functor g, ConstFinder g f) => Expr f -> Maybe (Expr g)
findConst = foldExpr constFinder

constAtomic :: (Functor f, Functor g, Functor h, ConstFinder g f, 
    Atomic (Expr g) :<: h) =>
    Expr g -> Expr (Atomic (Expr f)) -> Maybe (Expr h)
constAtomic constTemplate (In (Atomic p tl)) =
    let consts = mapMaybe findConst tl `asTypeOf` [constTemplate] in
    if (length tl == length consts) then
        Just $ eAtomic p consts
    else
        Nothing

processProblem :: Int -> Int -> FilePath -> IO ()
processProblem items arity domfile = do
    contents <- readFile domfile
    printResult $ runParser pddlProblemParser emptyProblem domfile contents
    where
        printResult (Left err) = print err
        printResult (Right dom) = do
            let translated = translateProblem items arity dom
            let atomicGoals =
                    maybe [] (findAtomics . renameAtomics ("goal-"++)) (getGoal dom) 
                    :: [Expr PDDLAtom]
            let initGoals =
                    (eAtomic "start_achieve-goals" ([] :: [ConstTermExpr])) :
                    mapMaybe 
                    (constAtomic (undefined :: ConstTermExpr))
                    atomicGoals :: [InitLiteralExpr]
            let problem = setInitial (initGoals ++ getInitial translated) translated
            print problem 

main :: IO ()
main = do
    stackArity:stackItems:args <- getArgs
    sequence_ [
        processProblem
            (read stackItems :: Int)
            (read stackArity :: Int) 
            domfile 
        | domfile <- args]
