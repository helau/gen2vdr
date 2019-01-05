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
    iexcl  => chr 161, # �
    cent   => chr 162, # �
    pound  => chr 163, # �
    curren => chr 164, # �
    yen    => chr 165, # �
    brvbar => chr 166, # �  (broken vertical bar)
    sect   => chr 167, # �
    uml    => chr 168, # �  (umlaut, or dieresis)
    copy   => chr 169, # �
    ordf   => chr 170, # �  (feminine ordinal)
    laquo  => chr 171, # �
    not    => chr 172, # �
    shy    => chr 173, # �  (soft hyphen)
    reg    => chr 174, # �
    macr   => chr 175, # �
    deg    => chr 176, # �
    plusmn => chr 177, # �
    sup2   => chr 178, # �  (superscript two)
    sup3   => chr 179, # �  (superscript three)
    acute  => chr 180, # �  (acute accent)
    micro  => chr 181, # �  (micro sign)
    para   => chr 182, # �  (pilcrow)
    middot => chr 183, # �
    cedil  => chr 184, # �  (cedilla)
    sup1   => chr 185, # �  (superscript one)
    ordm   => chr 186, # �  (masculine ordinal)
    raquo  => chr 187, # �
    frac14 => chr 188, # �  (one-quarter)
    frac12 => chr 189, # �  (one-half)
    frac34 => chr 190, # �  (three-quarters)
    iquest => chr 191, # �
    Agrave => chr 192, # �
    Aacute => chr 193, # �
    Acirc  => chr 194, # �
    Atilde => chr 195, # �
    Auml   => chr 196, # �
    Aring  => chr 197, # �
    AElig  => chr 198, # �
    Ccedil => chr 199, # �
    Egrave => chr 200, # �
    Eacute => chr 201, # �
    Ecirc  => chr 202, # �
    Euml   => chr 203, # �
    Igrave => chr 204, # �
    Iacute => chr 205, # �
    Icirc  => chr 206, # �
    Iuml   => chr 207, # �
    ETH    => chr 208, # �  (capital Eth, Icelandic)
    Ntilde => chr 209, # �
    Ograve => chr 210, # �
    Oacute => chr 211, # �
    Ocirc  => chr 212, # �
    Otilde => chr 213, # �
    Ouml   => chr 214, # �
    times  => chr 215, # �
    Oslash => chr 216, # �
    Ugrave => chr 217, # �
    Uacute => chr 218, # �
    Ucirc  => chr 219, # �
    Uuml   => chr 220, # �
    Yacute => chr 221, # �  (capital Y, acute accent)
    THORN  => chr 222, #�   (capital THORN, Icelandic)
    szlig  => chr 223, # �
    agrave => chr 224, # �
    aacute => chr 225, # �
    acirc  => chr 226, # �
    atilde => chr 227, # �
    auml   => chr 228, # �
    aring  => chr 229, # �
    aelig  => chr 230, # �
    ccedil => chr 231, # �
    egrave => chr 232, # �
    eacute => chr 233, # �
    ecirc  => chr 234, # �
    euml   => chr 235, # �
    igrave => chr 236, # �
    iacute => chr 237, # �
    icirc  => chr 238, # �
    iuml   => chr 239, # �
    eth    => chr 240, # �  (small eth, Icelandic)
    ntilde => chr 241, # �
    ograve => chr 242, # �
    oacute => chr 243, # �
    ocirc  => chr 244, # �
    otilde => chr 245, # �
    ouml   => chr 246, # �
    divide => chr 247, # �
    oslash => chr 248, # �
    ugrave => chr 249, # �
    uacute => chr 250, # �
    ucirc  => chr 251, # �
    uuml   => chr 252, # �
    yacute => chr 253, # �  (small y, acute)
    thorn  => chr 254, # �  (small thorn, Icelandic)
    yuml   => chr 255, # �
);


# now fill in all the numbers to match
# themselves

    foreach $chr ( 0 .. 255 ) {
        $entity{ '#' . $chr } = chr $chr;
    }
}
