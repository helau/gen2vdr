#!/usr/bin/perl -p0777
# striphtml ("striff tummel")

# how to strip out html comments and
# tags and transform entities in just
# three - count 'em three -
# substitutions; sed and awk eat your
# heart out. :-)

# as always, translations from this
# nacri rendition into more
# characteristically marine,
# herpetoid, titillative, or
# indonesian idioms are welcome for
# the furthering of comparative
# cyberlinguistic studies.

require 5.001;
# for nifty embedded regexp comments

# first we'll shoot all the
# <!-- comments -->

s{ <!     # comments begin with '<!'
          # followed by 0 or more
          # comments;
   (.*?)  # this eats up comments
          # in non random places
   (      # not supposed to have any
          # whitespace here
          # just a quick start:
   --     # each comment starts with
          # a '--'
     .*?  # and includes all text up
          # to and including the
   --     # next occurrence.
     \s*  # and may have trailing
          # whitespace (but not
          # leading whitespace)
   )+     # repetire ad libitum
   (.*?)  # trailing non comment text
  >       # up to a '>'
}{
  if ($1 || $3) { # this silliness for
                  # embedded comments in tags
     "<!$1 $3>";
  }
}gsex;       # mutate into nada, nothing,
             # and niente


# next we'll replace <br> with new line

s{ <br>
}{ "\n" }gsex;     # mutate into nada, nothing,

                # and niente
# next we'll remove all the <tags>

s{ <            # opening angle bracket
                #
   (?:          # Non-backreffing grouping
                #                        paren
       [^>'"] * # 0 or more things that are
                #       neither > nor ' nor "
         |      # or else
        ".*?"   # a section between
                #  double quotes (stingy match)
         |      # or else
        '.*?'   # a section between
                #  single quotes (stingy match)
   )+           # repetire ad libitum
                # hm...are null tags (<>)
                #                   legal?
  >             # closing angle bracket
}{}gsx;         # mutate into nada, nothing,
                # and niente


# finally we'll translate all &valid; HTML 2.0
# entities

s{ (
    &           # an entity starts with a
                # semicolon
    (
      \x23\d+   # and is either a pound
                # (# == hex 23) and numbers
       |        # or else
      \w+       # has alphanumunders...
    )
   ;?           # a semicolon terminates,
                # as does anything else
  )
} {
    $entity{$2} # if it's a known entity,
                # use that.
        ||      # But otherwise
        $1      # leave what we'd found.
}gex;           # execute replacement - that's
                # code not a string


# but wait! load up the %entity mappings
# enwrapped in a BEGIN so that we only
# execute once since we're in a -p "loop".
# awk is kinda nice after all.
BEGIN {

 %entity = (
    lt     => '<',
    gt     => '>',
    amp    => '&',
    quot   => '"',     # "  (vertical double quote)
    nbsp   => chr 160, #    (space)
    iexcl  => chr 161, # ¡
    cent   => chr 162, # ¢
    pound  => chr 163, # £
    curren => chr 164, # ¤
    yen    => chr 165, # ¥
    brvbar => chr 166, # ¦  (broken vertical bar)
    sect   => chr 167, # §
    uml    => chr 168, # ¨  (umlaut, or dieresis)
    copy   => chr 169, # ©
    ordf   => chr 170, # ª  (feminine ordinal)
    laquo  => chr 171, # «
    not    => chr 172, # ¬
    shy    => chr 173, # ­  (soft hyphen)
    reg    => chr 174, # ®
    macr   => chr 175, # ¯
    deg    => chr 176, # °
    plusmn => chr 177, # ±
    sup2   => chr 178, # ²  (superscript two)
    sup3   => chr 179, # ³  (superscript three)
    acute  => chr 180, # ´  (acute accent)
    micro  => chr 181, # µ  (micro sign)
    para   => chr 182, # ¶  (pilcrow)
    middot => chr 183, # ·
    cedil  => chr 184, # ¸  (cedilla)
    sup1   => chr 185, # ¹  (superscript one)
    ordm   => chr 186, # º  (masculine ordinal)
    raquo  => chr 187, # »
    frac14 => chr 188, # ¼  (one-quarter)
    frac12 => chr 189, # ½  (one-half)
    frac34 => chr 190, # ¾  (three-quarters)
    iquest => chr 191, # ¿
    Agrave => chr 192, # À
    Aacute => chr 193, # Á
    Acirc  => chr 194, # Â
    Atilde => chr 195, # Ã
    Auml   => chr 196, # Ä
    Aring  => chr 197, # Å
    AElig  => chr 198, # Æ
    Ccedil => chr 199, # Ç
    Egrave => chr 200, # È
    Eacute => chr 201, # É
    Ecirc  => chr 202, # Ê
    Euml   => chr 203, # Ë
    Igrave => chr 204, # Ì
    Iacute => chr 205, # Í
    Icirc  => chr 206, # Î
    Iuml   => chr 207, # Ï
    ETH    => chr 208, # Ð  (capital Eth, Icelandic)
    Ntilde => chr 209, # Ñ
    Ograve => chr 210, # Ò
    Oacute => chr 211, # Ó
    Ocirc  => chr 212, # Ô
    Otilde => chr 213, # Õ
    Ouml   => chr 214, # Ö
    times  => chr 215, # ×
    Oslash => chr 216, # Ø
    Ugrave => chr 217, # Ù
    Uacute => chr 218, # Ú
    Ucirc  => chr 219, # Û
    Uuml   => chr 220, # Ü
    Yacute => chr 221, # Ý  (capital Y, acute accent)
    THORN  => chr 222, #Þ   (capital THORN, Icelandic)
    szlig  => chr 223, # ß
    agrave => chr 224, # à
    aacute => chr 225, # á
    acirc  => chr 226, # â
    atilde => chr 227, # ã
    auml   => chr 228, # ä
    aring  => chr 229, # å
    aelig  => chr 230, # æ
    ccedil => chr 231, # ç
    egrave => chr 232, # è
    eacute => chr 233, # é
    ecirc  => chr 234, # ê
    euml   => chr 235, # ë
    igrave => chr 236, # ì
    iacute => chr 237, # í
    icirc  => chr 238, # î
    iuml   => chr 239, # ï
    eth    => chr 240, # ð  (small eth, Icelandic)
    ntilde => chr 241, # ñ
    ograve => chr 242, # ò
    oacute => chr 243, # ó
    ocirc  => chr 244, # ô
    otilde => chr 245, # õ
    ouml   => chr 246, # ö
    divide => chr 247, # ÷
    oslash => chr 248, # ø
    ugrave => chr 249, # ù
    uacute => chr 250, # ú
    ucirc  => chr 251, # û
    uuml   => chr 252, # ü
    yacute => chr 253, # ý  (small y, acute)
    thorn  => chr 254, # þ  (small thorn, Icelandic)
    yuml   => chr 255, # ÿ
);


# now fill in all the numbers to match
# themselves

    foreach $chr ( 0 .. 255 ) {
        $entity{ '#' . $chr } = chr $chr;
    }
}
