{-# OPTIONS -fglasgow-exts #-}

{-| Names in the concrete syntax are just strings (or lists of strings for
    qualified names).
-}
module Syntax.Concrete.Name where

import Data.Generics (Typeable, Data)

import Syntax.Position

{-| A name is a non-empty list of alternating 'Id's and 'Hole's. A normal name
    is represented by a singleton list, and operators are represented by a list
    with 'Hole's where the arguments should go. For instance: @[Hole,Id "+",Hole]@
    is infix addition.

    Equality and ordering on @Name@s are defined to ignore range so same names
    in different locations are equal.
-}
data Name = Name !Range [NamePart]
    deriving (Typeable, Data)

data NamePart = Hole | Id String
    deriving (Typeable, Data, Eq, Ord)

-- | @noName_ = 'noName' 'noRange'@
noName_ :: Name
noName_ = noName noRange

-- | @noName r = 'Name' r ['Hole']@
noName :: Range -> Name
noName r = Name r [Hole]

-- | @qualify A.B x == A.B.x@
qualify :: QName -> Name -> QName
qualify (QName m) x	= Qual m (QName x)
qualify (Qual m m') x	= Qual m $ qualify m' x

-- Define equality on @Name@ to ignore range so same names in different
--     locations are equal.
--
--   Is there a reason not to do this? -Jeff
--
--   No. But there are tons of reasons to do it. For instance, when using
--   names as keys in maps you really don't want to have to get the range
--   right to be able to do a lookup. -Ulf

instance Eq Name where
    Name _ xs == Name _ ys  = xs == ys

instance Ord Name where
    compare (Name _ xs) (Name _ ys) = compare xs ys


-- | @QName@ is a list of namespaces and the name of the constant.
--   For the moment assumes namespaces are just @Name@s and not
--     explicitly applied modules.
--   Also assumes namespaces are generative by just using derived
--     equality. We will have to define an equality instance to
--     non-generative namespaces (as well as having some sort of
--     lookup table for namespace names).
data QName = Qual  Name QName
           | QName Name 
  deriving (Typeable, Data, Eq, Ord)

isPrefix, isPostfix, isInfix, isNonfix :: Name -> Bool
isPrefix  (Name _ xs) = head xs /= Hole && last xs == Hole
isPostfix (Name _ xs) = head xs == Hole && last xs /= Hole
isInfix   (Name _ xs) = head xs == Hole && last xs == Hole
isNonfix  (Name _ xs) = head xs /= Hole && last xs /= Hole

instance Show Name where
    show (Name _ xs) = concatMap show xs

instance Show NamePart where
    show Hole	= "_"
    show (Id s) = s

instance Show QName where
    show (Qual m x) = show m ++ "." ++ show x
    show (QName x)  = show x

instance HasRange Name where
    getRange (Name r _)	= r

instance HasRange QName where
    getRange (QName  x) = getRange x
    getRange (Qual n x)	= fuseRange n x

