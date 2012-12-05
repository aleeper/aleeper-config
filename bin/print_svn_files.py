import os
import sys
import pysvn

def get_svn_ignores( svn_client, path ):
    prop_list = svn_client.propget( "svn:ignore", path )
    if len(prop_list) == 1:
        return prop_list.values()[0].split("\n")
    elif len(prop_list) > 1:
        raise Exception("more than one svn:ignore list for path " + path)
    else:
        return []

def print_svn_files( roots ):
    svn_client = pysvn.Client()

    for root in roots:
        for path, dirs, files in os.walk( root ):
            if ".svn" in dirs:
                dirs.remove( ".svn" )
                ignores = get_svn_ignores( svn_client, path )
                for ignore in ignores:
                    try:
                        dirs.remove( ignore )
                        files.remove( ignore )
                    except:
                        pass
            if ".hg" in dirs:
                dirs.remove( ".hg" )
            if ".hgtags" in files:
                files.remove( ".hgtags" )
            if ".git" in dirs:
                dirs.remove( ".git" )
            for file in files:
                print os.path.join( path, file )

if __name__ == '__main__':
    if len( sys.argv ) > 1:
        print_svn_files( sys.argv[1:] )
    else:
        print_svn_files( ["."] )
