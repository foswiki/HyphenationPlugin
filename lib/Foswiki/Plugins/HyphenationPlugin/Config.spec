# ---+ Extensions
# ---++ HyphenationPlugin
# This is the configuration used by the <b>HyphenationPlugin</b>.

# **STRING**
$Foswiki::cfg{HyphenationPlugin}{DefaultLanguage} = 'en';

# **PATH*
$Foswiki::cfg{HyphenationPlugin}{PatternsDir} = '$Foswiki::cfg{PubDir}/$Foswiki::cfg{SystemWebName}/HyphenationPlugin/patterns';

# **STRING**
$Foswiki::cfg{HyphenationPlugin}{MinLength} = 5;

# **BOOLEAN**
$Foswiki::cfg{HyphenationPlugin}{MemoryCache} = 1;

1;
