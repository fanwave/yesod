{-# LANGUAGE QuasiQuotes #-}
module Yesod.Form.Nic
    ( YesodNic (..)
    , nicHtmlField
    , maybeNicHtmlField
    ) where

import Yesod.Handler
import Yesod.Form.Core
import Yesod.Hamlet
import Yesod.Widget
import qualified Data.ByteString.Lazy.UTF8 as U
import Text.HTML.SanitizeXSS (sanitizeXSS)

class YesodNic a where
    -- | NIC Editor.
    urlNicEdit :: a -> Either (Route a) String
    urlNicEdit _ = Right "http://js.nicedit.com/nicEdit-latest.js"

nicHtmlField :: YesodNic y => FormFieldSettings -> FormletField sub y Html
nicHtmlField = requiredFieldHelper nicHtmlFieldProfile

maybeNicHtmlField :: YesodNic y => FormFieldSettings -> FormletField sub y (Maybe Html)
maybeNicHtmlField = optionalFieldHelper nicHtmlFieldProfile

nicHtmlFieldProfile :: YesodNic y => FieldProfile sub y Html
nicHtmlFieldProfile = FieldProfile
    { fpParse = Right . preEscapedString . sanitizeXSS
    , fpRender = U.toString . renderHtml
    , fpWidget = \theId name val _isReq -> do
        addBody [$hamlet|%textarea.html#$theId$!name=$name$ $val$|]
        addScript' urlNicEdit
        addJavascript [$julius|bkLib.onDomLoaded(function(){new nicEditor({fullPanel:true}).panelInstance("%theId%")});|]
    }

addScript' :: (y -> Either (Route y) String) -> GWidget sub y ()
addScript' f = do
    y <- liftHandler getYesod
    addScriptEither $ f y