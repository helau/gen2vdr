# Usage: strstr s1 s2
# 
# Strstr returns 1 if s1 contains s2, 0 otherwise
#
function strstr ()
{
    # strstr echoes nothing if s2 does not occur in s1
    case "$1" in
       *$2*) return 0;;
    esac
    return 1
}
